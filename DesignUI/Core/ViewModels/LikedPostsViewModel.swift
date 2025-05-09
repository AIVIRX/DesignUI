import SwiftUI
import Supabase

class LikedPostsViewModel: ObservableObject {
    @Published var likedPosts: [DesignPost] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase = SupabaseManager.shared.client
    
    @MainActor
    func fetchLikedPosts() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        isLoading = true
        
        do {
            let response = try await supabase
                .from("likes")
                .select("""
                    created_at,
                    posts!inner (
                        *,
                        profiles!posts_author_id_fkey (
                            username,
                            verified
                        )
                    )
                """)
                .eq("user_id", value: userId)
                .order("created_at", ascending: false) // Order by when the user liked the post
                .execute()
            
            // We need to decode the nested structure
            struct LikeResponse: Codable {
                let created_at: String
                let posts: DesignPost
            }
            
            let likeResponses = try JSONDecoder().decode([LikeResponse].self, from: response.data)
            // Extract just the posts from the response
            self.likedPosts = likeResponses.map { $0.posts }
            
        } catch {
            self.error = error
            print("Error fetching liked posts: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func unlikePost(_ postId: String) async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        
        do {
            try await supabase
                .from("likes")
                .delete()
                .eq("post_id", value: postId)
                .eq("user_id", value: userId)
                .execute()
            
            // Remove the unliked post from the local array
            likedPosts.removeAll { $0.id == postId }
            
        } catch {
            self.error = error
            print("Error unliking post: \(error)")
        }
    }
} 