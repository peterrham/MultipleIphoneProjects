import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @StateObject private var barcodeScanner = BarcodeScanner()
    @State private var isScanning = true

    var body: some View {
        ZStack {
            CameraView(scanner: barcodeScanner, isScanning: $isScanning)
                .onAppear {
                    barcodeScanner.startSession()
                }
                .onDisappear {
                    barcodeScanner.stopSession()
                }

            VStack {
                Spacer()
                if let scannedCode = barcodeScanner.detectedCode {
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
                    isScanning.toggle()
                    if isScanning {
                        barcodeScanner.startSession()
                    } else {
                        barcodeScanner.stopSession()
                    }
                }) {
                    Text(isScanning ? "Stop Scanning" : "Start Scanning")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isScanning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
}

class BarcodeScanner: NSObject, ObservableObject {
    @Published var detectedCode: String? = nil

    var overlayLayer: CALayer?
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "BarcodeScannerQueue")

    override init() {
        super.init()
        checkCameraAuthorization()
    }

    deinit {
        stopSession()
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }

    func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func addOverlay(for barcodes: [VNBarcodeObservation]) {
        guard let overlayLayer = overlayLayer else { return }
        DispatchQueue.main.async {
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
            }
        }
    }
}

extension BarcodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation] {
                self.addOverlay(for: results)
                if let firstResult = results.first {
                    DispatchQueue.main.async {
                        self.detectedCode = firstResult.payloadStringValue
                    }
                }
            }
        }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            // Handle error
        }
    }
}

struct CameraView: UIViewRepresentable {
    let scanner: BarcodeScanner
    @Binding var isScanning: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Add overlay layer for barcode visualization
        let overlayLayer = CALayer()
        overlayLayer.frame = view.bounds
        view.layer.addSublayer(overlayLayer)
        scanner.overlayLayer = overlayLayer

        DispatchQueue.global(qos: .userInitiated).async {
            scanner.startSession()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
                scanner.overlayLayer?.frame = uiView.bounds
            }
        }
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
