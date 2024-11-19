//
//  ContentView 2.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/13/24.
//


import SwiftUI
import AVFoundation
import Vision
import CoreML

struct VisionContentView: View {
    @StateObject private var model = ImageRecognitionModel()
    
    var body: some View {
        VStack {
            Text("Object: \(model.recognizedObject)")
            // Camera preview and results display
        }
        .onAppear {
            model.startSession()
        }
    }
}

class ImageRecognitionModel: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession!
    private var request: VNCoreMLRequest!
    @Published var recognizedObject: String = ""
    
    override init() {
        super.init()
        setupVisionModel()
        setupCamera()
    }
    
    private func setupVisionModel() {
        guard let model = try? VNCoreMLModel(for: MobileNetV2FP16().model) else { return }
        request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                DispatchQueue.main.async {
                    self.recognizedObject = topResult.identifier
                }
            }
        }
    }
    
    private func setupCamera() {
        // Configure AVCaptureSession for live image capture
    }
    
    func startSession() {
        captureSession.startRunning()
    }
}
