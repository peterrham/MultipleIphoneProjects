import SwiftUI

struct ContentView: View {
    @StateObject private var imageRecognitionApp = ImageRecognitionApp()
    
    var body: some View {
        ZStack {
            // Display the live camera preview
            CameraPreview(session: imageRecognitionApp.captureSession)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Display the recognized object
                Text("Detected: \(imageRecognitionApp.recognizedObject)")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                
                // Capture button to take a still frame for recognition
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
