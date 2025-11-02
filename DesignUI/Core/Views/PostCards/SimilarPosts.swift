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
                    .padding(.top, 5)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 15) {
                        ForEach(similarPosts) { post in
                            if (post.isPremium == true) && !subscriptionManager.isSubscribed {
                                Button {
                                    paywallManager.present()
                                } label: {
                                    SimilarPostCard(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
#if os(iOS)
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.triggerImpact(style: .heavy)
                                })
#endif
                            } else {
                                NavigationLink(destination: DetailView(
                                    id: post.id,
                                    mediaURL: post.preview_image_url,
                                    title: post.title,
                                    description: post.description,
                                    author: post.profiles.username,
                                    codeSnippet: post.code_snippet,
                                    creationDate: post.created_at,
                                    isAuthorVerified: post.profiles.verified,
                                    isPremium: post.isPremium == true,
                                )) {
                                    SimilarPostCard(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
#if os(iOS)
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.triggerImpact(style: .heavy)
                                })
#endif
                            }
                        }
                    }
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
                    .limit(3)
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

struct SimilarPostCard: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let post: DesignPost
    
    var body: some View {
        VStack(alignment:.leading){
            RoundedRectangle(cornerRadius: 15)
                .frame(width: 380)
#if os(iOS)
                .frame(height: 280)
#endif
            
#if os(macOS)
                .frame(height: 280)
#endif
            
#if os(iOS)
                .foregroundStyle(.thinMaterial)
#endif
            
#if os(macOS)
                .foregroundStyle(Color.gray.opacity(0.2))
#endif
                .overlay{
                    RoundedRectangle(cornerRadius: 15)
#if os(iOS)
                        .frame(width: 115, height: 250)
#endif
                        
#if os(macOS)
                        .frame(width: 115, height: 250)
#endif
                        .overlay {
                            WebImage(url: URL(string: post.preview_image_url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: 350)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
#if os(iOS)
                                        .frame(maxWidth: .infinity, maxHeight: 250)
#endif
#if os(macOS)
                                        .frame(maxWidth: .infinity, maxHeight: 250)
#endif
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .clipped()
                                        .shadow(radius: 8)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity, maxHeight: 250)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .clipped()
                                        .shadow(radius: 8)
                                }
                            }
                        }
                }
            VStack(alignment: .leading){
                Text(post.title)
                    .font(.system(size: 16).bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                HStack {
                    if post.isPremium == true {
                        // Empty space since sparkle icon will be shown next to like button
                    } else {
                        Text(post.profiles.username)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .textSelection(.disabled)
                        if post.profiles.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        if post.isPremium == true {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.clear)
                                .overlay(
                                    LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                        .mask(
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14, weight: .semibold))
                                        )
                                )
                                .padding(.leading, 8)
                        }
                        LikeButton(postId: post.id)
                    }
                    .padding(.vertical, 6)
                    .padding(.trailing, 6)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        
    }
}
