//
//  LikedPostsViewModel.swift
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

class LikedPostsViewModel: ObservableObject {
    private struct LikeResponse: Codable {
        let created_at: String
        let posts: DesignPost
    }

    @Published var likedPosts: [DesignPost] = []
    @Published var isLoading: Bool = false
    @Published var hasMorePosts: Bool = true
    @Published var error: Error?
    private var currentTask: Task<Void, Never>?
    
    private var currentPage: Int = 0
    private let pageSize: Int = 6
    private let client = SupabaseManager.shared.client
    private var isRefreshing = false
    private let likedPostsSelection = """
        created_at,
        posts!inner (
        *,
        profiles!posts_author_id_fkey (
          username,
          verified
            )
        )
    """
    
    // Memory management: Keep max 150 items, remove oldest when limit reached
    private let maxItemsInMemory: Int = 150
    private let itemsToRemoveWhenFull: Int = 50
    
    @MainActor
    func loadMoreLikedPostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        guard let item = item else {
            await fetchLikedPosts()
            return
        }
        
        // Load more when we're within the last 3 items (same as home page)
        let thresholdOffset = min(3, likedPosts.count)
        let thresholdIndex = likedPosts.index(likedPosts.endIndex, offsetBy: -thresholdOffset, limitedBy: likedPosts.startIndex) ?? likedPosts.startIndex
        if let itemIndex = likedPosts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            await fetchLikedPosts()
        }
    }
    
    @MainActor
    func fetchLikedPosts() async {
        // Don't block on isRefreshing - allow pagination after refresh completes
        guard !isLoading && hasMorePosts else { return }
        guard let userId = client.auth.currentUser?.id else { return }
        
        // Cancel any existing task
        currentTask?.cancel()
        
        isLoading = true
        error = nil

        let page = currentPage
        currentTask = Task {
            await fetchLikedPostsPage(userId: userId, page: page)
        }
    }

    @MainActor
    private func fetchLikedPostsPage(userId: UUID, page: Int) async {
        defer { isLoading = false }

        do {
            let newLikedPosts = try await loadLikedPostsPage(userId: userId, page: page)
            appendLikedPostsPage(newLikedPosts)
        } catch {
            handleFetchError(error, message: "Error fetching liked posts")
        }
    }

    @MainActor
    private func loadLikedPostsPage(userId: UUID, page: Int) async throws -> [DesignPost] {
        let startIndex = page * pageSize
        let endIndex = startIndex + pageSize - 1
        let response = try await client
            .from("likes")
            .select(likedPostsSelection)
            .eq("user_id", value: userId)
            .eq("posts.public", value: true)
            .order("created_at", ascending: false)
            .range(from: startIndex, to: endIndex)
            .execute()

        return try decodeLikedPosts(from: response.data)
    }

    private func decodeLikedPosts(from data: Data) throws -> [DesignPost] {
        let likeResponses = try JSONDecoder().decode([LikeResponse].self, from: data)
        return likeResponses.map { $0.posts }
    }

    @MainActor
    private func appendLikedPostsPage(_ newLikedPosts: [DesignPost]) {
        likedPosts.append(contentsOf: newLikedPosts)
        trimLikedPostsIfNeeded()
        currentPage += 1
        hasMorePosts = newLikedPosts.count == pageSize
    }

    @MainActor
    private func trimLikedPostsIfNeeded() {
        guard likedPosts.count > maxItemsInMemory else { return }
        let overflowCount = likedPosts.count - maxItemsInMemory
        let itemsToRemove = min(itemsToRemoveWhenFull, overflowCount)
        likedPosts.removeFirst(itemsToRemove)
    }

    @MainActor
    private func handleFetchError(_ error: Error, message: String) {
        self.error = error
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return
        }
        print("\(message): \(error)")
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
        guard !likedPosts.contains(where: { $0.id == postId }) else {
            print("Post \(postId) already in liked posts list")
            return
        }
        
        guard client.auth.currentUser != nil else {
            print("User not authenticated, cannot add liked post")
            return
        }
        
        do {
            // Fetch the post details - try without public filter first, then with it
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
                .single()
                .execute()
            
            let post = try JSONDecoder().decode(DesignPost.self, from: postResponse.data)
            
            // Add to the beginning of the list (most recent likes first)
            likedPosts.insert(post, at: 0)
            print("Successfully added post \(postId) to liked posts")
        } catch {
            print("Error adding liked post \(postId): \(error.localizedDescription)")
            // If fetching fails, try refreshing the list to get latest data
            await refreshPosts()
        }
    }
    
    deinit {
        currentTask?.cancel()
    }
}
