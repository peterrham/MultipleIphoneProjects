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

                // Scanned Barcodes
                ScrollView {
                    ForEach(barcodeCollector.detectedBarcodes, id: \.self) { barcode in
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

            // Play a louder beep for new barcode
            AudioServicesPlaySystemSound(SystemSoundID(1104)) // Loud "Sent Message" sound
        }
    }

    func exportBarcodes() {
        let csvContent = detectedBarcodes.joined(separator: "\n")
        let fileName = "Barcodes.csv"

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
