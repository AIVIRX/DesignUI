import SwiftUI

struct UploadTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var code: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var titleError: String = ""
    @State private var descriptionError: String = ""
    @State private var codeError: String = ""
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case title
        case description
        case code
    }
    
    private let supabase = SupabaseManager.shared.client
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    titleField
                    descriptionField
                    codeField
                }
            }
            .navigationTitle("Upload Template")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar(id: "uploadTemplateToolbar") {
                ToolbarItem(id: "cancel", placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(id: "upload", placement: .confirmationAction) {
                    uploadButton
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(title.count)/100")
                    .font(.caption)
                    .foregroundColor(title.count > 100 || !titleError.isEmpty ? .red : .secondary)
            }
            
            TextField("My Awesome Design", text: $title)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit {
                    validateTitle()
                    if titleError.isEmpty {
                        focusedField = .description
                    }
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(titleFieldBorder)
                .shadow(color: focusedField == .title ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                .onChange(of: title) { _, newValue in
                    if newValue.count > 100 {
                        title = String(newValue.prefix(100))
                    }
                    validateTitle()
                }
            
            if !titleError.isEmpty {
                Text(titleError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(description.count)/500")
                    .font(.caption)
                    .foregroundColor(description.count > 500 || !descriptionError.isEmpty ? .red : .secondary)
            }
            
            TextField("Describe your design...", text: $description)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .description)
                .submitLabel(.next)
                .onSubmit {
                    validateDescription()
                    if descriptionError.isEmpty {
                        focusedField = .code
                    }
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(descriptionFieldBorder)
                .shadow(color: focusedField == .description ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                .onChange(of: description) { _, newValue in
                    if newValue.count > 500 {
                        description = String(newValue.prefix(500))
                    }
                    validateDescription()
                }
            
            if !descriptionError.isEmpty {
                Text(descriptionError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private var codeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Code")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(code.count)/10000")
                    .font(.caption)
                    .foregroundColor(code.count > 10000 || !codeError.isEmpty ? .red : .secondary)
            }
            
            ZStack(alignment: .topLeading) {
                if code.isEmpty {
                    Text("Paste your SwiftUI code here...")
                        .foregroundColor(placeholderColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $code)
                    .focused($focusedField, equals: .code)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 200)
                    .font(.system(size: 14, design: .monospaced))
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .overlay(codeFieldBorder)
                    .shadow(color: focusedField == .code ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                    .onChange(of: code) { _, newValue in
                        if newValue.count > 10000 {
                            code = String(newValue.prefix(10000))
                        }
                        validateCode()
                    }
            }
            
            if !codeError.isEmpty {
                Text(codeError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var uploadButton: some View {
        Button("Upload") {
            validateTitle()
            validateDescription()
            validateCode()
            if titleError.isEmpty && descriptionError.isEmpty && codeError.isEmpty {
                Task {
                    await uploadTemplate()
                }
            }
        }
        .disabled(isUploadDisabled)
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
    
    private var titleFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                titleError.isEmpty ? (focusedField == .title ? Color.white : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .title || !titleError.isEmpty ? 2 : 1
            )
    }
    
    private var descriptionFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                descriptionError.isEmpty ? (focusedField == .description ? Color.white : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .description || !descriptionError.isEmpty ? 2 : 1
            )
    }
    
    private var codeFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                codeError.isEmpty ? (focusedField == .code ? Color.white : Color.gray.opacity(0.3)) : Color.red,
                lineWidth: focusedField == .code || !codeError.isEmpty ? 2 : 1
            )
    }
    
    private var isUploadDisabled: Bool {
        let hasErrors = !titleError.isEmpty || !descriptionError.isEmpty || !codeError.isEmpty
        let isEmpty = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                      description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                      code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isLoading || hasErrors || isEmpty
    }
    
    private func validateTitle() {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleError = "Title cannot be empty"
        } else if title.count > 100 {
            titleError = "Title must be 100 characters or less"
        } else {
            titleError = ""
        }
    }
    
    private func validateDescription() {
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            descriptionError = "Description cannot be empty"
        } else if description.count > 500 {
            descriptionError = "Description must be 500 characters or less"
        } else {
            descriptionError = ""
        }
    }
    
    private func validateCode() {
        if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            codeError = "Code cannot be empty"
        } else if code.count > 10000 {
            codeError = "Code must be 10000 characters or less"
        } else {
            codeError = ""
        }
    }
    
    private func uploadTemplate() async {
        guard let userId = supabase.auth.currentUser?.id else {
            await MainActor.run {
                showError = true
                errorMessage = "You must be signed in to upload templates."
                isLoading = false
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
            
            struct PostInsert: Encodable {
                let title: String
                let description: String
                let code_snippet: String
                let author_id: UUID
                let status: String
                let preview_image_url: String
            }
            
            let postData = PostInsert(
                title: trimmedTitle,
                description: trimmedDescription,
                code_snippet: trimmedCode,
                author_id: userId,
                status: "pending",
                preview_image_url: "" // Placeholder - can be updated later with actual preview image
            )
            
            _ = try await supabase
                .from("posts")
                .insert(postData)
                .execute()
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                showError = true
                errorMessage = "Failed to upload template. Please try again."
                isLoading = false
            }
            print("Error uploading template: \(error)")
        }
    }
}

