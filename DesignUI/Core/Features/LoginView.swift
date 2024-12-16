//
//  LoginView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/15/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
            VStack(spacing: 20) {
                Spacer()
                
                // App Logo or Title
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Design UI")
                    .font(.largeTitle)
                    .bold()
                
                Text("Sign in to access your account")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Sign in options
                VStack(spacing: 15) {
                    SignInWithAppleView()
                        .frame(height: 50)
                    
                    // Add other sign-in options here
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Terms and Privacy links
                HStack {
//                    Text("•")
                    Link("Privacy Policy", destination: URL(string: "https://dockui.com/privacy")!)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding()
    }
}

#Preview {
    LoginView()
}
