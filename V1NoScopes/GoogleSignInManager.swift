//
//  GoogleSignInManager.swift
//  V1NoScopesApp
//
//  Created by Ham, Peter on 11/10/24.
//


import SwiftUI
import GoogleSignIn
//import GoogleSignInSwift

class GoogleSignInManager: ObservableObject {
    @Published var user: GIDGoogleUser? = nil
    private let signInConfig = GIDConfiguration(clientID: "YOUR_CLIENT_ID")

    func signIn() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: rootViewController) { [weak self] user, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            self?.user = user
            print("Signed in successfully!")
            // Optional: validate the token here if needed.
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
        print("Signed out")
    }
}
