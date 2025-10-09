//
//  UploadSubmissionView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/25/25.
//

import SwiftUI

struct UploadSubmissionView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var code = ""
    @State private var selectedCategory = "UI Components"
    @State private var tags = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSignInAlert = false
    
    private let categories = [
        "UI Components",
        "Layouts",
        "Animations",
        "Forms",
        "Navigation",
        "Cards",
        "Buttons",
        "Lists",
        "Modals",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            if authViewModel.currentUser == nil {
                // Not authenticated - show sign in prompt
                VStack(spacing: 20) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Sign In Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("You need to be signed in to submit designs to the community.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Sign In") {
                        showSignInAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                // Authenticated - show upload form
                ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share Your Design")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Submit your SwiftUI code and help the community learn from your designs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Form Fields
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                            TextField("Give your design a catchy title", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            TextField("Describe your design and what makes it special", text: $description, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (optional)")
                                .font(.headline)
                            TextField("swiftui, button, animation, etc.", text: $tags)
                                .textFieldStyle(.roundedBorder)
                            Text("Separate tags with commas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Code
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SwiftUI Code")
                                .font(.headline)
                            Text("Paste your SwiftUI code here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $code)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Submit Button
                    Button(action: submitDesign) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Design")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.top, 20)
                    
                    // Guidelines
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Submission Guidelines")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Make sure your code is clean and well-commented")
                            Text("• Include proper SwiftUI syntax and best practices")
                            Text("• Your submission will be reviewed before being published")
                            Text("• Be respectful and follow community guidelines")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
                }
                .navigationTitle("Submit Design")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                clearForm()
            }
        } message: {
            Text("Your design has been submitted for review. We'll notify you once it's been moderated.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Sign In Required", isPresented: $showSignInAlert) {
            Button("OK") { }
        } message: {
            Text("Please sign in to submit designs to the community.")
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !code.isEmpty
    }
    
    private func submitDesign() {
        guard let user = authViewModel.currentUser else {
            errorMessage = "You must be logged in to submit designs."
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        
        let tagArray = tags.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let submission = UserSubmission(
            userId: user.id.uuidString,
            userName: user.userMetadata["full_name"] as? String ?? "Anonymous",
            userEmail: user.email ?? "",
            title: title,
            description: description,
            code: code,
            category: selectedCategory,
            tags: tagArray
        )
        
        // TODO: Submit to Supabase
        Task {
            do {
                try await submitToSupabase(submission)
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit design: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func submitToSupabase(_ submission: UserSubmission) async throws {
        // TODO: Implement Supabase submission
        // For now, just simulate a delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func clearForm() {
        title = ""
        description = ""
        code = ""
        tags = ""
        selectedCategory = "UI Components"
    }
}
