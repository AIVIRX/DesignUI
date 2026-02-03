//
//  LikedPostsView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

struct LikedPostsView: View {
    @StateObject private var viewModelLiked = LikedPostsViewModel()
    @EnvironmentObject private var designManager: DesignManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.openWindow) private var openWindow
    @State private var showingLimitAlert = false
    @State private var showingPaywall = false
    private let freeDesignLimit = 3
    
    var body: some View {
        ScrollView {
            if viewModelLiked.isLoading && viewModelLiked.likedPosts.isEmpty {
                ProgressView()
                    .padding()
            } else if viewModelLiked.likedPosts.isEmpty {
                VStack {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding()
                    Text("No liked posts yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 5)
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                postsGridView
            }
        }
        .task {
            await viewModelLiked.fetchLikedPosts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .likesChanged)) { notification in
            guard
                let info = notification.userInfo,
                let postId = info["postId"] as? String,
                let isLiked = info["isLiked"] as? Bool
            else { return }

            if !isLiked {
                // Remove unliked post from the grid immediately
                if let index = viewModelLiked.likedPosts.firstIndex(where: { $0.id == postId }) {
                    viewModelLiked.likedPosts.remove(at: index)
                }
            } else {
                // Post was liked - fetch and add it to the list
                Task {
                    await viewModelLiked.addLikedPost(postId: postId)
                }
            }
        }
        .refreshable {
            await viewModelLiked.refreshPosts()
        }
        .sheet(isPresented: $showingPaywall) {
            CustomPaywallView()
                .environmentObject(PaywallManager.shared)
                .environmentObject(subscriptionManager)
        }
        .alert("Free Limit Reached", isPresented: $showingLimitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Subscribe") {
                showingPaywall = true
            }
        } message: {
            Text("Free users are limited to \(freeDesignLimit) designs. Subscribe to create unlimited designs.")
        }
    }
    
    @ViewBuilder
    private var postsGridView: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                LazyMasonryView(
                    items: viewModelLiked.likedPosts,
                    columns: 2,
                    spacing: 8,
                    hasMorePosts: viewModelLiked.hasMorePosts,
                    isLoading: viewModelLiked.isLoading,
                    loadMoreHandler: { post in
                        guard let post = post else { return }
                        Task {
                            await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                        }
                    }
                ) { post in
                    likedPostCell(for: post)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            } else {
                gridView(spacing: 8, horizontalPadding: 8)
            }
        } else {
            // iPad: Use LazyMasonryView with 5 columns like Mac
            if #available(iOS 16.0, *) {
                LazyMasonryView(
                    items: viewModelLiked.likedPosts,
                    columns: 5,
                    spacing: 16,
                    hasMorePosts: viewModelLiked.hasMorePosts,
                    isLoading: viewModelLiked.isLoading,
                    loadMoreHandler: { post in
                        guard let post = post else { return }
                        Task {
                            await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                        }
                    }
                ) { post in
                    likedPostCell(for: post)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            } else {
                gridView(spacing: 16, horizontalPadding: 16)
            }
        }
#else
        if #available(macOS 13.0, *) {
            LazyMasonryView(
                items: viewModelLiked.likedPosts,
                columns: 5,
                spacing: 16,
                hasMorePosts: viewModelLiked.hasMorePosts,
                isLoading: viewModelLiked.isLoading,
                loadMoreHandler: { post in
                    guard let post = post else { return }
                    Task {
                        await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                    }
                }
            ) { post in
                likedPostCell(for: post)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        } else {
            gridView(spacing: 16, horizontalPadding: 16)
        }
#endif
    }
    
    private func gridView(spacing: CGFloat, horizontalPadding: CGFloat) -> some View {
        LazyVGrid(columns: GridConfiguration.shared.columns, spacing: spacing) {
            ForEach(viewModelLiked.likedPosts) { post in
                likedPostCell(for: post)
                    .task {
                        await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                    }
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    @ViewBuilder
    private func likedPostCell(for post: DesignPost) -> some View {
       CommunityCards(
           post: post,
           onOpen: { postToOpen in
               // Check subscription limits first
               if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                   showingLimitAlert = true
                   return
               }
               
               // Show loading toast
               ToastManager.shared.showToast(ToastData(title: "Loading Design...", icon: "clock.fill", duration: 5.0))
               
               Task {
                   do {
                       // 1. Fetch full details (including design_json)
                       let fullPost = try await PostFetcher.fetchPostDetails(id: postToOpen.id)
                       
                       // 2. Create DesignFile from post
                       if let newDesign = designManager.createDesignFromPost(post: fullPost, name: fullPost.title) {
                           // 3. Open it
                           await MainActor.run {
                               ToastManager.shared.dismissToast()
                               #if os(macOS)
                               openWindow(value: newDesign.id)
                               #else
                               designManager.openDesign(newDesign)
                               #endif
                           }
                       }
                   } catch {
                       print("Error opening liked post: \(error)")
                       await MainActor.run {
                           ToastManager.shared.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                       }
                   }
               }
           }
       )
    }
}
