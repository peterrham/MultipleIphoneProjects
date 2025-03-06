import SwiftUI
import AVFoundation
import UIKit

@main
struct PhotoCaptureApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class ImageRecognitionApp: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    func startSession() {
        configureSession()
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                print("[ImageRecognitionApp] Session started")
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                print("[ImageRecognitionApp] Session stopped")
            }
        }
    }

    private func configureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("[ImageRecognitionApp] Error configuring session: No camera available")
            return
        }

        captureSession.beginConfiguration()
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            print("[ImageRecognitionApp] Video input added")
        } else {
            print("[ImageRecognitionApp] Unable to add video input")
            return
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            print("[ImageRecognitionApp] Photo output added")
        } else {
            print("[ImageRecognitionApp] Unable to add photo output")
            return
        }

        captureSession.commitConfiguration()
        print("[ImageRecognitionApp] Capture session configured")
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("[ImageRecognitionApp] Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("[ImageRecognitionApp] Failed to process captured photo")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
            print("[ImageRecognitionApp] Photo captured successfully")
        }
    }
}

struct ContentView: View {
    @StateObject private var imageRecognitionApp = ImageRecognitionApp()
    @State private var showingShareSheet = false

    var body: some View {
        ZStack {
            CameraPreview(session: imageRecognitionApp.captureSession)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                if let capturedImage = imageRecognitionApp.capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding()
                }

                HStack {
                    Button(action: {
                        imageRecognitionApp.capturePhoto()
                    }) {
                        Text("Capture")
                            .font(.title)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Text("Share")
                            .font(.title)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(imageRecognitionApp.capturedImage == nil)
                }
                .padding()
            }
        }
        .onAppear {
            imageRecognitionApp.startSession()
        }
        .onDisappear {
            imageRecognitionApp.stopSession()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let capturedImage = imageRecognitionApp.capturedImage {
                ShareSheet(activityItems: [capturedImage])
            }
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    let session: AVCaptureSession

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        viewController.view.layer.addSublayer(previewLayer)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
