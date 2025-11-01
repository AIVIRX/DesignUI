//
//  LikedPostsView.swift
//  DesignUI
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
                LazyVGrid(columns: gridColumns, spacing: UIDevice.current.userInterfaceIdiom == .phone ? 8 : 16) {
                    ForEach(viewModelLiked.likedPosts) { post in
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
                            isPremium: post.isPremium == true
                        )
                        .task {
                            await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                        }
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 8 : 16)
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
            }
        }
        .refreshable {
            await viewModelLiked.refreshPosts()
        }
    }
}
