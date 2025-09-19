//
//  UsernameSelectionView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/25.
//

import SwiftUI

struct UsernameSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var usernameValidationMessage = ""
    @State private var isUsernameValid = false
    let supabase = SupabaseManager.shared.client

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Choose Your Username")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Pick a unique username that represents you.\nThis will be your public identity on Dock UI.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Username")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(username.count)/20")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        TextField("Enter username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .onChange(of: username) { _, newValue in
                                validateUsername(newValue)
                            }
                        
                        if !usernameValidationMessage.isEmpty {
                            Text(usernameValidationMessage)
                                .font(.caption)
                                .foregroundColor(isUsernameValid ? .green : .red)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            guard let userId = authViewModel.currentUser?.id else { return }
                            
                            authViewModel.isLoading = true
                            
                            do {
                                _ = try await authViewModel.supabase
                                    .from("profiles")
                                    .upsert([
                                        "id": userId.uuidString,
                                        "display_name": username,
                                        "username": username.lowercased(),
                                        "updated_at": ISO8601DateFormatter().string(from: Date()),
                                    ], onConflict: "id")
                                    .select()
                                    .single()
                                    .execute()
                                
                                await MainActor.run {
                                    authViewModel.hasUsername = true
                                    authViewModel.isLoading = false
                                }
                                
                            } catch {
                                await MainActor.run {
                                    authViewModel.showError = true
                                    authViewModel.errorMessage = "Username is not available"
                                    authViewModel.isLoading = false
                                }
                            }
                        }
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(authViewModel.isLoading ? "Creating Profile..." : "Complete Setup")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isUsernameValid && !authViewModel.isLoading ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!isUsernameValid || authViewModel.isLoading)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding()
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
    
    
    
    private func validateUsername(_ username: String) {
        // Reset validation
        usernameValidationMessage = ""
        isUsernameValid = false
        
        // Check if empty
        if username.isEmpty {
            return
        }
        
        // Check length
        if username.count < 3 {
            usernameValidationMessage = "Username must be at least 3 characters"
            return
        }
        
        if username.count > 20 {
            usernameValidationMessage = "Username must be less than 20 characters"
            return
        }
        
        // Check for valid characters (alphanumeric and underscores only)
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if username.rangeOfCharacter(from: validCharacterSet.inverted) != nil {
            usernameValidationMessage = "Username can only contain letters, numbers, and underscores"
            return
        }
        
        // Check if starts with letter or number
        if !username.first!.isLetter && !username.first!.isNumber {
            usernameValidationMessage = "Username must start with a letter or number"
            return
        }
        
        // If we get here, username is valid
        isUsernameValid = true
        usernameValidationMessage = "Username is available!"
    }
}
