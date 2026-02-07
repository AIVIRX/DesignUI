import SwiftUI
import SDWebImageSwiftUI

struct SimilarPostsView: View {
    var currentPostId: String
    @State private var similarPosts: [DesignPost] = []
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @EnvironmentObject private var designManager: DesignManager
    @State private var showingPaywall = false
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
                            CommunityCards(
                                post: post,
            
                            )
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
        .sheet(isPresented: $showingPaywall) {
            CustomPaywallView()
                .environmentObject(PaywallManager.shared)
                .environmentObject(subscriptionManager)
        }
    }
    
    private func fetchSimilarPosts() {
        let client = SupabaseManager.shared.client
        
        Task {
            do {
                // Generate a random offset (0-20) to vary which posts we pull from
                // This gives variety while still being fast (single query, no complex logic)
                let randomOffset = Int.random(in: 0...20)
                
                // Fetch more posts than we need, then randomly sample
                // This is fast because we're just shifting the window into recent posts
                let response: [DesignPost] = try await client
                    .from("posts")
                    .select("""
                    id,
                    slug,
                    preview_image_url,
                    title,
                    created_at,
                    isPremium,
                    post_type,
                    status,
                    public,
                    design_json,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                    )
                """)
                    .eq("public", value: true)
                    .eq("post_type", value: "fullscreen")
                    .neq("id", value: currentPostId)
                    .order("created_at", ascending: false)
                    .range(from: randomOffset, to: randomOffset + 11) // Fetch 12 posts from random offset
                    .execute()
                    .value
                
                await MainActor.run {
                    // Shuffle and take first 4 for randomness
                    self.similarPosts = Array(response.shuffled().prefix(4))
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
