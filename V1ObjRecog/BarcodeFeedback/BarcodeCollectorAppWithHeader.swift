//
//  BarcodeCollectorApp 2.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/24/24.
//


//
//  BarcodeCollectorApp.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/23/24.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

@main
struct BarcodeCollectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var barcodeCollector = BarcodeCollector()
    @State private var isScanning = true

    var body: some View {
        ZStack {
            // Camera View (Background)
            CameraView(scanner: barcodeCollector, isScanning: $isScanning)
                .onAppear {
                    barcodeCollector.startSession()
                }
                .onDisappear {
                    barcodeCollector.stopSession()
                }
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                Spacer()

                // Scanned Barcodes (Reverse Chronological Order)
                ScrollView {
                    ForEach(barcodeCollector.detectedBarcodes.reversed(), id: \.self) { barcode in
                        Text(barcode)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                }
                .frame(maxHeight: 200) // Limit height for the list

                // Export Button
                Button(action: {
                    barcodeCollector.exportBarcodes()
                }) {
                    Text("Export as CSV")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
}

class BarcodeCollector: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var detectedBarcodes: [String] = []
    private var session: AVCaptureSession?
    private var lastDetectedBarcode: String?
    private var audioEngine: AVAudioEngine?

    var captureSession: AVCaptureSession? {
        return session
    }

    override init() {
        super.init()
        session = AVCaptureSession()
        configureSession()
    }

    func configureSession() {
        guard let session = session else { return }

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capture device found.")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417, .code128]
            }
        } catch {
            print("Error setting up video input: \(error)")
        }
    }

    func startSession() {
        guard let session = session else { return }
        if !session.isRunning {
            session.startRunning()
        }
    }

    func stopSession() {
        guard let session = session else { return }
        if session.isRunning {
            session.stopRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcodeValue = metadataObject.stringValue else {
            return
        }

        if barcodeValue != lastDetectedBarcode {
            lastDetectedBarcode = barcodeValue
            DispatchQueue.main.async {
                self.detectedBarcodes.append(barcodeValue)
            }
            print("New barcode detected: \(barcodeValue)")

            // Play high-pitched bell sound
            playHighPitchedBell()
        }
    }

    func exportBarcodes() {
        // Add header and barcodes to the CSV content
        let header = "Barcode\n"
        let csvContent = header + detectedBarcodes.map { "\"\($0)\"" }.joined(separator: "\n")

        // Format the file name with a date and time stamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateTimeString = dateFormatter.string(from: Date())
        let fileName = "\(dateTimeString)_Barcodes.csv"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

            // Present share sheet
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        } catch {
            print("Error exporting barcodes: \(error)")
        }
    }

    func playHighPitchedBell() {
        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        let output = engine.outputNode
        let sampleRate = Float(engine.outputNode.outputFormat(forBus: 0).sampleRate)

        let sineFrequency: Float = 880.0 // Frequency in Hz (A5)
        var phase: Float = 0.0
        let phaseIncrement = (2.0 * Float.pi * sineFrequency) / sampleRate

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = sin(phase) // Generate sine wave
                phase += phaseIncrement
                if phase > 2.0 * Float.pi {
                    phase -= 2.0 * Float.pi
                }

                for buffer in bufferPointer {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = value * 0.2 // Amplitude
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: nil)
        engine.connect(mainMixer, to: output, format: nil)

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }

        // Play for 0.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            engine.stop()
            self.audioEngine = nil
        }

        self.audioEngine = engine
    }
}

struct CameraView: UIViewRepresentable {
    var scanner: BarcodeCollector
    @Binding var isScanning: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        if let session = scanner.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            // Update frame dynamically
            DispatchQueue.main.async {
                previewLayer.frame = view.bounds
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            scanner.startSession()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isScanning {
            scanner.startSession()
        } else {
            scanner.stopSession()
        }

        // Ensure preview layer stays updated
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}