//
//  EditProfileView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/22/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var displayName: String
    @State private var username: String
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case displayName
        case username
    }
    
    private let supabase = SupabaseManager.shared.client
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _displayName = State(initialValue: viewModel.profile?.display_name ?? "")
        _username = State(initialValue: viewModel.profile?.username ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture Section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 70, height: 70)
                            
                            Text(displayName.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Display Name
                        FormField(
                            title: "Display Name",
                            placeholder: "Enter your display name",
                            text: $displayName,
                            icon: "person.fill"
                        ) {
                            focusedField = .username
                        }
                        .focused($focusedField, equals: .displayName)
                        
                        // Username
                        FormField(
                            title: "Username",
                            placeholder: "Enter your username",
                            text: $username,
                            icon: "at"
                        ) {
                            Task {
                                await updateProfile()
                            }
                        }
                        .focused($focusedField, equals: .username)
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button {
                        Task {
                            await updateProfile()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Edit Profile")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
#endif
            .onSubmit {
                switch focusedField {
                case .displayName:
                    focusedField = .username
                case .username:
                    Task {
                        await updateProfile()
                    }
                case .none:
                    break
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateProfile() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        isLoading = true
        
        do {
            // Check if username is already taken (only if changed)
            if username != viewModel.profile?.username {
                let checkResponse = try await supabase
                    .from("profiles")
                    .select("username")
                    .eq("username", value: username.lowercased())
                    .neq("id", value: userId)  // Exclude current user
                    .execute()
                
                let decoder = JSONDecoder()
                let existingUsers = try decoder.decode([Profile].self, from: checkResponse.data)
                
                if !existingUsers.isEmpty {
                    showError = true
                    errorMessage = "Username is already taken"
                    isLoading = false
                    return
                }
            }
            
            // Proceed with updating profile if all checks pass
            try await supabase
                .from("profiles")
                .upsert([
                    "id": userId.uuidString,
                    "display_name": displayName,
                    "username": username.lowercased(),
                    "updated_at": ISO8601DateFormatter().string(from: Date()),
                ], onConflict: "id")
                .select()
                .single()
                .execute()
            
            // Refresh user profile after successful update
            await authViewModel.checkUsername()
            await viewModel.fetchProfile()
            dismiss()
            
        } catch {
            showError = true
            errorMessage = "Username is not available"  // More user-friendly error message
        }
        
        isLoading = false
    }
    // Helper view for form fields
    struct FormField: View {
        let title: String
        let placeholder: String
        @Binding var text: String
        let icon: String
        var onSubmit: (() -> Void)? = nil
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .foregroundColor(.gray)
                
                TextField(placeholder, text: $text)
                    .contentShape(RoundedRectangle(cornerRadius: 12))
#if os(iOS)
                    .autocapitalization(.none)
                    .submitLabel(.next) // Show next on keyboard
#endif
                    .autocorrectionDisabled()
                    .onSubmit {
                        onSubmit?()
                    }
            }
        }
    }
}
