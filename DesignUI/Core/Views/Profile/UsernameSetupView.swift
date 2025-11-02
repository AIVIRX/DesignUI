import SwiftUI

struct UsernameSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var isSaving: Bool = false
    @State private var displayNameError: String = ""
    @State private var usernameError: String = ""
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case displayName
        case username
        case bio
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    displayNameField
                    usernameField
                    bioField
                }
            }
            .navigationTitle("Setup Profile")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    continueButton
                }
                #else
                ToolbarItem(placement: .automatic) {
                    continueButton
                }
                #endif
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Complete Your Profile")
                .font(.title2)
                .fontWeight(.bold)
            Text("Tell us a bit about yourself")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Display Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(displayName.count)/50")
                    .font(.caption)
                    .foregroundColor(displayName.count > 50 ? .red : .secondary)
            }
            
            TextField("John Doe", text: $displayName)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .displayName)
                .submitLabel(.next)
                .onSubmit {
                    validateDisplayName()
                    if displayNameError.isEmpty {
                        focusedField = .username
                    }
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(displayNameFieldBorder)
                .shadow(color: focusedField == .displayName ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                .onChange(of: displayName) { _, newValue in
                    if newValue.count > 50 {
                        displayName = String(newValue.prefix(50))
                    }
                    validateDisplayName()
                }
            
            if !displayNameError.isEmpty {
                Text(displayNameError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Username")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(username.count)/15")
                    .font(.caption)
                    .foregroundColor(username.count > 15 || !usernameError.isEmpty ? .red : .secondary)
            }
            
            TextField("johndoe", text: $username)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit {
                    validateUsername()
                    if usernameError.isEmpty {
                        focusedField = .bio
                    }
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(usernameFieldBorder)
                .shadow(color: focusedField == .username ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
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
            
            if !usernameError.isEmpty {
                Text(usernameError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private var bioField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(bio.count)/130")
                    .font(.caption)
                    .foregroundColor(bio.count > 130 ? .red : .secondary)
            }
            
            ZStack(alignment: .topLeading) {
                if bio.isEmpty {
                    Text("Tell us about yourself...")
                        .foregroundColor(placeholderColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $bio)
                    .focused($focusedField, equals: .bio)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 120)
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .overlay(bioFieldBorder)
                    .shadow(color: focusedField == .bio ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                    .onChange(of: bio) { _, newValue in
                        if newValue.count > 130 {
                            bio = String(newValue.prefix(130))
                        }
                    }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var continueButton: some View {
        Button {
            validateDisplayName()
            validateUsername()
            if displayNameError.isEmpty && usernameError.isEmpty {
                Task { await saveProfile() }
            }
        } label: {
            if isSaving {
                ProgressView()
            } else {
                Text("Continue")
                    .fontWeight(.semibold)
            }
        }
        .disabled(isContinueDisabled)
    }
    
    // Helper computed properties
    private var backgroundColor: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var placeholderColor: Color {
        #if os(iOS)
        Color(uiColor: .placeholderText)
        #else
        Color.secondary.opacity(0.6)
        #endif
    }
    
    private var displayNameFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                displayNameError.isEmpty ? (focusedField == .displayName ? Color.white : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .displayName || !displayNameError.isEmpty ? 2 : 1
            )
    }
    
    private var usernameFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                usernameError.isEmpty ? (focusedField == .username ? Color.white : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .username || !usernameError.isEmpty ? 2 : 1
            )
    }
    
    private var bioFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                focusedField == .bio ? Color.white : Color.gray.opacity(0.3),
                lineWidth: focusedField == .bio ? 2 : 1
            )
    }
    
    private var isContinueDisabled: Bool {
        let hasErrors = !displayNameError.isEmpty || !usernameError.isEmpty
        let isEmpty = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                      username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isSaving || hasErrors || isEmpty
    }
    
    private func validateDisplayName() {
        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayNameError = "Display name cannot be empty"
        } else if displayName.count > 50 {
            displayNameError = "Display name must be 50 characters or less"
        } else {
            displayNameError = ""
        }
    }
    
    private func validateUsername() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedUsername.isEmpty {
            usernameError = "Username cannot be empty"
        } else if trimmedUsername.count > 15 {
            usernameError = "Username must be 15 characters or less"
        } else if !trimmedUsername.allSatisfy({ $0.isLetter || $0.isNumber }) {
            usernameError = "Username can only contain letters and numbers"
        } else {
            usernameError = ""
        }
    }
    
    private func saveProfile() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        // Final validation
        validateDisplayName()
        validateUsername()
        if !displayNameError.isEmpty || !usernameError.isEmpty {
            return
        }
        
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedDisplayName.isEmpty && !trimmedUsername.isEmpty else { return }
        
        isSaving = true
        displayNameError = ""
        usernameError = ""
        
        do {
            // Check if username is already taken
            let checkResponse = try await authViewModel.supabase
                .from("profiles")
                .select("username")
                .eq("username", value: trimmedUsername)
                .execute()
            
            let decoder = JSONDecoder()
            struct UsernameRecord: Decodable { let username: String }
            let existingUsers = try decoder.decode([UsernameRecord].self, from: checkResponse.data)
            
            if !existingUsers.isEmpty {
                await MainActor.run {
                    usernameError = "Username is already taken"
                    isSaving = false
                }
                return
            }
            
            struct ProfileUpsertPayload: Encodable {
                let id: UUID
                let username: String
                let display_name: String
                let bio: String?
            }
            let payload = ProfileUpsertPayload(
                id: userId,
                username: trimmedUsername,
                display_name: trimmedDisplayName,
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            _ = try await authViewModel.supabase
                .from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
            await authViewModel.checkUsername()
        } catch {
            await MainActor.run {
                usernameError = "Failed to save profile. Please try again."
                isSaving = false
            }
        }
        
        isSaving = false
    }
}