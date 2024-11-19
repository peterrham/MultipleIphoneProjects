//
//  ImageRecognitionApp.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/14/24.
//


import CoreML
import Vision
import AVFoundation

class ImageRecognitionApp: NSObject, ObservableObject {
    // MARK: - Properties
    private(set) var captureSession = AVCaptureSession()
    private var request: VNCoreMLRequest!
    
    @Published var recognizedObject: String = "None"
    
    // MARK: - Initializer
    override init() {
        super.init()
        setupVisionModel()
        setupCamera()
    }
    
    // MARK: - Vision Model Setup
    private func setupVisionModel() {
        // Load the ML model for inference only
        guard let model = try? VNCoreMLModel(for: MobileNetV2FP16().model) else {
            fatalError("Failed to load model")
        }
        
        // Create a Vision request with the CoreML model
        request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                DispatchQueue.main.async {
                    // Update recognizedObject with the prediction result
                    self?.recognizedObject = "\(topResult.identifier) \(Int(topResult.confidence * 100))%"
                }
            }
        }
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        // Configure the camera input
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print("Error setting up camera input: \(error)")
        }
        
        // Configure the camera output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
    }
    
    // MARK: - Session Control
    func startSession() {
        if !captureSession.isRunning {
            print("Starting capture session...")
            captureSession.startRunning()
        } else {
            print("Capture session is already running.")
        }
    }

    
    func stopSession() {
        captureSession.stopRunning()
    }
}

extension ImageRecognitionApp: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Perform the Vision request on each frame
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
