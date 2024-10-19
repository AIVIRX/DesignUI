import SwiftUI

struct LikedView: View {
    @State private var likedPosts: [DesignPost] = []
    @State private var hasMoreLikedPosts = true
    @State private var isLoading: Bool = false
    @State private var isLikedPostsLoaded = false
    private let postsLimit = 2
    var body: some View {
        VStack {
//            if likedPosts.isEmpty && isLoading {
//                ProgressView("Loading liked posts...")
//                    .bold()
//                    .frame(width: 185, height: 400)
//            } else if !likedPosts.isEmpty && isLikedPostsLoaded {
//                
//                LazyVGrid(columns: gridColumns, spacing: 16) {
//                    ForEach(Array(likedPosts.enumerated()), id: \.offset) { index, post in
//                        DesignCards(
//                            id: post.id,
//                            media: post.image_url,
//                            title: post.title,
//                            authorUID: post.author,
//                            description: post.description,
//                            codeSnippet: post.codeSnippet,
//                            published: formattedDate(from: post.creationDate),
//                            type: post.type,
//                            tags: post.tags,
//                            likes: post.likesCount,
//                            views: post.viewCount,
//                            hexa: post.hexa,
//                            visibility: post.visibility
//                        )
//                        .onAppear {
//                            if index == likedPosts.count - 1 {
//                                loadMoreLikedPostsIfNeeded()
//                            }
//                        }
//                    }
//                    if isLoading {
//                        
//                        ProgressView()
//                            .frame(width: 185, height: 400)
//                    }
//                }
//                .padding()
//            } else {
//                
//                Text("No liked posts yet.")
//                    .bold()
//                    .frame(height: 200)
//            }
        }
        .frame(maxWidth: 1600)
        .task {
//            if !isLikedPostsLoaded {
//                await fetchLikedPosts(reset: true)
//                isLikedPostsLoaded = true
//            }
        }
    }
    
    
    
}
