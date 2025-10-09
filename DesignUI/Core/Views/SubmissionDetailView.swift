//
//  SubmissionDetailView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/25/25.
//

import SwiftUI

struct SubmissionDetailView: View {
    let submission: UserSubmission
    let onModerationComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var moderationNotes = ""
    @State private var selectedAction: ModerationAction = .approve
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum ModerationAction: String, CaseIterable {
        case approve = "approve"
        case reject = "reject"
        
        var displayName: String {
            switch self {
            case .approve: return "Approve"
            case .reject: return "Reject"
            }
        }
        
        var color: Color {
            switch self {
            case .approve: return .green
            case .reject: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .approve: return "checkmark.circle.fill"
            case .reject: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(submission.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("by \(submission.userName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(submission.status.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(submission.status.color))
                                
                                Text(submission.submittedAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Category and Tags
                        HStack {
                            Text(submission.category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                            
                            if !submission.tags.isEmpty {
                                ForEach(submission.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(submission.description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Code Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SwiftUI Code")
                            .font(.headline)
                        
                        ScrollView {
                            Text(submission.code)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    // Moderation Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Moderation")
                            .font(.headline)
                        
                        // Action Selection
                        HStack(spacing: 16) {
                            ForEach(ModerationAction.allCases, id: \.self) { action in
                                Button(action: {
                                    selectedAction = action
                                }) {
                                    HStack {
                                        Image(systemName: action.icon)
                                        Text(action.displayName)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedAction == action ? action.color : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedAction == action ? .white : .primary)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Moderation Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Add any notes about your decision...", text: $moderationNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Action Buttons
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button(action: processModeration) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: selectedAction.icon)
                                }
                                Text(isProcessing ? "Processing..." : selectedAction.displayName)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedAction.color)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isProcessing)
                        .frame(maxWidth: 200)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Review Submission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Moderation Complete", isPresented: $showAlert) {
            Button("OK") {
                dismiss()
                onModerationComplete()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func processModeration() {
        isProcessing = true
        
        // TODO: Update submission in Supabase
        Task {
            do {
                try await updateSubmissionStatus()
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Submission has been \(selectedAction.displayName.lowercased()) successfully."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Failed to process moderation: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func updateSubmissionStatus() async throws {
        // TODO: Implement Supabase update
        // For now, just simulate a delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
