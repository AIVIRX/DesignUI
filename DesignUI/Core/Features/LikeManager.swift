//
//  LikeManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/18/24.
//

import Foundation
import Supabase

@MainActor
class LikeManager: ObservableObject {
    static let shared = LikeManager()
    private let client = SupabaseManager.shared.client
    
    @Published var likedPosts: Set<String> = []
    
    func like(postId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id,
              let postUUID = UUID(uuidString: postId) else { return }
        try await client
            .rpc(
                "handle_like",
                params: [
                    "post_uuid": postUUID,
                    "user_uuid": userId
                ]
            )
            .execute()
        
        likedPosts.insert(postId)
    }
    
    func unlike(postId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id,
              let postUUID = UUID(uuidString: postId) else { return }
        try await client
            .rpc(
                "handle_unlike",
                params: [
                    "post_uuid": postUUID,
                    "user_uuid": userId
                ]
            )
            .execute()
        
        likedPosts.remove(postId)
    }
    
    func toggleLike(postId: String) async throws {
        if likedPosts.contains(postId) {
            try await unlike(postId: postId)
        } else {
            try await like(postId: postId)
        }
    }
    
    func fetchLikedPosts() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        do {
            let response: [Like] = try await client
                .from("likes")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            likedPosts = Set(response.map { $0.postId })
        } catch {
            print("Error fetching liked posts: \(error)")
        }
    }
}
