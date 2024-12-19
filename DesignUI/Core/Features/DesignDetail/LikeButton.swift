//
//  LikeButton.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/18/24.
//

import SwiftUI

struct LikeButton: View {
    let postId: String
    @StateObject private var likeManager = LikeManager.shared
    
    var body: some View {
        Button {
            Task {
                try? await likeManager.toggleLike(postId: postId)
            }
        } label: {
            Image(systemName: likeManager.likedPosts.contains(postId) ? "heart.fill" : "heart")
                .foregroundColor(likeManager.likedPosts.contains(postId) ? .red : .gray)
                .font(.system(size: 22))
        }
    }
}
