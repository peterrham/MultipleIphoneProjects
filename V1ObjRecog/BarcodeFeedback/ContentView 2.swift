//
//  ContentView 2.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/22/24.
//


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

                // Adding fixed rectangles for debugging
                Path { path in
                    // Top left rectangle
                    path.addRect(CGRect(x: 10, y: 10, width: 50, height: 50))
                    // Center rectangle
                    path.addRect(CGRect(x: screenWidth / 2 - 25, y: screenHeight / 2 - 25, width: 50, height: 50))
                    // Bottom right rectangle
                    path.addRect(CGRect(x: screenWidth - 60, y: screenHeight - 60, width: 50, height: 50))
                }
                .stroke(Color.red, lineWidth: 2)

                // Drawing a crosshair in the center
                Path { path in
                    path.move(to: CGPoint(x: screenWidth / 2, y: screenHeight / 2 - 20))
                    path.addLine(to: CGPoint(x: screenWidth / 2, y: screenHeight / 2 + 20))
                    path.move(to: CGPoint(x: screenWidth / 2 - 20, y: screenHeight / 2))
                    path.addLine(to: CGPoint(x: screenWidth / 2 + 20, y: screenHeight / 2))
                }
                .stroke(Color.blue, lineWidth: 2)
            }
        }
    }
}

class BarcodeScanner: ObservableObject {
    @Published var detectedCode: String?
    private var session: AVCaptureSession?

    func startSession() {
        print("BarcodeScanner: startSession called")
        // Setup AVCaptureSession here
        session = AVCaptureSession()
        // Additional configuration...
        print("BarcodeScanner: Session started")
    }

    func stopSession() {
        print("BarcodeScanner: stopSession called")
        session?.stopRunning()
        session = nil
        print("BarcodeScanner: Session stopped")
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
            // Setting up camera preview here
            let cameraLayer = AVCaptureVideoPreviewLayer(session: scanner.session ?? AVCaptureSession())
            cameraLayer.videoGravity = .resizeAspectFill
            cameraLayer.frame = view.bounds
            view.layer.addSublayer(cameraLayer)
            print("Coordinator: Camera preview set up")
        }
    }
}
