import SwiftUI

struct BookmarkedPostsView: View {
    let userId: String
    @StateObject private var viewModel = BookmarkedPostsViewModel()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.bookmarkedPosts) { post in
                    DesignCards(
                        id: post.id,
                        media: post.preview_image_url,
                        title: post.title,
                        authorName: post.profiles.username,
                        isVerified: post.profiles.verified,
                        description: post.description,
                        codeSnippet: post.code_snippet,
                        published: post.created_at
                    )
                }
            }
            .padding(.horizontal)
        }
        .task {
            await viewModel.fetchBookmarkedPosts(userId: userId)
        }
    }
} 