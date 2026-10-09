import SwiftUI
import PhotosUI
import Supabase

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ProfileViewModel
    @State private var displayName: String
    @State private var username: String
    @State private var bio: String
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var displayNameError: String = ""
    @State private var usernameError: String = ""
    
    // Photo Selection
    #if os(iOS)
    @State private var selectedItem: PhotosPickerItem?
    #endif
    @State private var selectedImageData: Data?
    @State private var avatarUrl: String?
    @State private var isImporting = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case displayName
        case username
        case bio
    }
    
    private let supabase = SupabaseManager.shared.client
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _displayName = State(initialValue: viewModel.profile?.display_name ?? "")
        _username = State(initialValue: viewModel.profile?.username ?? "")

        _bio = State(initialValue: viewModel.profile?.bio ?? "")
        _avatarUrl = State(initialValue: viewModel.profile?.avatarUrl ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profilePictureSection
                    displayNameField
                    usernameField
                    bioField
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
#else
            .toolbar(id: "editProfileToolbar") {
                ToolbarItem(id: "cancel", placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(id: "save", placement: .confirmationAction) {
                    saveButton
                }
            }
#endif
            .onSubmit {
                handleSubmit()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var profilePictureSection: some View {
        VStack(spacing: 12) {
            #if os(iOS)
            PhotosPicker(selection: $selectedItem, matching: .images) {
                avatarView
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
            #else
            Button(action: {
                isImporting = true
            }) {
                avatarView
            }
            .buttonStyle(.plain)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Access security scoped resource
                        guard url.startAccessingSecurityScopedResource() else { return }
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        if let data = try? Data(contentsOf: url) {
                            DispatchQueue.main.async {
                                selectedImageData = data
                            }
                        }
                    }
                case .failure(let error):
                    print("File import failed: \(error.localizedDescription)")
                }
            }
            #endif
        }
        .padding(.top)
    }
    
    private var avatarView: some View {
        ZStack {
            if let selectedImageData {
                #if os(iOS)
                if let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: selectedImageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                }
                #endif
            } else if let avatarUrl, let url = URL(string: avatarUrl) {
                CachedRemoteImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 80, height: 80)
                    
                    Text(displayName.prefix(1).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Edit overlay
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 80, height: 80)
            
            Image(systemName: "camera.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
                .offset(x: 25, y: 25)
        }
    }
    
    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            displayNameHeader
            displayNameInput
            
            if !displayNameError.isEmpty {
                Text(displayNameError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }

    private var displayNameHeader: some View {
        HStack {
            Text("Display Name")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            Text(verbatim: "\(displayName.count)/50")
                .font(.caption)
                .foregroundColor(displayNameCountColor)
        }
    }

    private var displayNameInput: some View {
        TextField("John Doe", text: $displayName)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .displayName)
            .submitLabel(.next)
            .onSubmit {
                handleDisplayNameSubmit()
            }
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(displayNameFieldBorder)
            .shadow(color: displayNameShadowColor, radius: 4, x: 0, y: 2)
            .onChange(of: displayName) { _, newValue in
                sanitizeDisplayName(newValue)
            }
    }

    private var displayNameCountColor: Color {
        (displayName.count > 50 || !displayNameError.isEmpty) ? .red : .secondary
    }

    private var displayNameShadowColor: Color {
        focusedField == .displayName ? Color.black.opacity(0.1) : .clear
    }

    private func handleDisplayNameSubmit() {
        validateDisplayName()
        if displayNameError.isEmpty {
            focusedField = .username
        }
    }

    private func sanitizeDisplayName(_ newValue: String) {
        if newValue.count > 50 {
            displayName = String(newValue.prefix(50))
        }
        validateDisplayName()
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            usernameHeader
            usernameInput
            
            if !usernameError.isEmpty {
                Text(usernameError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }

    private var usernameHeader: some View {
        HStack {
            Text("Username")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            Text(verbatim: "\(username.count)/15")
                .font(.caption)
                .foregroundColor(usernameCountColor)
        }
    }

    private var usernameInput: some View {
        TextField("johndoe", text: $username)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .focused($focusedField, equals: .username)
            .submitLabel(.next)
            .onSubmit {
                handleUsernameSubmit()
            }
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(usernameFieldBorder)
            .shadow(color: usernameShadowColor, radius: 4, x: 0, y: 2)
            .onChange(of: username) { _, newValue in
                sanitizeUsername(newValue)
            }
    }

    private var usernameCountColor: Color {
        (username.count > 15 || !usernameError.isEmpty) ? .red : .secondary
    }

    private var usernameShadowColor: Color {
        focusedField == .username ? Color.black.opacity(0.1) : .clear
    }

    private func handleUsernameSubmit() {
        validateUsername()
        if usernameError.isEmpty {
            focusedField = .bio
        }
    }

    private func sanitizeUsername(_ newValue: String) {
        let filtered = newValue.filter { $0.isLetter || $0.isNumber }
        if filtered != newValue {
            username = filtered
        }

        if username.count > 15 {
            username = String(username.prefix(15))
        }

        validateUsername()
    }
    
    private var bioField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(verbatim: "\(bio.count)/130")
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
                    .frame(minHeight: 60, maxHeight: 100)
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
    
    private var saveButton: some View {
        Button("Save") {
            validateDisplayName()
            validateUsername()
            if displayNameError.isEmpty && usernameError.isEmpty {
                Task {
                    await updateProfile()
                }
            }
        }
        .disabled(isSaveDisabled)
    }
    
    private func handleSubmit() {
        switch focusedField {
        case .displayName:
            focusedField = .username
        case .username:
            focusedField = .bio
        case .bio:
            Task {
                await updateProfile()
            }
        case .none:
            break
        }
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
                displayNameError.isEmpty ? (focusedField == .displayName ? Color.accentColor : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .displayName || !displayNameError.isEmpty ? 2 : 1
            )
    }
    
    private var usernameFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                usernameError.isEmpty ? (focusedField == .username ? Color.accentColor : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .username || !usernameError.isEmpty ? 2 : 1
            )
    }
    
    private var bioFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                focusedField == .bio ? Color.accentColor : Color.gray.opacity(0.3),
                lineWidth: focusedField == .bio ? 2 : 1
            )
    }
    
    private var isSaveDisabled: Bool {
        isLoading || !displayNameError.isEmpty || !usernameError.isEmpty
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
        
    private func updateProfile() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        // Final validation before saving
        validateDisplayName()
        validateUsername()
        
        if !displayNameError.isEmpty || !usernameError.isEmpty {
            return
        }
        
        isLoading = true
        
        // Upload photo if changed
        if let selectedImageData {
            if let uploadedUrl = await uploadAvatar(userId: userId, data: selectedImageData) {
                avatarUrl = uploadedUrl
            }
        }
        
        do {
            // Check username uniqueness if it changed
            if username.lowercased() != viewModel.profile?.username?.lowercased() {
                let checkResponse = try await supabase
                    .from("profiles")
                    .select("username")
                    .eq("username", value: username.lowercased())
                    .neq("id", value: userId.uuidString)
                    .execute()
                
                let decoder = JSONDecoder()
                struct UsernameRecord: Decodable { let username: String }
                let existingUsers = try decoder.decode([UsernameRecord].self, from: checkResponse.data)
                
                if !existingUsers.isEmpty {
                    await MainActor.run {
                        usernameError = "Username is already taken"
                        isLoading = false
                    }
                    return
                }
            }
            
            let updatePayload = ProfileUpdatePayload(
                id: userId.uuidString,
                display_name: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                username: username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                bio: sanitizeBio(bio),
                avatar_url: avatarUrl,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("profiles")
                .upsert(updatePayload, onConflict: "id")
                .select()
                .single()
                .execute()
            
            await authViewModel.checkUsername()
            await viewModel.fetchProfile()
            dismiss()
            
        } catch {
            await MainActor.run {
                showError = true
                errorMessage = "Failed to update profile. Please try again."
                print("Error updating profile: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func uploadAvatar(userId: UUID, data: Data) async -> String? {
        // Check file size (limit 10MB)
        let fileSizeInMB = Double(data.count) / (1024 * 1024)
        if fileSizeInMB > 10 {
            await MainActor.run {
                errorMessage = "Image size too large. Please select an image under 10MB."
                showError = true
            }
            return nil
        }
        
        let fileName = "\(userId.uuidString)/avatar.jpg"
        
        do {
            // Upload to Supabase Storage
            _ = try await supabase.storage
                .from("avatars")
                .upload(
                    fileName,
                    data: data,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            
            // Get Public URL
            let publicUrl = try supabase.storage
                .from("avatars")
                .getPublicURL(path: fileName)
            
            // Append timestamp to bust cache since filename is constant
            return "\(publicUrl.absoluteString)?t=\(Int(Date().timeIntervalSince1970))"
            
        } catch {
            print("Error uploading avatar: \(error)")
            await MainActor.run {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                showError = true
            }
            return nil
        }
    }
}

// Helper struct for updates
private struct ProfileUpdatePayload: Encodable {
    let id: String
    let display_name: String
    let username: String
    let bio: String
    let avatar_url: String?
    let updated_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case display_name
        case username
        case bio
        case avatar_url
        case updated_at
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(display_name, forKey: .display_name)
        try container.encode(username, forKey: .username)
        try container.encode(bio, forKey: .bio)
        try container.encodeIfPresent(avatar_url, forKey: .avatar_url)
        try container.encode(updated_at, forKey: .updated_at)
    }
}

private func sanitizeBio(_ value: String) -> String {
    let nonEmptyLines = value
        .components(separatedBy: .newlines)
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    return nonEmptyLines
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
