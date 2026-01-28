//
//  MySubmissionsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/28/25.
//

import SwiftUI

struct MySubmissionsView: View {
    @StateObject private var viewModel = CommunitySubmissionViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.mySubmissions.isEmpty {
                ProgressView("Loading submissions...")
            } else if viewModel.mySubmissions.isEmpty {
                emptyState
            } else {
                submissionsList
            }
        }
        .navigationTitle("My Submissions")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.fetchMySubmissions()
        }
        .refreshable {
            await viewModel.fetchMySubmissions()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Submissions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Submit your designs to the community to see them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private var submissionsList: some View {
        List(viewModel.mySubmissions) { submission in
            SubmissionRow(submission: submission)
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
}

// MARK: - Submission Row

struct SubmissionRow: View {
    let submission: CommunitySubmission
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let urlString = submission.preview_image_url,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderImage
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.title)
                    .font(.headline)
                    .lineLimit(1)
                
                statusBadge
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            )
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch submission.status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
    
    private var statusText: String {
        switch submission.status {
        case .pending:
            return "Pending Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
}
