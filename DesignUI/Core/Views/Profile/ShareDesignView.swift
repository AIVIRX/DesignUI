//
//  ShareDesignView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/5/26.
//

import SwiftUI

struct ShareDesignView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let designFile: DesignFile
    let canvasManager: CanvasManager
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var uploadProgress: String = ""
    @State private var showSignInAlert = false
    
    private let supabase = SupabaseManager.shared.client
    private let imageUploadService = ImageUploadService.shared
    
    /// Returns the current user ID if signed in
    private var currentUserId: UUID? {
        supabase.auth.currentUser?.id
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Thumbnail
                    previewSection
                    
                    // Title Field
                    titleField
                    
                    // Description Field
                    descriptionField
                    
                    // Upload Progress
                    if isLoading {
                        progressSection
                    }
                }
                .padding()
            }
            .navigationTitle("Share to Community")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        Task {
                            await shareDesign()
                        }
                    }
                    .disabled(isShareDisabled)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Sign In Required", isPresented: $showSignInAlert) {
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Sign In") {
                    dismiss()
                    // The user will need to navigate to sign in from the profile tab
                }
            } message: {
                Text("You must be signed in to share designs to the community.")
            }
            .onAppear {
                // Check if user is signed in when view appears
                if currentUserId == nil {
                    showSignInAlert = true
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
            
            CanvasPreviewView(designFile: designFile)
                .frame(height: 200)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(title.count)/100")
                    .font(.caption)
                    .foregroundColor(title.count > 100 ? .red : .secondary)
            }
            
            TextField("My Awesome Design", text: $title)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: title) { _, newValue in
                    if newValue.count > 100 {
                        title = String(newValue.prefix(100))
                    }
                }
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(description.count)/500")
                    .font(.caption)
                    .foregroundColor(description.count > 500 ? .red : .secondary)
            }
            
            TextField("Describe your design...", text: $description, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: description) { _, newValue in
                    if newValue.count > 500 {
                        description = String(newValue.prefix(500))
                    }
                }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(uploadProgress)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
    
    private var isShareDisabled: Bool {
        isLoading ||
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func shareDesign() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                showSignInAlert = true
            }
            return
        }
        
        isLoading = true
        uploadProgress = "Processing images..."
        
        do {
            // Process components and upload images (with user folder)
            let processedComponents = try await imageUploadService.processDesignForSharing(canvasManager.components, userId: userId)
            
            await MainActor.run {
                uploadProgress = "Encoding design..."
            }
            
            // Encode design to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let designData = try encoder.encode(processedComponents)
            guard let designJSON = String(data: designData, encoding: .utf8) else {
                throw NSError(domain: "ShareDesign", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode design"])
            }
            
            await MainActor.run {
                uploadProgress = "Generating preview..."
            }
            
            // Generate preview thumbnail (with user folder)
            var previewURL = ""
            if let thumbnailData = designFile.thumbnail,
               let compressedThumbnail = imageUploadService.compressImage(thumbnailData, maxSizeKB: 200) {
                let url = try await imageUploadService.uploadImage(compressedThumbnail, filename: "preview", userId: userId)
                previewURL = url.absoluteString
            }
            
            await MainActor.run {
                uploadProgress = "Saving to community..."
            }
            
            // Insert into posts table
            struct CommunityPostInsert: Encodable {
                let title: String
                let description: String
                let author_id: UUID
                let status: String
                let preview_image_url: String
                let post_type: String
                let design_json: String
                let design_device_preset: String
                let design_color_scheme: String
            }
            
            let postData = CommunityPostInsert(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                author_id: userId,
                status: "approved",
                preview_image_url: previewURL,
                post_type: "community_design",
                design_json: designJSON,
                design_device_preset: selectedDevice.rawValue,
                design_color_scheme: colorScheme == .dark ? "dark" : "light"
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
                isLoading = false
                showError = true
                errorMessage = "Failed to share design: \(error.localizedDescription)"
            }
            print("❌ Error sharing design: \(error)")
        }
    }
}
