//
//  UsernameSetupView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/10/25.
//

import SwiftUI

struct UsernameSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss // ✅ Allows view to close itself
    @State private var username = ""
    @State private var isLoading = false
    @State private var error: String?
    
    private let supabase = SupabaseManager.shared.client
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose a Username")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This will be your unique identifier on Dockui")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button {
                    Task {
                        await setupUsername()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(username.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(username.isEmpty || isLoading)
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationBarBackButtonHidden()
        }
    }
    
    private func setupUsername() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        isLoading = true
        error = nil
        
        do {
            // Check if username is available
            let existingUsernames: [[String: String]] = try await supabase
                .from("profiles")
                .select("id")
                .eq("username", value: username.lowercased())
                .execute()
                .value
            
            if !existingUsernames.isEmpty {
                error = "Username is already taken"
                isLoading = false
                return
            }
            
            // Update profile with new username
            try await supabase
                .from("profiles")
                .update([
                    "username": username.lowercased(),
                    "display_name": username
                ])
                .eq("id", value: userId)
                .execute()
            
            // Refresh authViewModel
            await authViewModel.checkUsername()

            // ✅ Dismiss the setup view after successfully setting username
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }

        isLoading = false
    }
}
