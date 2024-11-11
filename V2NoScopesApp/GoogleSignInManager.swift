import SwiftUI
import GoogleSignIn

class GoogleSignInManager: ObservableObject {
    @Published var user: GIDGoogleUser? = nil
    private let signInConfig: GIDConfiguration
    
    init(clientID: String) {
        // Initialize GIDConfiguration with your client ID
        self.signInConfig = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = self.signInConfig
    }
    
    func signIn() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Error: Unable to access root view controller.")
            return
        }
        
        // Start sign-in with configuration and presenting view controller
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else {
                print("Error: Sign-in result is nil.")
                return
            }
            
            self?.user = user
            print("Signed in successfully! User: \(user.profile?.name ?? "No Name")")
            
            // Retrieve the access token
            if let accessToken = self?.user!.accessToken.tokenString {
                print("Access Token: \(accessToken)")
                // You can use this access token with Google APIs, such as the People API
            }
            
            // Validate ID token if needed
            if let idToken = user.idToken?.tokenString {
                self?.validateIDToken(idToken)
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
        print("Signed out")
    }
    
    func validateIDToken(_ idToken: String) {
        guard let url = URL(string: "https://oauth2.googleapis.com/tokeninfo?id_token=\(idToken)") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error validating token: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Token Validation Response: \(json)")
                    // Additional checks can be added, such as verifying audience ("aud") or expiration ("exp")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
}
