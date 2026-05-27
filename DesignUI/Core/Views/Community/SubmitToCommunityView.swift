//
//  SubmitToCommunityView.swift
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
            navigationContent
        }
    }

    private var navigationContent: some View {
        submissionForm
            .navigationTitle("Share to Community")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .modifier(
                SubmissionAlertModifier(
                    showError: $viewModel.showError,
                    errorMessage: viewModel.errorMessage,
                    showAccountRequiredAlert: $showAccountRequiredAlert
                )
            )
            .onChange(of: viewModel.submissionSuccess) { _, success in
                handleSubmissionSuccess(success)
            }
    }
    
    private var submissionForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                designPreview
                titleSection
                descriptionSection
#if os(iOS)
                submitButton
#endif
                reviewNote
            }
            .padding()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }

#if os(macOS)
        ToolbarItem(placement: .confirmationAction) {
            Button(action: submitAction) {
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

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.subheadline)
                .fontWeight(.medium)
            TextField("My Amazing Design", text: $title)
                .textFieldStyle(.plain)
                .padding()
                .background(fieldBackground)
                .cornerRadius(12)
                .overlay(fieldBorder)
        }
    }

    private var descriptionSection: some View {
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
                .overlay(fieldBorder)
        }
    }

    private var reviewNote: some View {
        Text("Your submission will be reviewed before appearing in the community.")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    
    private var designPreview: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 240)
                .overlay {
                    previewContent
                }
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            
            Text("Preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        if let thumbnailData = designFile.thumbnail,
           let image = createImage(from: thumbnailData) {
            #if os(iOS)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .padding()
            #else
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .padding()
            #endif
        } else {
            VStack {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Preview will be generated")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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

    private func handleSubmissionSuccess(_ success: Bool) {
        guard success else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
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
                    Text("Share to Community")
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

private struct SubmissionAlertModifier: ViewModifier {
    @Binding var showError: Bool
    let errorMessage: String
    @Binding var showAccountRequiredAlert: Bool

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })
            .alert("Account Required", isPresented: $showAccountRequiredAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text("You need to be signed in to submit designs to the community.")
            })
    }
}
