import Foundation
import Supabase

@MainActor
class PostsManager: ObservableObject {
    private let client = SupabaseManager.shared.client
    private var currentTask: Task<Void, Never>?
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchPosts() {
        // Cancel any existing fetch task
        currentTask?.cancel()
        
        currentTask = Task {
            isLoading = true
            error = nil
            
            do {
                let query = client.database
                    .from("posts")
                    .select("""
                        *,
                        profiles!posts_author_id_fkey(
                            username,
                            verified
                        )
                    """)
                    .order("created_at", ascending: false)
                    .limit(6)
                
                let response: [Post] = try await query.execute().value
                
                // Check if task was cancelled
                if !Task.isCancelled {
                    self.posts = response
                }
            } catch {
                if !Task.isCancelled {
                    print("Error fetching posts: \(error)")
                    self.error = error
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    deinit {
        currentTask?.cancel()
    }
} 