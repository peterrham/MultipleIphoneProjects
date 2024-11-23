//
//  BarcodePreviewApp.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/23/24.
//

import SwiftUI
import AVFoundation

@main
struct BarcodePreviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var detectedBarcode: String = "No barcode detected yet."

    var body: some View {
        VStack {
            Text("Detected Barcode:")
                .font(.headline)
                .padding()
            Text(detectedBarcode)
                .font(.largeTitle)
                .padding()
            BarcodeCameraView(detectedBarcode: $detectedBarcode)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct BarcodeCameraView: UIViewRepresentable {
    @Binding var detectedBarcode: String

    func makeUIView(context: Context) -> UIView {
        print("Creating UIView...")
        let view = UIView(frame: .zero)
        view.backgroundColor = .black // Debug background color for visibility

        let session = AVCaptureSession()
        print("AVCaptureSession created.")

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Error: No back camera found.")
            return view
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                print("Video input added.")
            } else {
                print("Cannot add video input.")
            }
        } catch {
            print("Error creating video input: \(error.localizedDescription)")
            return view
        }

        // Add a Metadata Output for Barcode Detection
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            print("Metadata output added.")

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code128] // Add desired barcode types
        } else {
            print("Cannot add metadata output.")
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        print("Preview layer added.")

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            print("Capture session started.")
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(detectedBarcode: $detectedBarcode)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var detectedBarcode: String
        private var lastDetectedBarcode: String = ""

        init(detectedBarcode: Binding<String>) {
            _detectedBarcode = detectedBarcode
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let barcodeValue = metadataObject.stringValue else {
                print("No barcode detected.")
                return
            }

            // Check if the barcode is new
            if barcodeValue != lastDetectedBarcode {
                print("New barcode detected: \(barcodeValue)")
                detectedBarcode = barcodeValue
                lastDetectedBarcode = barcodeValue

                // Play a beep sound for new barcode
                AudioServicesPlaySystemSound(SystemSoundID(1057)) // System sound for a short beep
            } else {
                print("Duplicate barcode detected: \(barcodeValue)")
            }
        }
    }
}
