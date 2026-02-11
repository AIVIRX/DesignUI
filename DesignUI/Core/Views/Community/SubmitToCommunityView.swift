//
//  SubmitToCommunityView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/28/25.
//

import SwiftUI

struct SubmitToCommunityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommunitySubmissionViewModel()
    
    let designFile: DesignFile
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var showAccountRequiredAlert = false
    
    init(designFile: DesignFile) {
        self.designFile = designFile
        _title = State(initialValue: designFile.name)
    }
    
    var body: some View {
        NavigationStack {
            submissionForm
            .navigationTitle("Submit to Community")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                #if os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submitAction()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(title.isEmpty || viewModel.isLoading)
                }
                #endif
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Account Required", isPresented: $showAccountRequiredAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You need an account to submit designs to the community.")
            }
            .onChange(of: viewModel.submissionSuccess) { _, success in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Submission Form
    
    private var submissionForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview
                designPreview
                
                // Title Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("My Amazing Design", text: $title)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(fieldBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Description Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Optional")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $description)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 100)
                        .background(fieldBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Info Banner
                infoBanner
                
                // Submit Button
                #if os(iOS)
                submitButton
                #endif
            }
            .padding()
        }
    }
    
    private var designPreview: some View {
        VStack(spacing: 12) {
            if let thumbnailData = designFile.thumbnail,
               let image = createImage(from: thumbnailData) {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                #endif
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Preview will be generated")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            Text("Preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            Text("Your submission will be reviewed before appearing in the community.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func submitAction() {
        guard SupabaseManager.shared.client.auth.currentUser != nil else {
            showAccountRequiredAlert = true
            return
        }
        Task {
            await viewModel.submitDesign(
                designFile: designFile,
                title: title.isEmpty ? designFile.name : title,
                description: description
            )
        }
    }
    
    #if os(iOS)
    private var submitButton: some View {
        Button {
            submitAction()
        } label: {
            Group {
                if viewModel.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text(viewModel.uploadProgress)
                    }
                } else if viewModel.submissionSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submitted!")
                    }
                } else {
                    Text("Submit to Community")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.submissionSuccess ? Color.green : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(title.isEmpty || viewModel.isLoading)
    }
    #endif
    
    private var fieldBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    #if os(iOS)
    private func createImage(from data: Data) -> UIImage? {
        UIImage(data: data)
    }
    #else
    private func createImage(from data: Data) -> NSImage? {
        NSImage(data: data)
    }
    #endif
}
