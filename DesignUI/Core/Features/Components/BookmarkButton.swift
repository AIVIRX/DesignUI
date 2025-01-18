import SwiftUI

struct BookmarkButton: View {
    let postId: String
    @State private var isBookmarked = false
    @StateObject private var bookmarkManager = BookmarkManager.shared
    
    var body: some View {
        Button {
            Task {
                try? await bookmarkManager.toggleBookmark(postId: postId)
                // Update bookmark status after toggle
                if let status = try? await bookmarkManager.isBookmarked(postId: postId) {
                    isBookmarked = status
                }
            }
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? .blue : .gray)
                .font(.system(size: 22))
        }
        .task {
            // Check initial bookmark status
            if let status = try? await bookmarkManager.isBookmarked(postId: postId) {
                isBookmarked = status
            }
        }
    }
} 