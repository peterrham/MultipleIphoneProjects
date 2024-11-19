//
//  ContentViewV3.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/19/24.
//


import SwiftUI
import AVFoundation
import Vision

struct ContentViewV3: View {
    @StateObject private var barcodeScannerV3 = BarcodeScannerV3()
    @State private var isScanningV3 = true // Tracks scanning state

    var body: some View {
        ZStack {
            CameraViewV3(scanner: barcodeScannerV3, isScanning: $isScanningV3)
                .onAppear {
                    print("ContentViewV3: onAppear called")
                    barcodeScannerV3.startSessionV3()
                    print("ContentViewV3: onAppear completed")
                }
                .onDisappear {
                    print("ContentViewV3: onDisappear called")
                    barcodeScannerV3.stopSessionV3()
                    print("ContentViewV3: onDisappear completed")
                }

            VStack {
                Spacer()
                if let scannedCode = barcodeScannerV3.detectedCodeV3 {
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
                    isScanningV3.toggle()
                    if isScanningV3 {
                        print("ContentViewV3: Scanning resumed")
                    } else {
                        print("ContentViewV3: Scanning paused")
                    }
                }) {
                    Text(isScanningV3 ? "Stop Scanning" : "Start Scanning")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isScanningV3 ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
}

class BarcodeScannerV3: NSObject, ObservableObject {
    @Published var detectedCodeV3: String? = nil

    public var overlayLayerV3: CALayer? // Made public for external access
    let captureSessionV3 = AVCaptureSession()
    private let videoOutputV3 = AVCaptureVideoDataOutput()
    private let queueV3 = DispatchQueue(label: "BarcodeScannerQueueV3")

    override init() {
        print("BarcodeScannerV3: init called")
        super.init()
        checkCameraAuthorizationV3()
        print("BarcodeScannerV3: init completed")
    }

    deinit {
        print("BarcodeScannerV3: deinit called")
        stopSessionV3()
        print("BarcodeScannerV3: deinit completed")
    }

    public func checkCameraAuthorizationV3() {
        print("BarcodeScannerV3: checkCameraAuthorizationV3 called")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("BarcodeScannerV3: Camera already authorized")
            setupCameraV3()
        case .notDetermined:
            print("BarcodeScannerV3: Requesting camera authorization")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        print("BarcodeScannerV3: Camera authorization granted")
                        self.setupCameraV3()
                    }
                } else {
                    print("BarcodeScannerV3: Camera authorization denied")
                }
            }
        default:
            print("BarcodeScannerV3: Camera access denied or restricted")
        }
        print("BarcodeScannerV3: checkCameraAuthorizationV3 completed")
    }

    public func setupCameraV3() {
        print("BarcodeScannerV3: setupCameraV3 called")
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("BarcodeScannerV3: No video device available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSessionV3.canAddInput(videoInput) {
                captureSessionV3.addInput(videoInput)
                print("BarcodeScannerV3: Video input added to session")
            } else {
                print("BarcodeScannerV3: Could not add video input")
            }
        } catch {
            print("BarcodeScannerV3: Error creating video input - \(error)")
            return
        }

        videoOutputV3.setSampleBufferDelegate(self, queue: queueV3)
        if captureSessionV3.canAddOutput(videoOutputV3) {
            captureSessionV3.addOutput(videoOutputV3)
            print("BarcodeScannerV3: Video output added to session")
        } else {
            print("BarcodeScannerV3: Could not add video output")
        }
        print("BarcodeScannerV3: setupCameraV3 completed")
    }

    public func startSessionV3() {
        print("BarcodeScannerV3: startSessionV3 called")
        if !captureSessionV3.isRunning {
            captureSessionV3.startRunning()
            print("BarcodeScannerV3: Capture session started")
        } else {
            print("BarcodeScannerV3: Capture session already running")
        }
        print("BarcodeScannerV3: startSessionV3 completed")
    }

    public func stopSessionV3() {
        print("BarcodeScannerV3: stopSessionV3 called")
        if captureSessionV3.isRunning {
            captureSessionV3.stopRunning()
            print("BarcodeScannerV3: Capture session stopped")
        } else {
            print("BarcodeScannerV3: Capture session already stopped")
        }
        print("BarcodeScannerV3: stopSessionV3 completed")
    }

    public func addOverlayV3(for barcodes: [VNBarcodeObservation]) {
        guard let overlayLayer = overlayLayerV3 else { return }
        DispatchQueue.main.async {
            print("Adding overlay for \(barcodes.count) barcodes")
            overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            for barcode in barcodes {
                let box = CALayer()
                box.borderColor = UIColor.red.cgColor
                box.borderWidth = 2.0
                
                // Transform boundingBox to screen coordinates
                let boundingBox = barcode.boundingBox
                let x = boundingBox.origin.x * overlayLayer.bounds.width
                let y = (1 - boundingBox.origin.y - boundingBox.height) * overlayLayer.bounds.height
                let width = boundingBox.width * overlayLayer.bounds.width
                let height = boundingBox.height * overlayLayer.bounds.height
                box.frame = CGRect(x: x, y: y, width: width, height: height)
                
                overlayLayer.addSublayer(box)
                print("Overlay box frame: \(box.frame)")
            }
        }
    }
}

