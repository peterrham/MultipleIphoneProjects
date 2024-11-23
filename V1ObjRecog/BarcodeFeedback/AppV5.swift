import SwiftUI
import AVFoundation

@main
struct BarcodeScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var barcodeScanner = BarcodeScanner()
    @State private var isScanning = true

    var body: some View {
        ZStack {
            CameraView(scanner: barcodeScanner, isScanning: $isScanning)
                .onAppear {
                    print("ContentView: onAppear called")
                    barcodeScanner.startSession()
                }
                .onDisappear {
                    print("ContentView: onDisappear called")
                    barcodeScanner.stopSession()
                }

            // Debugging Overlay
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height

                ZStack {
                    // Top left rectangle with coordinates
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .position(x: 35, y: 35)
                    Text("(10, 10)")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .position(x: 70, y: 20)

                    // Center rectangle with coordinates
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .position(x: screenWidth / 2, y: screenHeight / 2)
                    Text("(\(Int(screenWidth / 2)), \(Int(screenHeight / 2)))")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .position(x: screenWidth / 2 + 50, y: screenHeight / 2 - 25)

                    // Bottom right rectangle with coordinates
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .position(x: screenWidth - 35, y: screenHeight - 35)
                    Text("(\(Int(screenWidth - 60)), \(Int(screenHeight - 60)))")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .position(x: screenWidth - 50, y: screenHeight - 50)

                    // Dynamic Debug Lines
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: screenWidth, y: screenHeight))
                        path.move(to: CGPoint(x: 0, y: screenHeight))
                        path.addLine(to: CGPoint(x: screenWidth, y: 0))
                    }
                    .stroke(Color.green, lineWidth: 1)
                }
            }

            // Start/Stop Scanning Buttons
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        isScanning = true
                        barcodeScanner.startSession()
                        print("Scanning started")
                    }) {
                        Text("Start Scanning")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .overlay(
                        Text("(10, \(UIScreen.main.bounds.height - 50))")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .offset(y: -20)
                    )

                    Button(action: {
                        isScanning = false
                        barcodeScanner.stopSession()
                        print("Scanning stopped")
                    }) {
                        Text("Stop Scanning")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .overlay(
                        Text("(\(UIScreen.main.bounds.width - 150), \(UIScreen.main.bounds.height - 50))")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .offset(y: -20)
                    )
                }
                .padding()
            }
        }
    }
}

class BarcodeScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var detectedCode: String?
    public var session: AVCaptureSession?

    override init() {
        super.init()
        print("BarcodeScanner: init called")
        session = AVCaptureSession()
        configureSession()
        print("BarcodeScanner: AVCaptureSession initialized")
    }

    func configureSession() {
        guard let session = session else { return }

        print("BarcodeScanner: Configuring session")
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("BarcodeScanner: No video capture device found")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                print("BarcodeScanner: Video input added")
            } else {
                print("BarcodeScanner: Unable to add input to session")
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
                print("BarcodeScanner: Metadata output added")
            } else {
                print("BarcodeScanner: Unable to add metadata output")
                return
            }
        } catch {
            print("BarcodeScanner: Error setting up video input: \(error)")
            return
        }

        print("BarcodeScanner: Session configured successfully")
    }

    func startSession() {
        guard let session = session else {
            print("BarcodeScanner: No session available to start")
            return
        }
        print("BarcodeScanner: startSession called")
        if !session.isRunning {
            session.startRunning()
            print("BarcodeScanner: Session started")
        } else {
            print("BarcodeScanner: Session was already running")
        }
    }

    func stopSession() {
        guard let session = session else {
            print("BarcodeScanner: No session available to stop")
            return
        }
        print("BarcodeScanner: stopSession called")
        if session.isRunning {
            session.stopRunning()
            print("BarcodeScanner: Session stopped")
        } else {
            print("BarcodeScanner: Session was already stopped")
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        print("BarcodeScanner: metadataOutput called with \(metadataObjects.count) objects")
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            print("BarcodeScanner: No valid barcode found")
            return
        }
        handleDetectedBarcode(stringValue)
    }

    func handleDetectedBarcode(_ code: String) {
        print("BarcodeScanner: handleDetectedBarcode called with code: \(code)")
        DispatchQueue.main.async {
            self.detectedCode = code
        }
        print("BarcodeScanner: Barcode detection updated in UI")
    }
}

struct CameraView: UIViewRepresentable {
    var scanner: BarcodeScanner
    @Binding var isScanning: Bool

    func makeUIView(context: Context) -> UIView {
        print("CameraView: makeUIView called")
        let view = UIView(frame: .zero)
        context.coordinator.setupCameraPreview(on: view)
        print("CameraView: makeUIView returning")
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        print("CameraView: updateUIView called")
        if isScanning {
            scanner.startSession()
        } else {
            scanner.stopSession()
        }
        print("CameraView: updateUIView completed")
    }

    func makeCoordinator() -> Coordinator {
        print("CameraView: makeCoordinator called")
        return Coordinator(scanner: scanner)
    }

    class Coordinator: NSObject {
        private var scanner: BarcodeScanner

        init(scanner: BarcodeScanner) {
            print("Coordinator: init called")
            self.scanner = scanner
            super.init()
            print("Coordinator: init completed")
        }

        func setupCameraPreview(on view: UIView) {
            print("Coordinator: setupCameraPreview called")
            guard let session = scanner.session else {
                print("Coordinator: session is nil")
                return
            }
            let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
            cameraLayer.videoGravity = .resizeAspectFill
            cameraLayer.frame = view.bounds
            view.layer.addSublayer(cameraLayer)
            print("Coordinator: Camera preview set up")
        }
    }
}
