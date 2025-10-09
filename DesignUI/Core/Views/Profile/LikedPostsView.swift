//
//  LikedPostsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

struct LikedPostsView2: View {
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
                LazyVGrid(columns: gridColumns, spacing: 16) {
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
                            likesCount: post.likes_count,
                            isLiked: false
                        )
                        .task {
                            await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .task {
            await viewModelLiked.fetchLikedPosts()
        }
    }
}
