import SwiftUI

struct ContentView: View {
    @EnvironmentObject var googleSignInManager: GoogleSignInManager

    var body: some View {
        VStack {
            Button("createSpreadsheet") {
                googleSignInManager.createSpreadsheet()
                }
         Button("Disconect") {
                googleSignInManager.disconnect()
                }
            Button("FetchUserInfo") {
                googleSignInManager.fetchAndPrintUserInfo()
                }
            
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
