import Foundation
import Supabase

@MainActor
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    private let client = SupabaseManager.shared.client
    
    func toggleBookmark(postId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        // Check if post is already bookmarked
        let exists = try await client.database
            .from("bookmarks")
            .select("*", head: true)
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
            .count ?? 0 > 0
        
        if exists {
            // Remove bookmark
            try await client.database
                .from("bookmarks")
                .delete()
                .eq("post_id", value: postId)
                .eq("user_id", value: userId)
                .execute()
        } else {
            // Add bookmark
            try await client.database
                .from("bookmarks")
                .insert(["post_id": postId, "user_id": userId])
                .execute()
        }
    }
    
    func isBookmarked(postId: String) async throws -> Bool {
        guard let userId = AuthManager.shared.currentUser?.id else { return false }
        
        let count = try await client.database
            .from("bookmarks")
            .select("*", head: true)
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
            .count ?? 0
        
        return count > 0
    }
} 