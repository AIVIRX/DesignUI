//
//  ExploreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI
import StoreKit

struct ExploreView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var searchText = ""
    @EnvironmentObject private var store: Store
    
    var filteredPosts: [DesignPost] {
        guard !searchText.isEmpty else { return viewModel.posts }
        
        let searchQuery = searchText.lowercased()
        
        return viewModel.posts.filter { post in
            let titleMatch = post.title.lowercased().contains(searchQuery)
            let descriptionMatch = post.description.lowercased().contains(searchQuery)
            return titleMatch || descriptionMatch
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
                                        published: post.created_at,
                                        likesCount: post.likes_count,
                                        isLiked: false
                                    )
                                    .task {
                                        await viewModel.loadMorePostsIfNeeded(currentItem: post)
                                    }
                                }
                            }
                            .padding()
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
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                        if newValue == searchText { // Prevent outdated calls
                            await viewModel.searchPosts(query: newValue)
                        }
                    }
                }
            }
            .navigationTitle("Templates")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.shared.triggerImpact(style: .medium)
                    })
                }
            }
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
