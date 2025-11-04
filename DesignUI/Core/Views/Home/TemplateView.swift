//
//  ExploreView.swift
//  DockUI
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
    
    @State private var adInterval: Int = 7 // Optimized interval: ads every 7 posts (good balance for revenue & UX)
    @State private var adIdentifiers: [Int: String] = [:] // Cache ad identifiers by position to prevent shifting
    
    // Combine posts with ads, inserting ads every 7 posts
    var feedItems: [FeedItem] {
        let posts = filteredPosts
        var items: [FeedItem] = []
        
        // Don't show ads on macOS (AdMob SDK not supported) or if user is subscribed
        #if os(iOS)
        let shouldShowAds = !subscriptionManager.isSubscribed
        #else
        let shouldShowAds = false // No ads on macOS
        #endif
        
        // Use the current adInterval
        let currentInterval = adInterval
        
        for (index, post) in posts.enumerated() {
            items.append(.post(post))
            
            // Only insert ads if we should show them (iOS and not subscribed)
            if shouldShowAds {
                // Insert ad after every adInterval posts, but not at the very end
                // Make sure we have at least one more post after the ad
                if (index + 1) % currentInterval == 0 && index < posts.count - 1 {
                    // Use stable identifier based on post position to prevent ad shifting
                    let adPosition = index + 1
                    // Don't modify state here - use existing identifier or generate in onAppear/onChange
                    if let identifier = adIdentifiers[adPosition] {
                        items.append(.ad(identifier))
                    }
                }
            }
        }
        
        return items
    }
    
    // Generate ad identifiers when posts change to avoid modifying state during view update
    private func generateAdIdentifiers(for posts: [DesignPost]) {
        // Only generate ad identifiers if we should show ads (iOS and not subscribed)
        #if os(iOS)
        guard !posts.isEmpty && !subscriptionManager.isSubscribed else {
            adIdentifiers = [:] // Clear identifiers if we shouldn't show ads
            return
        }
        
        var newIdentifiers: [Int: String] = [:]
        let currentInterval = adInterval
        
        for (index, _) in posts.enumerated() {
            if (index + 1) % currentInterval == 0 && index < posts.count - 1 {
                let adPosition = index + 1
                // Reuse existing identifier if available, otherwise generate new one
                if let existing = adIdentifiers[adPosition] {
                    newIdentifiers[adPosition] = existing
                } else {
                    newIdentifiers[adPosition] = UUID().uuidString
                }
            }
        }
        
        adIdentifiers = newIdentifiers
        #else
        // No ads on macOS
        adIdentifiers = [:]
        #endif
    }
    
    // Generate identifiers only for newly added posts during pagination
    private func generateAdIdentifiersForNewPosts(oldCount: Int, newPosts: [DesignPost]) {
        // Only generate ad identifiers if we should show ads (iOS and not subscribed)
        #if os(iOS)
        guard oldCount < newPosts.count && !subscriptionManager.isSubscribed else { return }
        
        let currentInterval = adInterval
        var updatedIdentifiers = adIdentifiers
        
        // Only generate identifiers for positions that are now in range
        for index in oldCount..<newPosts.count {
            if (index + 1) % currentInterval == 0 && index < newPosts.count - 1 {
                let adPosition = index + 1
                // Only add if we don't already have an identifier for this position
                if updatedIdentifiers[adPosition] == nil {
                    updatedIdentifiers[adPosition] = UUID().uuidString
                }
            }
        }
        
        adIdentifiers = updatedIdentifiers
        #else
        // No ads on macOS - do nothing
        #endif
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
            .onChange(of: viewModel.posts) { oldPosts, newPosts in
                // Only regenerate identifiers if posts actually changed (different count or different posts)
                // Don't regenerate during pagination if we're just appending more posts
                let oldCount = oldPosts.count
                let newCount = newPosts.count
                
                // If we have fewer posts (refresh/filter change), regenerate
                // If we have more posts (pagination), only regenerate if identifiers are empty
                if newCount < oldCount || (newCount > oldCount && adIdentifiers.isEmpty) || (oldCount == 0 && newCount > 0) {
                    generateAdIdentifiers(for: newPosts)
                } else if newCount > oldCount {
                    // Pagination: generate identifiers for new positions only
                    generateAdIdentifiersForNewPosts(oldCount: oldCount, newPosts: newPosts)
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
            .onChange(of: subscriptionManager.isSubscribed) { oldValue, newValue in
                // Update ad identifiers when subscription status changes
                // If user subscribed, clear ad identifiers
                // If user unsubscribed, regenerate ad identifiers
                if newValue {
                    // User subscribed - clear ads
                    adIdentifiers = [:]
                } else {
                    // User unsubscribed - regenerate ad identifiers if on iOS
                    #if os(iOS)
                    generateAdIdentifiers(for: viewModel.posts)
                    #endif
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
            .padding(.horizontal)
        }
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
                Group {
                    if selectedFilter == filterType {
                        Color.primary
                    } else {
                        #if os(iOS)
                        Color(uiColor: .systemGray5)
                        #else
                        Color(NSColor.controlBackgroundColor)
                        #endif
                    }
                }
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
        } else if viewModel.isLoading || viewModel.isRefreshing {
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
                    items: feedItems,
                    columns: 2,
                    spacing: 8,
                    hasMorePosts: viewModel.hasMorePosts,
                    isLoading: viewModel.isLoading,
                    loadMoreHandler: { item in
                        guard let feedItem = item else { return }
                        
                        // Only trigger loading for posts, not ads
                        if case .post(let post) = feedItem {
                            Task {
                                await viewModel.loadMorePostsIfNeeded(currentItem: post)
                            }
                        }
                        // Ad items don't trigger loading - just return
                    }
                ) { item in
                    feedItemCell(for: item)
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
        if #available(macOS 13.0, *) {
            LazyMasonryView(
                items: feedItems,
                columns: 5,
                spacing: 16,
                hasMorePosts: viewModel.hasMorePosts,
                isLoading: viewModel.isLoading,
                loadMoreHandler: { item in
                    guard let feedItem = item else { return }
                    
                    // Only trigger loading for posts, not ads
                    if case .post(let post) = feedItem {
                        Task {
                            await viewModel.loadMorePostsIfNeeded(currentItem: post)
                        }
                    }
                    // Ad items don't trigger loading - just return
                }
            ) { item in
                feedItemCell(for: item)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        } else {
            gridView(spacing: 16, horizontalPadding: 16, verticalPadding: 16)
        }
#endif
    }
    
    private var gridColumns: [GridItem] {
#if os(macOS)
        // More columns for macOS - allows 5+ columns based on screen width
        // Minimum width of 160px per column means ~5 columns on typical macOS screens
        [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ]
#else
        // iOS: 2 columns for iPad
        [
            GridItem(.adaptive(minimum: 200), spacing: 16)
        ]
#endif
    }
    
    private func gridView(spacing: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat) -> some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(feedItems) { item in
                feedItemCell(for: item)
                    .task {
                        if case .post(let post) = item {
                            await viewModel.loadMorePostsIfNeeded(currentItem: post)
                        }
                    }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }
    
    @ViewBuilder
    private func feedItemCell(for item: FeedItem) -> some View {
        switch item {
        case .post(let post):
            postCell(for: post)
        case .ad(let identifier):
            // Only show ads on iOS - never on macOS
            #if os(iOS)
            NativeAdView(adIdentifier: identifier)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true) // Prevent layout shifts by maintaining size
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.vertical, 4)
            #else
            // Empty view on macOS - ads should never appear here due to feedItems filtering,
            // but this is an extra safety check
            EmptyView()
            #endif
        }
    }
    @ViewBuilder
    private func postCell(for post: DesignPost) -> some View {
        // DesignCards already contains NavigationLink, so we don't wrap it again
        // This prevents nested NavigationLinks which cause rendering issues on macOS
        if (post.isPremium == true) && !subscriptionManager.isSubscribed {
            // For premium posts, we need to intercept the NavigationLink
            // Replace the DesignCards NavigationLink with a Button that shows paywall
            Button { paywallManager.present() } label: {
                designCardContent(for: post, isPremium: true)
            }
        } else {
            designCard(for: post, isPremium: post.isPremium == true)
        }
    }
    
    @ViewBuilder
    private func designCardContent(for post: DesignPost, isPremium: Bool) -> some View {
        // Determine if it's a component based on post_type
        let postType = post.post_type?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isComponent = postType == "component"
        
        // Return just the card content without NavigationLink wrapper
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

