//
//  ExploreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI

enum FilterType: String, CaseIterable {
    case all = "All"
    case templates = "Templates"
    case components = "Components"
    
    var icon: String? {
        switch self {
        case .all:
            return nil
        case .templates:
            return "rectangle.stack"
        case .components:
            return "cube"
        }
    }
}

struct ExploreView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    var filteredPosts: [DesignPost] {
        // Filter by search text only (type filtering is done at database level)
        guard !searchText.isEmpty else { return viewModel.posts }
        
        let searchQuery = searchText.lowercased()
        
        return viewModel.posts.filter { post in
            let titleMatch = post.title.lowercased().contains(searchQuery)
            let descriptionMatch = post.description.lowercased().contains(searchQuery)
            return titleMatch || descriptionMatch
        }
    }
    
    private func getFilterTypeForDatabase() -> (postType: String?, isAllPosts: Bool) {
        switch selectedFilter {
        case .all:
            return (nil, true) // Fetch all posts - no filter
        case .templates:
            return (nil, false) // Fetch templates (exclude components)
        case .components:
            return ("component", false) // Fetch only components
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    searchBarView
                    tagButtonsView
                    postsContentView
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
                    let filter = getFilterTypeForDatabase()
                    await viewModel.refreshPosts(filterType: filter.postType, isAllPosts: filter.isAllPosts)
                }
            }
            .task {
                if viewModel.posts.isEmpty {
                    let filter = getFilterTypeForDatabase()
                    await viewModel.fetchPostsByType(postType: filter.postType, isAllPosts: filter.isAllPosts)
                }
            }
            .onChange(of: selectedFilter) { oldValue, newValue in
                // Debounce filter changes to prevent rapid database queries
                // Only process if filter actually changed
                guard oldValue != newValue else { return }
                
                Task {
                    let filter = getFilterTypeForDatabase()
                    await viewModel.fetchPostsByTypeDebounced(postType: filter.postType, isAllPosts: filter.isAllPosts)
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
    private var searchBarView: some View {
#if os(iOS)
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
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
#endif
    }
    
    private var tagButtonsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterType.allCases, id: \.self) { filterType in
                    filterButton(for: filterType)
                }
            }
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
        }
        .padding(.vertical, 8)
    }
    
    private func filterButton(for filterType: FilterType) -> some View {
        Button {
            selectedFilter = filterType
        } label: {
            HStack(spacing: 6) {
                if let icon = filterType.icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(filterType.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                selectedFilter == filterType
                    ? Color.primary
                    : Color(.systemGray5)
            )
            .foregroundColor(
                selectedFilter == filterType
                    ? (colorScheme == .dark ? Color.black : Color.white)
                    : Color.primary
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var postsContentView: some View {
        if !viewModel.posts.isEmpty {
            if filteredPosts.isEmpty {
                Text("No posts found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                postsGridView
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
    
    @ViewBuilder
    private var postsGridView: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
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
                gridView(spacing: 8, horizontalPadding: 8, verticalPadding: 8)
            }
        } else {
            gridView(spacing: 16, horizontalPadding: 16, verticalPadding: 16)
        }
#else
        gridView(spacing: 16, horizontalPadding: 16, verticalPadding: 16)
#endif
    }
    
    private func gridView(spacing: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat) -> some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(filteredPosts) { post in
                postCell(for: post)
                    .buttonStyle(PlainButtonStyle())
                    .task {
                        await viewModel.loadMorePostsIfNeeded(currentItem: post)
                    }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }
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
        let postType = post.post_type?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isComponent = postType == "component"
        
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

