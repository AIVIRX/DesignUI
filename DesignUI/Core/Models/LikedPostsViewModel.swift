//
//  LikedPostsViewModel.swift
//  DockUI
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

class LikedPostsViewModel: ObservableObject {
    @Published var likedPosts: [DesignPost] = []
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
    func loadMoreLikedPostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        guard let item = item else {
            await fetchLikedPosts()
            return
        }
        
        // Prevent loading for the same item multiple times
        guard lastLoadItemId != item.id else { return }
        
        // Load more when we're within the last 3 items (same as templates page)
        let thresholdOffset = min(3, likedPosts.count)
        let thresholdIndex = likedPosts.index(likedPosts.endIndex, offsetBy: -thresholdOffset, limitedBy: likedPosts.startIndex) ?? likedPosts.startIndex
        if let itemIndex = likedPosts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            lastLoadItemId = item.id
            await fetchLikedPosts()
        }
    }
    
    @MainActor
    func fetchLikedPosts() async {
        guard !isLoading && hasMorePosts && !isRefreshing else { return }
        guard let userId = client.auth.currentUser?.id else { return }
        
        isLoading = true
        error = nil
        lastLoadItemId = nil // Reset when starting a new fetch
        
        do {
            let response = try await client
                .from("likes")
                .select("""
                    created_at,
                    posts!inner (
                    *,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                        )
                    )
                """)
                .eq("user_id", value: userId)
                .eq("posts.public", value: true)
                .order("created_at", ascending: false)
                .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                .execute()
            
            struct LikeResponse: Codable {
                let created_at: String
                let posts: DesignPost
            }
            
            let likeResponses = try JSONDecoder().decode([LikeResponse].self, from: response.data)
            let newLikedPosts = likeResponses.map { $0.posts }
            
            likedPosts.append(contentsOf: newLikedPosts)
            currentPage += 1
            hasMorePosts = newLikedPosts.count == pageSize
            lastLoadItemId = nil // Reset after successful load
        } catch {
            self.error = error
            // Only log non-cancelled errors
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Silently handle cancelled requests - these are usually due to view lifecycle changes
                return
            }
            print("Error fetching liked posts: \(error)")
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
        likedPosts.removeAll()
        hasMorePosts = true
        error = nil
        
        defer {
            isRefreshing = false
            isLoading = false
        }
        
        // Only fetch first page on refresh - let pagination handle the rest
        do {
            let response = try await client
                .from("likes")
                .select("""
                    created_at,
                    posts!inner (
                        *,
                        profiles!posts_author_id_fkey (
                          username,
                          verified
                        )
                    )
                    """)
                .eq("user_id", value: userId)
                .eq("posts.public", value: true)
                .order("created_at", ascending: false)
                .range(from: 0, to: pageSize - 1)
                .execute()
            
            struct LikeResponse: Codable {
                let created_at: String
                let posts: DesignPost
            }
            
            let likeResponses = try JSONDecoder().decode([LikeResponse].self, from: response.data)
                let newLikedPosts = likeResponses.map { $0.posts }
                
            likedPosts = newLikedPosts
            currentPage = 1
            hasMorePosts = newLikedPosts.count == pageSize
        } catch {
            self.error = error
            // Only log non-cancelled errors
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Silently handle cancelled requests - these are usually due to view lifecycle changes
                return
            }
            print("Error refreshing liked posts: \(error)")
        }
    }
    
    @MainActor
    func addLikedPost(postId: String) async {
        // Check if post is already in the list
        guard !likedPosts.contains(where: { $0.id == postId }) else { return }
        
        guard client.auth.currentUser != nil else { return }
        
        do {
            // Fetch the post details
            let postResponse = try await client
                .from("posts")
                .select("""
                    *,
                    profiles!posts_author_id_fkey (
                        username,
                        verified
                    )
                """)
                .eq("id", value: postId)
                .eq("public", value: true)
                .single()
                .execute()
            
            let post = try JSONDecoder().decode(DesignPost.self, from: postResponse.data)
            
            // Add to the beginning of the list (most recent likes first)
            likedPosts.insert(post, at: 0)
        } catch {
            print("Error adding liked post: \(error)")
            // If fetching fails, just refresh the list
            await refreshPosts()
        }
    }
    
    deinit {
        currentTask?.cancel()
    }
}
