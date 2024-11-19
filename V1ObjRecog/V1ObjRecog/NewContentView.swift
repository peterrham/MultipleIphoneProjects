//
//  ContentView 2.swift
//  V1ObjRecog
//
//  Created by Ham, Peter on 11/14/24.
//
import SwiftUI
import CoreML
import Vision
import AVFoundation

struct NewContentView: View {
    @StateObject private var imageRecognitionApp = ImageRecognitionApp()
    
    var body: some View {
        ZStack {
            CameraPreview(session: imageRecognitionApp.captureSession)
                .edgesIgnoringSafeArea(.all) // Ensures the preview fills the screen
            VStack {
                Spacer()
                Text("Detected: \(imageRecognitionApp.recognizedObject)")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .onAppear {
            imageRecognitionApp.startSession()
        }
        .onDisappear {
            imageRecognitionApp.stopSession()
        }
    }
}

