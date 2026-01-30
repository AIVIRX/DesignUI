//
//  LikedPostsView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

struct LikedPostsView: View {
    @StateObject private var viewModelLiked = LikedPostsViewModel()
    
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
       CommunityCards(post: post)
    }
}
