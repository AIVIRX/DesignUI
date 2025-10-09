//
//  ModerationView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/25/25.
//

import SwiftUI

struct ModerationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var submissions: [UserSubmission] = []
    @State private var isLoading = true
    @State private var selectedStatus: UserSubmission.SubmissionStatus? = nil
    @State private var selectedSubmission: UserSubmission?
    @State private var showDetailView = false
    
    private let adminUserId = "your-user-id-here" // Replace with your actual user ID
    
    var filteredSubmissions: [UserSubmission] {
        if let status = selectedStatus {
            return submissions.filter { $0.status == status }
        }
        return submissions
    }
    
    var body: some View {
        NavigationView {
            if !isAdminUser {
                // Not admin - show access denied
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Access Denied")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("You don't have permission to access the moderation panel.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                // Admin user - show moderation interface
                VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content Moderation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Review and moderate user-submitted designs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Status Filter
                HStack {
                    Text("Filter by status:")
                        .font(.headline)
                    
                    Picker("Status", selection: $selectedStatus) {
                        Text("All").tag(nil as UserSubmission.SubmissionStatus?)
                        ForEach(UserSubmission.SubmissionStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status as UserSubmission.SubmissionStatus?)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        loadSubmissions()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                // Submissions List
                if isLoading {
                    Spacer()
                    ProgressView("Loading submissions...")
                    Spacer()
                } else if filteredSubmissions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No submissions found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Submissions will appear here once users start submitting designs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List(filteredSubmissions) { submission in
                        SubmissionRowView(submission: submission) {
                            selectedSubmission = submission
                            showDetailView = true
                        }
                    }
                }
                }
            }
        }
        .sheet(isPresented: $showDetailView) {
            if let submission = selectedSubmission {
                SubmissionDetailView(submission: submission) {
                    loadSubmissions()
                }
            }
        }
        .onAppear {
            if isAdminUser {
                loadSubmissions()
            }
        }
    }
    
    private var isAdminUser: Bool {
        guard let user = authViewModel.currentUser else { return false }
        return user.id.uuidString == adminUserId
    }
    
    private func loadSubmissions() {
        isLoading = true
        // TODO: Load from Supabase
        // For now, simulate with sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            submissions = sampleSubmissions
            isLoading = false
        }
    }
}

struct SubmissionRowView: View {
    let submission: UserSubmission
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(Color(submission.status.color))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(submission.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("by \(submission.userName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(submission.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Text(submission.submittedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(submission.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(submission.status.color))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Sample data for testing
private let sampleSubmissions: [UserSubmission] = [
    UserSubmission(
        userId: "user1",
        userName: "John Designer",
        userEmail: "john@example.com",
        title: "Beautiful Login Screen",
        description: "A modern login screen with smooth animations",
        code: "struct LoginView: View { ... }",
        category: "Forms",
        tags: ["login", "animation", "modern"]
    ),
    UserSubmission(
        userId: "user2",
        userName: "Sarah Swift",
        userEmail: "sarah@example.com",
        title: "Custom Button Component",
        description: "Reusable button with multiple styles",
        code: "struct CustomButton: View { ... }",
        category: "UI Components",
        tags: ["button", "reusable", "component"]
    )
]
