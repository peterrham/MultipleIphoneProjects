//
//  SimpleCameraView.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/14/24.
//

import SwiftUI
import AVFoundation

struct SimpleCameraView: View {
    var body: some View {
        CameraPreview(session: AVCaptureSession()) // Temporary session for testing
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                let session = AVCaptureSession()
                guard let captureDevice = AVCaptureDevice.default(for: .video),
                      let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
                session.addInput(input)
                session.startRunning()
            }
    }
}
