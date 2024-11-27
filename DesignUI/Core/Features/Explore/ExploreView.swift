//
//  ExploreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI
import Combine
import Firebase
import SDWebImage
import SDWebImageSwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var searchText = ""
    @State private var selectedTag: String? = "All"
    
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var filteredPosts: [DesignPost] {
        if searchText.isEmpty {
            return viewModel.posts
        }
        return viewModel.posts.filter { post in
            let searchQuery = searchText.lowercased()
            return post.title.lowercased().contains(searchQuery) ||
                   post.description.lowercased().contains(searchQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    SearchBarView(searchText: $searchText)
                        .padding(.top, 8)
                    
                    // Posts Grid
                    if !viewModel.posts.isEmpty {
                        if filteredPosts.isEmpty && !searchText.isEmpty {
                            Text("No matching posts found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    DesignCards(
                                        id: post.id,
                                        media: post.preview_image_url,
                                        title: post.title,
                                        authorName: post.profiles.username,
                                        isVerified: post.profiles.verified,
                                        description: post.description,
                                        codeSnippet: post.code_snippet,
                                        published: post.created_at
                                    )
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMorePostsIfNeeded(currentItem: post)
                                        }
                                    }
                                }
                                
                                if viewModel.isLoading {
                                    GridLoadingView()
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else if viewModel.isLoading {
                        ProgressView("Loading posts...")
                            .padding()
                    } else {
                        Text("No posts found")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Explore")
            .frame(maxWidth: 1600)
            .refreshable {
                Task {
                    await viewModel.refreshPosts()
                }
            }
            .task {
                if viewModel.posts.isEmpty {
                    await viewModel.fetchPosts()
                }
            }
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
}

// Helper Views
struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(isSelected ? .blue : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct GridLoadingView: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<2) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 400)
                    .overlay(
                        ProgressView()
                            .tint(.gray)
                    )
            }
        }
    }
}

#Preview {
    ExploreView()
}
    
