import SwiftUI
import SDWebImageSwiftUI

struct SimilarPostsView: View {
    @State private var similarPosts: [DesignPost] = []
    var currentPostId: String
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    var body: some View {
        VStack(alignment: .leading) {
            if !similarPosts.isEmpty {
                Text("Similar Posts")
                    .font(.title2).bold()
                    .padding(.leading, 8)
                    .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(similarPosts) { post in
                            DesignCards(post: post)
                            .frame(width: 200) // Constrain width for horizontal scroll
                        }
                    }
                    .padding(.horizontal, 8) // Horizontal padding for hover scale
                    .padding(.vertical, 8) // Vertical padding for hover scale (top and bottom)
                }
                .scrollIndicators(.never)

            } else {
                Text("No posts found")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            fetchSimilarPosts()
        }
    }
    
    private func fetchSimilarPosts() {
        let client = SupabaseManager.shared.client
        
        Task {
            do {
                let response: [DesignPost] = try await client
                    .from("posts")
                    .select("""
                    *,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                    )
                """)
                    .eq("public", value: true)
                    .eq("post_type", value: "fullscreen")
                    .neq("id", value: currentPostId)
                    .order("created_at", ascending: false)
                    .limit(5)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.similarPosts = response
                }
            } catch {
                // Only log non-cancelled errors
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    // Silently handle cancelled requests - these are usually due to view lifecycle changes
                    return
                }
                print("Error fetching similar posts: \(error)")
            }
        }
    }
}
