//
//  ContentView 2.swift
//  V2NoScopesApp
//
//  Created by Ham, Peter on 11/10/24.
//


import SwiftUI

struct SignInContentView: View {
    @EnvironmentObject var googleSignInManager: GoogleSignInManager

    var body: some View {
        VStack {
            if let user = googleSignInManager.user {
                Text("Hello, \(user.profile?.name ?? "User")!")
                Button("Sign Out") {
                    googleSignInManager.signOut()
                }
            } else {
                Button(action: {
                    googleSignInManager.signIn()
                }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Sign in with Google")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
