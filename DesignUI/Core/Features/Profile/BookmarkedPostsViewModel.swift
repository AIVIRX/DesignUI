@MainActor
class BookmarkedPostsViewModel: ObservableObject {
    @Published var bookmarkedPosts: [DesignPost] = []
    private let client = SupabaseManager.shared.client
    
    func fetchBookmarkedPosts(userId: String) async {
        do {
            let response: [DesignPost] = try await client.database
                .from("bookmarks")
                .select("""
                    posts!inner (
                        *,
                        profiles!posts_author_id_fkey (
                            username,
                            verified
                        )
                    )
                """)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            bookmarkedPosts = response.compactMap { $0.posts }
        } catch {
            print("Error fetching bookmarked posts: \(error)")
        }
    }
} 