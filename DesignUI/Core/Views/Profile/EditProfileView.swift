import SwiftUI

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
                    
                    Form {
                        Section {
                            // Key ID
                            HStack(alignment: .top, spacing: 16) {
                                TextField("Display Name",text: $displayName, prompt: Text("John Doe"))
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .displayName)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .username
                                    }
                            }
                            
                            // Username
                            HStack(alignment: .top, spacing: 16) {
                                TextField("Username", text: $username, prompt: Text("johndoe"))
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .username)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .bio
                                    }
                            }
                            
                            // Bio
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Bio")
                                    
                                    Spacer()
                                    
                                    Text("\(bio.count)/130")
                                        .font(.caption)
                                        .foregroundColor(bio.count > 130 ? .red : .secondary)
                                }
                                
                                TextField("", text: $bio, prompt: Text("Tell us about yourself..."), axis: .vertical)
                                    .focused($focusedField, equals: .bio)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        Task {
                                            await updateProfile()
                                        }
                                    }
                                    .lineLimit(3...6)
                                    .onChange(of: bio) { _, newValue in
                                        if newValue.count > 130 {
                                            bio = String(newValue.prefix(130))
                                        }
                                    }
                            }
                        }
                    }
                        .formStyle(.grouped)
                    
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
#else
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await updateProfile()
                            }
                        }
                        .disabled(isLoading)
                    }
                }
#endif
                .onSubmit {
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
                if username != viewModel.profile?.username {
                    let checkResponse = try await supabase
                        .from("profiles")
                        .select("username")
                        .eq("username", value: username)
                        .neq("id", value: userId)
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
                
                try await supabase
                    .from("profiles")
                    .upsert([
                        "id": userId.uuidString,
                        "display_name": displayName,
                        "username": username.lowercased(),
                        "bio": bio,
                        "updated_at": ISO8601DateFormatter().string(from: Date()),
                    ], onConflict: "id")
                    .select()
                    .single()
                    .execute()
                
                await authViewModel.checkUsername()
                await viewModel.fetchProfile()
                dismiss()
                
            } catch {
                showError = true
                errorMessage = "Username is not available"
            }
            
            isLoading = false
        }
    }
