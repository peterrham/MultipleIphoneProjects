//
//  ContentView.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/18/24.
//


import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @StateObject private var barcodeScanner = BarcodeScanner()

    var body: some View {
        ZStack {
            CameraView(scanner: barcodeScanner)
                .onAppear {
                    print("ContentView: onAppear called")
                    barcodeScanner.startSession()
                }
                .onDisappear {
                    print("ContentView: onDisappear called")
                    barcodeScanner.stopSession()
                }

            if let scannedCode = barcodeScanner.detectedCode {
                Text("Scanned Code: \(scannedCode)")
                    .padding()
                    .background(Color.black.opacity(0.7)) // Semi-transparent black background
                    .foregroundColor(.white) // White text for contrast
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
            }
        }
    }
}

class BarcodeScanner: NSObject, ObservableObject {
    @Published var detectedCode: String? = nil

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "BarcodeScannerQueue")

    override init() {
        print("BarcodeScanner: init called")
        super.init()
        checkCameraAuthorization()
    }

    deinit {
        print("BarcodeScanner: deinit called")
        stopSession()
    }

    private func checkCameraAuthorization() {
        print("BarcodeScanner: checkCameraAuthorization called")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("BarcodeScanner: Camera already authorized")
            setupCamera()
        case .notDetermined:
            print("BarcodeScanner: Requesting camera authorization")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        print("BarcodeScanner: Camera authorization granted")
                        self.setupCamera()
                    }
                } else {
                    print("BarcodeScanner: Camera authorization denied")
                }
            }
        default:
            print("BarcodeScanner: Camera access denied or restricted")
        }
    }

    private func setupCamera() {
        print("BarcodeScanner: setupCamera called")
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("BarcodeScanner: No video device available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                print("BarcodeScanner: Video input added to session")
            } else {
                print("BarcodeScanner: Could not add video input")
            }
        } catch {
            print("BarcodeScanner: Error creating video input - \(error)")
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("BarcodeScanner: Video output added to session")
        } else {
            print("BarcodeScanner: Could not add video output")
        }
    }

    func startSession() {
        print("BarcodeScanner: startSession called")
        if !captureSession.isRunning {
            captureSession.startRunning()
            print("BarcodeScanner: Capture session started")
        } else {
            print("BarcodeScanner: Capture session already running")
        }
    }

    func stopSession() {
        print("BarcodeScanner: stopSession called")
        if captureSession.isRunning {
            captureSession.stopRunning()
            print("BarcodeScanner: Capture session stopped")
        } else {
            print("BarcodeScanner: Capture session already stopped")
        }
    }
}

extension BarcodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("BarcodeScanner: captureOutput called")
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("BarcodeScanner: No pixel buffer in sample buffer")
            return
        }

        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation], let firstResult = results.first {
                DispatchQueue.main.async {
                    print("BarcodeScanner: Barcode detected - \(String(describing: firstResult.payloadStringValue))")
                    self.detectedCode = firstResult.payloadStringValue
                }
            }
        }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([request])
            print("BarcodeScanner: Vision request performed")
        } catch {
            print("BarcodeScanner: Error performing Vision request - \(error)")
        }
    }
}

struct CameraView: UIViewRepresentable {
    let scanner: BarcodeScanner

    func makeUIView(context: Context) -> UIView {
        print("CameraView: makeUIView called")
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        // Start the capture session after the preview layer is added
        DispatchQueue.global(qos: .userInitiated).async {
            print("CameraView: Starting capture session from makeUIView")
            scanner.startSession()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("CameraView: updateUIView called")
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
                print("CameraView: Updated preview layer frame")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        print("CameraView: makeCoordinator called")
        return Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

@main
struct RecognizeBarCodeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
