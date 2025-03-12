//
//  LikeButton.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/7/25.
//

import SwiftUI

struct LikeButton: View {
    let postId: String
    let initialLikeCount: Int
    @State private var isLiked: Bool = false
    @State private var likeCount: Int
    @State private var isLoading = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAlert = false
    private let supabase = SupabaseManager.shared.client
    
    init(postId: String, initialLikeCount: Int) {
        self.postId = postId
        self.initialLikeCount = initialLikeCount
        _likeCount = State(initialValue: initialLikeCount)
    }
    
    var body: some View {
        Button {
            Task {
                if supabase.auth.currentUser != nil {
                    await handleLike()
                } else {
                    showAlert = true
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .gray)
                    .font(.system(size: 16))
                
                Text("\(formatCount(likeCount))")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .opacity(isLoading ? 0.7 : 1.0)
        .animation(.spring(response: 0.2), value: isLoading)
        .task {
            await fetchLikeStatus()
        }
        .alert("Sign In Required", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need to be signed in to like a design.")
        }
#if os(macOS)
        .buttonStyle(PlainButtonStyle())
#endif
    }
    
    private func fetchLikeStatus() async {
        guard let userId = supabase.auth.currentUser?.id,
              let postUUID = UUID(uuidString: postId) else { return }
        
        do {
            let count = try await supabase.from("likes")
                .select("*", head: true, count: .exact)
                .eq("user_id", value: userId)
                .eq("post_id", value: postUUID)
                .execute()
                .count ?? 0
            
            isLiked = (count > 0)
        } catch {
            print("Error fetching like status:", error)
        }
    }
    
    private func handleLike() async {
        guard let userId = supabase.auth.currentUser?.id,
              let postUUID = UUID(uuidString: postId) else { return }
        
        guard !isLoading else { return }
        isLoading = true
        
        do {
            if isLiked {
                try await supabase.from("likes")
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("post_id", value: postUUID)
                    .execute()
                
                isLiked = false
                likeCount = max(0, likeCount - 1)
            } else {
                let insertData: [String: UUID] = [
                    "post_id": postUUID,
                    "user_id": userId
                ]
                
                try await supabase.from("likes")
                    .insert(insertData)
                    .execute()
                
                isLiked = true
                likeCount += 1
            }
        } catch {
            print("Error toggling like:", error)
        }
        
        isLoading = false
    }
}
