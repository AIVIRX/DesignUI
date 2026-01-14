//
//  ExploreView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @Binding var selectedTab: ContentView.Tabs
    
    @State private var adInterval: Int = 20 // Ads every 20 posts
    @State private var adIdentifiers: [Int: String] = [:] // Cache ad identifiers by position to prevent shifting
    @State private var showSettings = false
    
    // Combine posts with ads, inserting ads every 7 posts
    var feedItems: [FeedItem] {
        let posts = viewModel.posts
        var items: [FeedItem] = []
        
        // Don't show ads on macOS (AdMob SDK not supported), iPad, or if user is subscribed
#if os(iOS)
        let shouldShowAds = !subscriptionManager.isSubscribed && UIDevice.current.userInterfaceIdiom == .phone
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
        // Only generate ad identifiers if we should show ads (iPhone only, not subscribed)
#if os(iOS)
        guard !posts.isEmpty && !subscriptionManager.isSubscribed && UIDevice.current.userInterfaceIdiom == .phone else {
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
        // Only generate ad identifiers if we should show ads (iPhone only, not subscribed)
#if os(iOS)
        guard oldCount < newPosts.count && !subscriptionManager.isSubscribed && UIDevice.current.userInterfaceIdiom == .phone else { return }
        
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
#endif
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.posts.isEmpty && (viewModel.isLoading || viewModel.isRefreshing) {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            heroView
                            postsGridView
                                .frame(maxWidth: 1600)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .ignoresSafeArea(edges: .top)
                    #if os(macOS)
                    .modifier(ScrollEdgeEffectHiddenModifier())
                    #endif
                    .refreshable {
                        await viewModel.fetchPosts()
                    }
                    .toolbar {
                        ToolbarItem {
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                            }
                        }
                    }
                    .sheet(isPresented: $showSettings) {
                        NavigationStack {
                            SettingsView()
                        }
                        #if os(macOS)
                        .frame(minWidth: 500, minHeight: 400)
                        #endif
                    }


                }
            }
            #if os(macOS)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .modifier(FullScreenToolbarModifier())
//            .transparentToolbar()
            #endif
            .task {
                if viewModel.posts.isEmpty {
                    await viewModel.fetchPostsByType(postType: nil, isAllPosts: true)
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
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
    }
}

// MARK: - Helpers
extension ExploreView {
    private var heroView: some View {
        LargeHero(
            name: "Introducing Studio",
            description: "Transform concepts into polished designs with DockUI Studio. No coding required.",
            height: 400,
            buttonTitle: "Get Started",
            cornerRadius: 0
        ) {
            selectedTab = .studio
        }
    }
    
    @ViewBuilder
    private var postsContentView: some View {
        if !viewModel.posts.isEmpty {
            postsGridView
                .frame(maxWidth: 1600)
        } else {
            // Empty state (not loading - that's handled in body)
            Text("No posts found")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
    }
    
    @ViewBuilder
    private var postsGridView: some View {
        AdaptiveMasonryGrid(
            items: feedItems,
            spacing: 12,
            hasMorePosts: viewModel.hasMorePosts,
            isLoading: viewModel.isLoading,
            loadMoreHandler: { item in
                guard let feedItem = item else { return }
                if case .post(let post) = feedItem {
                    Task {
                        await viewModel.loadMorePostsIfNeeded(currentItem: post)
                    }
                }
            }
        ) { item in
            feedItemCell(for: item)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
    
    private func calculateColumns(for width: CGFloat) -> Int {
        #if os(iOS)
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        if isPhone {
            return 2
        } else {
            // iPad: adaptive based on width
            if width < 700 {
                return 3
            } else if width < 1000 {
                return 4
            } else {
                return 5
            }
        }
        #else
        // macOS: adaptive based on width
        if width < 600 {
            return 2
        } else if width < 900 {
            return 3
        } else if width < 1200 {
            return 4
        } else {
            return 5
        }
        #endif
    }
    
    private var gridColumns: [GridItem] {
#if os(macOS)
        [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ]
#else
        if UIDevice.current.userInterfaceIdiom == .phone {
            [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
        } else {
            [
                GridItem(.adaptive(minimum: 160), spacing: 16)
            ]
        }
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
        // DesignCards contains NavigationLink - DetailView will handle premium paywall
        designCard(for: post, isPremium: post.isPremium == true)
    }
    
    @ViewBuilder
    private func designCard(for post: DesignPost, isPremium: Bool) -> some View {
        DesignCards(post: post)
    }
}

#if os(iOS)

// Preference key to read container width
struct ContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Helper view for adaptive column layout on iPad
@available(iOS 16.0, *)
struct AdaptiveColumnMasonryView<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let minColumnWidth: CGFloat
    let maxColumns: Int
    let spacing: CGFloat
    let hasMorePosts: Bool
    let isLoading: Bool
    let loadMoreHandler: ((Item?) -> Void)?
    let content: (Item) -> Content
    
    @State private var containerWidth: CGFloat = 0
    
    var calculatedColumns: Int {
        guard containerWidth > 0 else { return 5 } // Default to 5 columns
        let calculated = max(2, Int(containerWidth / (minColumnWidth + spacing)))
        return min(calculated, maxColumns)
    }
    
    var body: some View {
        LazyMasonryView(
            items: items,
            columns: calculatedColumns,
            spacing: spacing,
            hasMorePosts: hasMorePosts,
            isLoading: isLoading,
            loadMoreHandler: loadMoreHandler
        ) { item in
            content(item)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ContainerWidthKey.self, value: geometry.size.width)
            }
        )
        .onPreferenceChange(ContainerWidthKey.self) { width in
            containerWidth = width
        }
    }
}
#endif

