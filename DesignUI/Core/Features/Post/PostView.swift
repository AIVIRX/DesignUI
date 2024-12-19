import SwiftUI

struct PostView: View {
    @StateObject private var postsManager = PostsManager()
    
    var body: some View {
        Group {
            if postsManager.isLoading {
                ProgressView()
            } else if let error = postsManager.error {
                VStack {
                    Text("Error loading posts")
                        .foregroundColor(.red)
                    Button("Retry") {
                        postsManager.fetchPosts()
                    }
                }
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(postsManager.posts) { post in
                            PostCard(post: post)
                        }
                    }
                }
            }
        }
        .task {
            postsManager.fetchPosts()
        }
    }
} 