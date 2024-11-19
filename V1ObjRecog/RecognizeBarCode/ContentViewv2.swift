//
//  ContentViewv2.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/18/24.
//


import SwiftUI
import AVFoundation
import Vision

struct ContentViewv2: View {
    @StateObject private var barcodeScannerv2 = BarcodeScannerv2()
    @State private var isScanningv2 = true // Tracks scanning state

    var body: some View {
        ZStack {
            CameraViewv2(scanner: barcodeScannerv2, isScanningv2: $isScanningv2)
                .onAppear {
                    print("ContentViewv2: onAppear called")
                    barcodeScannerv2.startSessionv2()
                    print("ContentViewv2: onAppear completed")
                }
                .onDisappear {
                    print("ContentViewv2: onDisappear called")
                    barcodeScannerv2.stopSessionv2()
                    print("ContentViewv2: onDisappear completed")
                }

            VStack {
                Spacer()
                if let scannedCode = barcodeScannerv2.detectedCodev2 {
                    Text("Scanned Code: \(scannedCode)")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding()
                }

                Button(action: {
                    isScanningv2.toggle()
                    if isScanningv2 {
                        print("ContentViewv2: Scanning resumed")
                    } else {
                        print("ContentViewv2: Scanning paused")
                    }
                }) {
                    Text(isScanningv2 ? "Stop Scanning" : "Start Scanning")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isScanningv2 ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
}

class BarcodeScannerv2: NSObject, ObservableObject {
    @Published var detectedCodev2: String? = nil

    let captureSessionv2 = AVCaptureSession()
    private let videoOutputv2 = AVCaptureVideoDataOutput()
    private let queuev2 = DispatchQueue(label: "BarcodeScannerQueuev2")

    override init() {
        print("BarcodeScannerv2: init called")
        super.init()
        checkCameraAuthorizationv2()
        print("BarcodeScannerv2: init completed")
    }

    deinit {
        print("BarcodeScannerv2: deinit called")
        stopSessionv2()
        print("BarcodeScannerv2: deinit completed")
    }

    private func checkCameraAuthorizationv2() {
        print("BarcodeScannerv2: checkCameraAuthorizationv2 called")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("BarcodeScannerv2: Camera already authorized")
            setupCamerav2()
        case .notDetermined:
            print("BarcodeScannerv2: Requesting camera authorization")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        print("BarcodeScannerv2: Camera authorization granted")
                        self.setupCamerav2()
                    }
                } else {
                    print("BarcodeScannerv2: Camera authorization denied")
                }
            }
        default:
            print("BarcodeScannerv2: Camera access denied or restricted")
        }
        print("BarcodeScannerv2: checkCameraAuthorizationv2 completed")
    }

    private func setupCamerav2() {
        print("BarcodeScannerv2: setupCamerav2 called")
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("BarcodeScannerv2: No video device available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSessionv2.canAddInput(videoInput) {
                captureSessionv2.addInput(videoInput)
                print("BarcodeScannerv2: Video input added to session")
            } else {
                print("BarcodeScannerv2: Could not add video input")
            }
        } catch {
            print("BarcodeScannerv2: Error creating video input - \(error)")
            return
        }

        videoOutputv2.setSampleBufferDelegate(self, queue: queuev2)
        if captureSessionv2.canAddOutput(videoOutputv2) {
            captureSessionv2.addOutput(videoOutputv2)
            print("BarcodeScannerv2: Video output added to session")
        } else {
            print("BarcodeScannerv2: Could not add video output")
        }
        print("BarcodeScannerv2: setupCamerav2 completed")
    }

    func startSessionv2() {
        print("BarcodeScannerv2: startSessionv2 called")
        if !captureSessionv2.isRunning {
            captureSessionv2.startRunning()
            print("BarcodeScannerv2: Capture session started")
        } else {
            print("BarcodeScannerv2: Capture session already running")
        }
        print("BarcodeScannerv2: startSessionv2 completed")
    }

    func stopSessionv2() {
        print("BarcodeScannerv2: stopSessionv2 called")
        if captureSessionv2.isRunning {
            captureSessionv2.stopRunning()
            print("BarcodeScannerv2: Capture session stopped")
        } else {
            print("BarcodeScannerv2: Capture session already stopped")
        }
        print("BarcodeScannerv2: stopSessionv2 completed")
    }
}

extension BarcodeScannerv2: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("BarcodeScannerv2: captureOutput called")
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("BarcodeScannerv2: No pixel buffer in sample buffer")
            return
        }

        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation], let firstResult = results.first {
                DispatchQueue.main.async {
                    print("BarcodeScannerv2: Barcode detected - \(String(describing: firstResult.payloadStringValue))")
                    self.detectedCodev2 = firstResult.payloadStringValue
                }
            }
        }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([request])
            print("BarcodeScannerv2: Vision request performed")
        } catch {
            print("BarcodeScannerv2: Error performing Vision request - \(error)")
        }
        print("BarcodeScannerv2: captureOutput completed")
    }
}

struct CameraViewv2: UIViewRepresentable {
    let scanner: BarcodeScannerv2
    @Binding var isScanningv2: Bool

    func makeUIView(context: Context) -> UIView {
        print("CameraViewv2: makeUIView called")
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSessionv2)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayerv2 = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            print("CameraViewv2: Starting capture session from makeUIView")
            scanner.startSessionv2()
        }
        print("CameraViewv2: makeUIView completed")
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("CameraViewv2: updateUIView called")
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
                print("CameraViewv2: Updated preview layer frame")
            }
        }
        print("CameraViewv2: updateUIView completed")
    }

    func makeCoordinator() -> Coordinatorv2 {
        print("CameraViewv2: makeCoordinator called")
        return Coordinatorv2(scanner: scanner, isScanningv2: $isScanningv2)
    }

    class Coordinatorv2: NSObject {
        var previewLayerv2: AVCaptureVideoPreviewLayer?
        let scanner: BarcodeScannerv2
        @Binding var isScanningv2: Bool

        init(scanner: BarcodeScannerv2, isScanningv2: Binding<Bool>) {
            self.scanner = scanner
            _isScanningv2 = isScanningv2
            super.init()
            print("Coordinatorv2: init completed")
        }
    }
}

@main
struct RecognizeBarCodeAppv2: App {
    var body: some Scene {
        WindowGroup {
            ContentViewv2()
        }
    }
}
