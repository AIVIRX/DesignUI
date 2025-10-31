import SwiftUI

struct UsernameSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a username")
                .font(.title2.bold())
            Text("This will be your public handle. You can change it later.")
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Username")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(username.count)/15")
                        .font(.caption)
                        .foregroundColor(username.count > 15 || !errorMessage.isEmpty ? .red : .secondary)
                }
                
                TextField("username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(isSaving)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(errorMessage.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .onChange(of: username) { _, newValue in
                        // Filter to only alphanumeric characters
                        let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                        if filtered != newValue {
                            username = filtered
                        }
                        
                        // Limit to 15 characters
                        if username.count > 15 {
                            username = String(username.prefix(15))
                        }
                        
                        validateUsername()
                    }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Button(action: { 
                validateUsername()
                if errorMessage.isEmpty {
                    Task { await saveUsername() }
                }
            }) {
                if isSaving { ProgressView() } else { Text("Continue") }
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving || !errorMessage.isEmpty)
        }
        .padding()
    }
    
    private func validateUsername() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedUsername.isEmpty {
            errorMessage = "Username cannot be empty"
        } else if trimmedUsername.count > 15 {
            errorMessage = "Username must be 15 characters or less"
        } else if !trimmedUsername.allSatisfy({ $0.isLetter || $0.isNumber }) {
            errorMessage = "Username can only contain letters and numbers"
        } else {
            errorMessage = ""
        }
    }
    
    private func saveUsername() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        // Final validation
        validateUsername()
        if !errorMessage.isEmpty {
            return
        }
        
        isSaving = true
        errorMessage = ""
        
        do {
            // Check if username is already taken
            let checkResponse = try await authViewModel.supabase
                .from("profiles")
                .select("username")
                .eq("username", value: trimmed)
                .execute()
            
            let decoder = JSONDecoder()
            struct UsernameRecord: Decodable { let username: String }
            let existingUsers = try decoder.decode([UsernameRecord].self, from: checkResponse.data)
            
            if !existingUsers.isEmpty {
                await MainActor.run {
                    errorMessage = "Username is already taken"
                    isSaving = false
                }
                return
            }
            
            struct ProfileUpsertPayload: Encodable {
                let id: UUID
                let username: String
                let display_name: String
            }
            let payload = ProfileUpsertPayload(id: userId, username: trimmed, display_name: trimmed)
            _ = try await authViewModel.supabase
                .from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
            await authViewModel.checkUsername()
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save username. Please try again."
            }
        }
        
        isSaving = false
    }
}


