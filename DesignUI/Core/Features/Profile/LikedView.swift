import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LikedView: View {
    @State private var likedPosts: [DesignPost] = []
    @State private var lastFetchedDocument: DocumentSnapshot?
    @State private var hasMoreLikedPosts = true
    @State private var isLoading: Bool = false
    @State private var isLikedPostsLoaded = false
    private let postsLimit = 4
    var body: some View {
        VStack {
            if likedPosts.isEmpty && isLoading {
                ProgressView("Loading liked posts...")
                    .bold()
                    .frame(width: 185, height: 400)
            } else if !likedPosts.isEmpty && isLikedPostsLoaded {
                
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(Array(likedPosts.enumerated()), id: \.offset) { index, post in
                        DesignCards(
                            id: post.id,
                            media: post.media,
                            title: post.title,
                            authorUID: post.author,
                            description: post.description,
                            codeSnippet: post.codeSnippet,
                            published: formattedDate(from: post.creationDate),
                            type: post.type,
                            tags: post.tags,
                            likes: post.likesCount,
                            views: post.viewCount,
                            hexa: post.hexa,
                            visibility: post.visibility
                        )
                        .onAppear {
                            if post == likedPosts.last {
                                loadMoreLikedPostsIfNeeded()
                            }
                        }
                    }
                    if isLoading {
                        
                        ProgressView()
                            .frame(width: 185, height: 400)
                    }
                }
                .padding()
            } else {
                
                Text("No liked posts yet.")
                    .bold()
                    .frame(height: 200)
            }
        }
        .task {
            if !isLikedPostsLoaded {
                await fetchLikedPosts(reset: true)
                isLikedPostsLoaded = true
            }
        }
    }
    
    private func loadMoreLikedPostsIfNeeded() {
        guard hasMoreLikedPosts && !isLoading else { return }
        Task {
            await fetchLikedPosts()
        }
    }
    
    private func fetchLikedPosts(reset: Bool = false) async {
        let db = Firestore.firestore()
        
        guard let user = Auth.auth().currentUser else { return }
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if reset {
                lastFetchedDocument = nil
                likedPosts.removeAll()
                hasMoreLikedPosts = true // Reset this when doing a fresh fetch
            }
            
            var query = db.collection("users")
                .document(user.uid)
                .collection("likedPosts")
                .order(by: "timestamp", descending: true)
                .limit(to: postsLimit)
            
            if let lastDocument = lastFetchedDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let likedPostsSnapshot = try await query.getDocuments()
            
            if likedPostsSnapshot.documents.isEmpty {
                hasMoreLikedPosts = false // No more posts to load
                return
            }
            
            var fetchedPosts: [DesignPost] = []
            
            for likedPostDoc in likedPostsSnapshot.documents {
                let postID = likedPostDoc.documentID
                
                // Fetch the full post details from the `posts` subcollection
                let postSnapshot = try await db.collection("posts").document(postID).getDocument()
                if let post = try? postSnapshot.data(as: DesignPost.self) {
                    fetchedPosts.append(post)
                }
            }
            
            lastFetchedDocument = likedPostsSnapshot.documents.last
            likedPosts.append(contentsOf: fetchedPosts)
            
            // Set `hasMoreLikedPosts` to false if fewer posts were fetched than the limit
            hasMoreLikedPosts = likedPostsSnapshot.documents.count == postsLimit
        } catch {
            print("Error fetching liked posts: \(error)")
        }
    }
}
