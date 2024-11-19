import SwiftUI
import AVFoundation
import Vision

struct BarCodeContentView: View {
    @StateObject private var barcodeScanner = BarcodeScanner()
    
    var body: some View {
        ZStack {
            CameraView(scanner: barcodeScanner)
                .edgesIgnoringSafeArea(.all)
             
            
           // XXX if let scannedCode = barcodeScanner.detectedCode {
            
            let scannedCode = "Test Button"
  
                Text("Scanned Code: \(scannedCode)")
                    .padding()
                    // .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
            // }
        }
    }
}

class BarcodeScanner: NSObject, ObservableObject {
    @Published var detectedCode: String? = nil
    
 
    // Make captureSession accessible by changing its access level
    let captureSession = AVCaptureSession()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "BarcodeScannerQueue")
    
    override init() {
        print("BarcodeScanner initialized")
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("Error: No video device available.")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Error: Could not add video input.")
            }
        } catch {
            print("Error: Could not create video input - \(error)")
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Error: Could not add video output.")
        }

        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
}

extension BarcodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        print("captureOutput")
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        print("AFTER captureOutput")
        
        let request = VNDetectBarcodesRequest { request, error in
            print("VNDetectBarcodesRequest")
            if let results = request.results as? [VNBarcodeObservation], let firstResult = results.first {
                DispatchQueue.main.async {
                    self.detectedCode = firstResult.payloadStringValue
                }
            }
        }
        
        print("VNImageRequestHandler")
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? requestHandler.perform([request])
        
        print("END BarcodeScanner.captureOutput")
    }
}


struct CameraView: UIViewRepresentable {
    let scanner: BarcodeScanner
    
    func makeUIView(context: Context) -> UIView {
        
        print("CameraView.makeUIView")
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

@main
struct BarcodeApp: App {
    var body: some Scene {
        WindowGroup {
            BarCodeContentView()
        }
    }
}
