import SwiftUI
import SDWebImageSwiftUI

struct SimilarPostsView: View {
    @State private var similarPosts: [DesignPost] = []
    var currentPostId: String
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !similarPosts.isEmpty {
                Text("Similar Posts")
                    .font(.title2).bold()
                    .padding(.top, 5)
                    .padding(.bottom, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(similarPosts) { post in
                            // Determine if it's a component based on post_type
                            let postType = post.post_type?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let isComponent = postType == "component"
                            
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
                                isPremium: post.isPremium == true,
                                isComponent: isComponent
                            )
                            .frame(width: 200) // Constrain width for horizontal scroll
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16) // Top padding for hover scale
                    .padding(.bottom, 16) // Bottom padding for hover scale
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
