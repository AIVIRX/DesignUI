//
//  ExploreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var searchText = ""
    
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
                    // Posts Grid
                    if !viewModel.posts.isEmpty {
                        if filteredPosts.isEmpty && !searchText.isEmpty {
                            Text("No posts found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
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
                .searchable(text: $searchText)
            }
            .navigationTitle("Explore")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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

struct GridLoadingView: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<2) { _ in
                RoundedRectangle(cornerRadius: 12)
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
    
