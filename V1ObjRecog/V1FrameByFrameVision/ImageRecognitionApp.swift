//
//  ImageRecognitionApp.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/14/24.
//


import AVFoundation
import Vision
import SwiftUI

class ImageRecognitionApp: NSObject, ObservableObject {
    private(set) var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    
    @Published var recognizedObject: String = "None"
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Error: No video capture device found.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Add photo output for still image capture
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            captureSession.startRunning()
        } catch {
            print("Error setting up camera input: \(error)")
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
    
    // Capture a still photo on button press
    func capturePhoto() {
        // Initialize photo settings with the desired format
        let photoSettings = AVCapturePhotoSettings(
            format: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        
        // Capture photo with configured settings
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }


}

extension ImageRecognitionApp: AVCapturePhotoCaptureDelegate {
    // Delegate method called when a photo is captured
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        // Get the image as a CVPixelBuffer for Vision model processing
        guard let pixelBuffer = photo.pixelBuffer else {
            print("returning")
            
            return }
        
        print("before recognizing")
        
        recognizeObject(in: pixelBuffer)
    }
    // Perform object recognition on the captured image
    private func recognizeObject(in pixelBuffer: CVPixelBuffer) {
        print("Recognizing object...")
            // guard let model = try? VNCoreMLModel(for: MobileNetV2FP16().model) else {
        // guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {

        
        print("Failed to load model")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                DispatchQueue.main.async {
                    self?.recognizedObject = "\(topResult.identifier) \(Int(topResult.confidence * 100))%"
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Error performing object recognition: \(error)")
        }
    }
}
