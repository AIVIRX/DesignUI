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
    private var lastLoadItemId: String?
    
    @MainActor
    func loadMoreUserPostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        guard let item = item else {
            await fetchUserPosts()
            return
        }
        
        // Prevent loading for the same item multiple times
        guard lastLoadItemId != item.id else { return }
        
        // Load more when we're within the last 3 items (same as templates page)
        let thresholdOffset = min(3, userPosts.count)
        let thresholdIndex = userPosts.index(userPosts.endIndex, offsetBy: -thresholdOffset, limitedBy: userPosts.startIndex) ?? userPosts.startIndex
        if let itemIndex = userPosts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            lastLoadItemId = item.id
            await fetchUserPosts()
        }
    }
    
    @MainActor
    func fetchUserPosts() async {
        guard !isLoading && hasMorePosts && !isRefreshing else { return }
        guard let userId = client.auth.currentUser?.id else { return }
        
        isLoading = true
        error = nil
        lastLoadItemId = nil // Reset when starting a new fetch
        
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
            currentPage += 1
            hasMorePosts = newPosts.count == pageSize
            lastLoadItemId = nil // Reset after successful load
        } catch {
            self.error = error
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            print("Error fetching user posts: \(error)")
        }
        
        isLoading = false
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
        
        guard postAuthor.author_id == userId.uuidString else {
            throw NSError(domain: "UserPostsViewModel", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only delete your own posts"])
        }
        
        // Delete the post
        try await client
            .from("posts")
            .delete()
            .eq("id", value: postId)
            .execute()
        
        // Remove from local array
        userPosts.removeAll { $0.id == postId }
    }
    
    deinit {
        currentTask?.cancel()
    }
}

