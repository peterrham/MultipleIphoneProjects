//
//  CameraPreview.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/14/24.
//


import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // Create an AVCaptureVideoPreviewLayer using the session and add it to the view
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        previewLayer.connection?.videoOrientation = .portrait // Use .portrait for most apps

        
        view.layer.addSublayer(previewLayer)
        
        // Set the frame of the preview layer to match the view bounds
                DispatchQueue.main.async {
                    previewLayer.frame = view.bounds
                }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // You can add code here to update the view when SwiftUI state changes
        // For example, resizing the preview layer if needed
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                           previewLayer.frame = uiView.bounds
                       }
        }
    }
}
