import SwiftUI
import AVFoundation

@main
struct CameraPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            CameraView()
        }
    }
}

struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        print("Creating UIView...")
        let view = UIView(frame: .zero)
        view.backgroundColor = .black // Debug background

        let session = AVCaptureSession()
        print("AVCaptureSession created.")

        // Check camera permissions
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard cameraAuthorizationStatus == .authorized else {
            print("Camera access not authorized.")
            return view
        }

        // List available devices
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
        print("Available cameras: \(devices.map { $0.localizedName })")

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
        print("Updating UIView...")
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                print("Preview layer frame updated.")
            }
        } else {
            print("Preview layer not found.")
        }
    }
}
