//
//  ExploreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var searchText = ""
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
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
                VStack(spacing: 12) {
#if os(iOS)
                    // Custom Search Bar
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search templates", text: $searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 8 : 16)
                        .padding(.top, UIDevice.current.userInterfaceIdiom == .phone ? 8 : 16)
                    }
#endif
                    // Posts Grid
                    if !viewModel.posts.isEmpty {
                        if filteredPosts.isEmpty && !searchText.isEmpty {
                            Text("No posts found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
#if os(iOS)
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                // Pinterest-style masonry layout - fills columns vertically with lazy loading
                                if #available(iOS 16.0, *) {
                                    LazyMasonryView(
                                        items: filteredPosts,
                                        columns: 2,
                                        spacing: 8,
                                        hasMorePosts: viewModel.hasMorePosts,
                                        isLoading: viewModel.isLoading,
                                        loadMoreHandler: { item in
                                            Task {
                                                await viewModel.loadMorePostsIfNeeded(currentItem: item)
                                            }
                                        }
                                    ) { post in
                                        postCell(for: post)
                                            .buttonStyle(PlainButtonStyle())
                                            .task {
                                                await viewModel.loadMorePostsIfNeeded(currentItem: post)
                                            }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                } else {
                                    LazyVGrid(columns: gridColumns, spacing: 8) {
                                        ForEach(filteredPosts) { post in
                                            postCell(for: post)
                                                .buttonStyle(PlainButtonStyle())
                                                .task {
                                                    await viewModel.loadMorePostsIfNeeded(currentItem: post)
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                }
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(filteredPosts) { post in
                                        postCell(for: post)
                                            .buttonStyle(PlainButtonStyle())
                                            .task {
                                                await viewModel.loadMorePostsIfNeeded(currentItem: post)
                                            }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
#else
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    postCell(for: post)
                                        .buttonStyle(PlainButtonStyle())
                                        .task {
                                            await viewModel.loadMorePostsIfNeeded(currentItem: post)
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
#endif
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
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                        if newValue == searchText { // Prevent outdated calls
                            await viewModel.searchPosts(query: newValue)
                        }
                    }
                }
            }
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
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
#else
        .searchable(text: $searchText, prompt: "Search templates")
#endif
        .navigationViewStyle(DefaultNavigationViewStyle())
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
    }
}

// MARK: - Helpers
extension ExploreView {
    @ViewBuilder
    private func postCell(for post: DesignPost) -> some View {
        if (post.isPremium == true) && !subscriptionManager.isSubscribed {
            Button { paywallManager.present() } label: {
                designCard(for: post, isPremium: true)
            }
        } else {
            NavigationLink(destination: DetailView(
                id: post.id,
                mediaURL: post.preview_image_url,
                title: post.title,
                description: post.description,
                author: post.profiles.username,
                codeSnippet: post.code_snippet,
                creationDate: post.created_at,
                isAuthorVerified: post.profiles.verified,
                isPremium: post.isPremium == true
            )) {
                designCard(for: post, isPremium: post.isPremium == true)
            }
        }
    }
    
    @ViewBuilder
    private func designCard(for post: DesignPost, isPremium: Bool) -> some View {
        // Determine if it's a component based on post_type
        // Support both "component" (singular) and "components" (plural)
        let postType = post.post_type?.lowercased() ?? ""
        let isComponent = postType == "component" || postType == "components"
        
        DesignCards(
            id: post.id,
            media: post.preview_image_url,
            title: post.title,
            authorName: post.profiles.username,
            isVerified: post.profiles.verified,
            description: post.description,
            codeSnippet: post.code_snippet,
            published: post.created_at,
            isLiked: false,
            isPremium: isPremium,
            isComponent: isComponent
        )
    }
}
