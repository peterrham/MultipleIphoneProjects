import SwiftUI
import GoogleSignIn

@main
struct V2NoScopesApp: App {
        @StateObject private var googleSignInManager = GoogleSignInManager(clientID: "748381179204-hp1qqcpa5jr929nj0hs6sou0sb6df60a.apps.googleusercontent.com")
    
    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "748381179204-hp1qqcpa5jr929nj0hs6sou0sb6df60a.apps.googleusercontent.com")
    }
    
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(googleSignInManager)
            }
        }
    }