extension BarcodeScannerV3: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("BarcodeScannerV3: captureOutput called")
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("BarcodeScannerV3: No pixel buffer in sample buffer")
            return
        }

        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation] {
                print("Barcodes detected: \(results.count)")
                self.addOverlayV3(for: results)
                if let firstResult = results.first {
                    DispatchQueue.main.async {
                        self.detectedCodeV3 = firstResult.payloadStringValue
                        print("Barcode detected: \(self.detectedCodeV3 ?? "Unknown")")
                    }
                }
            } else if let error = error {
                print("Error detecting barcodes: \(error)")
            } else {
                print("No barcodes detected")
            }
        }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([request])
            print("BarcodeScannerV3: Vision request performed")
        } catch {
            print("BarcodeScannerV3: Error performing Vision request - \(error)")
        }
        print("BarcodeScannerV3: captureOutput completed")
    }
}

struct CameraViewV3: UIViewRepresentable {
    let scanner: BarcodeScannerV3
    @Binding var isScanningV3: Bool

    func makeUIView(context: Context) -> UIView {
        print("CameraViewV3: makeUIView called")
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSessionV3)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Add overlay layer for barcode visualization
        let overlayLayer = CALayer()
        overlayLayer.frame = view.bounds
        view.layer.addSublayer(overlayLayer)
        scanner.overlayLayerV3 = overlayLayer

        DispatchQueue.global(qos: .userInitiated).async {
            print("CameraViewV3: Starting capture session from makeUIView")
            scanner.startSessionV3()
        }
        print("CameraViewV3: makeUIView completed")
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("CameraViewV3: updateUIView called")
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
                scanner.overlayLayerV3?.frame = uiView.bounds
                print("CameraViewV3: Updated preview and overlay layer frames")
            }
        }
        print("CameraViewV3: updateUIView completed")
    }

    func makeCoordinator() -> CoordinatorV3 {
        print("CameraViewV3: makeCoordinator called")
        return CoordinatorV3(scanner: scanner, isScanningV3: $isScanningV3)
    }

    class CoordinatorV3: NSObject {
        var previewLayerV3: AVCaptureVideoPreviewLayer?
        let scanner: BarcodeScannerV3
        @Binding var isScanningV3: Bool

        init(scanner: BarcodeScannerV3, isScanningV3: Binding<Bool>) {
            self.scanner = scanner
            _isScanningV3 = isScanningV3
            super.init()
            print("CoordinatorV3: init completed")
        }
    }
}

@main
struct RecognizeBarCodeAppV3: App {
    var body: some Scene {
        WindowGroup {
            ContentViewV3()
        }
    }
}
