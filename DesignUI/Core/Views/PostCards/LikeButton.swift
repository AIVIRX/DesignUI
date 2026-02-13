//
//  LikeButton.swift
//
//  Created by Maicol Cabreja on 2/7/25.
//

import SwiftUI

extension Notification.Name {
    static let likesChanged = Notification.Name("likesChanged")
}

struct LikeButton: View {
    let postId: String
    @State private var isLiked: Bool = false
    @State private var isLoading = false
    @State private var showAlert = false
    private let supabase = SupabaseManager.shared.client
    @Environment(\.requestReview) private var requestReview
    init(postId: String) {
        self.postId = postId
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
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .foregroundColor(isLiked ? .red : .white)
                .font(.system(size: 16))
        }
        .disabled(isLoading)
        .task {
            await fetchLikeStatus()
        }
        .alert("Sign In Required", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need to be signed in to like a design.")
        }
#if os(iOS)
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.triggerImpact(style: .soft)
        })
#endif
#if os(macOS)
        .buttonStyle(BorderlessButtonStyle())
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
                NotificationCenter.default.post(name: .likesChanged, object: nil, userInfo: [
                    "postId": postId,
                    "isLiked": false
                ])
            } else {
                let insertData: [String: UUID] = [
                    "post_id": postUUID,
                    "user_id": userId
                ]
                
                try await supabase.from("likes")
                    .insert(insertData)
                    .execute()
                
                isLiked = true
                NotificationCenter.default.post(name: .likesChanged, object: nil, userInfo: [
                    "postId": postId,
                    "isLiked": true
                ])
                
                // Request review when user favorites a post (only once per session)
                if !SessionManager.shared.hasRequestedReview {
                    requestReview()
                    SessionManager.shared.hasRequestedReview = true
                }
            }
        } catch {
            print("Error toggling like:", error)
        }
        
        isLoading = false
    }
}
