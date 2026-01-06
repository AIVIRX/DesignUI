//
//  CommunityDesignsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/5/26.
//

import SwiftUI

// MARK: - Community Design Model
struct CommunityDesign: Identifiable, Decodable {
    let id: UUID
    let title: String
    let description: String
    let preview_image_url: String
    let design_json: String?
    let design_device_preset: String?
    let design_color_scheme: String?
    let author: Author?
    let created_at: String
    
    struct Author: Decodable {
        let username: String?
        let avatar_url: String?
    }
}

// MARK: - Community Designs Grid View
struct CommunityDesignsGridView: View {
    let onSelectDesign: (CommunityDesign) -> Void
    
    @State private var designs: [CommunityDesign] = []
    @State private var isLoading = true
    @State private var error: String?
    
    private let supabase = SupabaseManager.shared.client
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if designs.isEmpty {
                emptyView
            } else {
                designsScrollView
            }
        }
        .task {
            await fetchCommunityDesigns()
        }
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 40)
            Spacer()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("Failed to load")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Retry") {
                    Task { await fetchCommunityDesigns() }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }
    
    private var emptyView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "person.3")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("No community designs yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Be the first to share!")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }
    
    private var designsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(designs) { design in
                    CommunityDesignCardView(
                        design: design,
                        onSelect: { onSelectDesign(design) }
                    )
                    .frame(width: 220)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func fetchCommunityDesigns() async {
        isLoading = true
        error = nil
        
        do {
            let response: [CommunityDesign] = try await supabase
                .from("posts")
                .select("id, title, description, preview_image_url, design_json, design_device_preset, design_color_scheme, created_at, author:profiles!posts_author_id_fkey(username, avatar_url)")
                .eq("post_type", value: "community_design")
                .eq("status", value: "approved")
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            await MainActor.run {
                designs = response
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
            print("❌ Error fetching community designs: \(error)")
        }
    }
}

// MARK: - Community Design Card View
struct CommunityDesignCardView: View {
    let design: CommunityDesign
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview Image
            AsyncImage(url: URL(string: design.preview_image_url)) { phase in
                switch phase {
                case .empty:
                    Color.secondary.opacity(0.1)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.secondary.opacity(0.1)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    Color.secondary.opacity(0.1)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(design.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let author = design.author?.username {
                    Text("by \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button("Copy Design") {
                onSelect()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}
