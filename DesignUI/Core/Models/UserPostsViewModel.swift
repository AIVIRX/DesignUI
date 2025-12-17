//
//  UserPostsViewModel.swift
//  DockUI
//
//  Created by Maicol Cabreja on 1/15/25.
//

import SwiftUI

class UserPostsViewModel: ObservableObject {
    @Published var userPosts: [DesignPost] = []
    @Published var isLoading: Bool = false
    @Published var hasMorePosts: Bool = true
    @Published var error: Error?
    private var currentTask: Task<Void, Never>?
    
    private var currentPage: Int = 0
    private let pageSize: Int = 6
    private let client = SupabaseManager.shared.client
    private let refreshCooldown: TimeInterval = 1
    private var isRefreshing = false
    
    // Memory management: Keep max 150 items, remove oldest when limit reached
    private let maxItemsInMemory: Int = 150
    private let itemsToRemoveWhenFull: Int = 50
    
    @MainActor
    func loadMoreUserPostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        guard let item = item else {
            await fetchUserPosts()
            return
        }
        
        // Load more when we're within the last 3 items (same as home page)
        let thresholdOffset = min(3, userPosts.count)
        let thresholdIndex = userPosts.index(userPosts.endIndex, offsetBy: -thresholdOffset, limitedBy: userPosts.startIndex) ?? userPosts.startIndex
        if let itemIndex = userPosts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            await fetchUserPosts()
        }
    }
    
    @MainActor
    func fetchUserPosts() async {
        // Don't block on isRefreshing - allow pagination after refresh completes
        guard !isLoading && hasMorePosts else { return }
        guard let userId = client.auth.currentUser?.id else { return }
        
        // Cancel any existing task
        currentTask?.cancel()
        
        isLoading = true
        error = nil
        
        currentTask = Task {
            do {
            let response = try await client
                .from("posts")
                .select("""
                    *,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                    )
                """)
                .eq("author_id", value: userId)
                .order("created_at", ascending: false)
                .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                .execute()
            
                let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
                
                userPosts.append(contentsOf: newPosts)
                
                // Memory management: Remove oldest items if we exceed the limit
                if userPosts.count > maxItemsInMemory {
                    let itemsToRemove = min(itemsToRemoveWhenFull, userPosts.count - maxItemsInMemory)
                    userPosts.removeFirst(itemsToRemove)
                }
                
                currentPage += 1
                hasMorePosts = newPosts.count == pageSize
            } catch {
                self.error = error
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    return
                }
                print("Error fetching user posts: \(error)")
            }
            
            isLoading = false
        }
    }
    
    @MainActor
    func refreshPosts() async {
        guard !isRefreshing else { return }
        guard let userId = client.auth.currentUser?.id else { return }
        
        isRefreshing = true
        isLoading = true
        currentPage = 0
        userPosts.removeAll()
        hasMorePosts = true
        error = nil
        
        defer {
            isRefreshing = false
            isLoading = false
        }
        
        // Only fetch first page on refresh - let pagination handle the rest
        do {
            let response = try await client
                .from("posts")
                .select("""
                    *,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                    )
                """)
                .eq("author_id", value: userId)
                .order("created_at", ascending: false)
                .range(from: 0, to: pageSize - 1)
                .execute()
            
            let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
            
            userPosts = newPosts
            currentPage = 1
            hasMorePosts = newPosts.count == pageSize
        } catch {
            self.error = error
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            print("Error refreshing user posts: \(error)")
        }
    }
    
    @MainActor
    func deletePost(postId: String) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw NSError(domain: "UserPostsViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Verify the post belongs to the user
        let postResponse = try await client
            .from("posts")
            .select("author_id")
            .eq("id", value: postId)
            .single()
            .execute()
        
        struct PostAuthor: Codable {
            let author_id: String
        }
        
        let postAuthor = try JSONDecoder().decode(PostAuthor.self, from: postResponse.data)
        
        // Compare UUIDs - handle both string and UUID formats
        let userIdString = userId.uuidString.lowercased()
        let authorIdString = postAuthor.author_id.lowercased()
        
        guard authorIdString == userIdString else {
            print("Delete failed: User ID mismatch. User: \(userIdString), Post author: \(authorIdString)")
            throw NSError(domain: "UserPostsViewModel", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only delete your own posts"])
        }
        
        // Delete the post
        try await client
            .from("posts")
            .delete()
            .eq("id", value: postId)
            .execute()
        
        // Remove from local array (already on MainActor)
        userPosts.removeAll { $0.id == postId }
        
        print("Post \(postId) deleted successfully")
    }
    
    deinit {
        currentTask?.cancel()
    }
}

