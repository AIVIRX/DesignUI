//
//  LikedPostsViewModel.swift
//  DesignUI
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
    
    @MainActor
    func loadMoreLikedPostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing else { return }
        
        guard let item = item else {
            await fetchLikedPosts()
            return
        }
        
        let thresholdIndex = likedPosts.index(likedPosts.endIndex, offsetBy: -1)
        if let itemIndex = likedPosts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            await fetchLikedPosts()
        }
    }
    
    @MainActor
    func fetchLikedPosts() async {
        guard !isLoading && hasMorePosts && !isRefreshing else { return }
        
        guard let userId = client.auth.currentUser?.id else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await client
                .from("posts")
                .select("""
                    *,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                    ),
                    likes!inner(*)
                """)
                .eq("likes.user_id", value: userId)
                .order("created_at", ascending: false)
                .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                .execute()
            
            let newLikedPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
            
            likedPosts.append(contentsOf: newLikedPosts)
            currentPage += 1
            hasMorePosts = newLikedPosts.count == pageSize
        } catch {
            self.error = error
            print("Error fetching liked posts: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshPosts() async {
        // Cancel any existing refresh task
        currentTask?.cancel()
        
        guard !isRefreshing else { return }
        guard let userId = client.auth.currentUser?.id else { return }
        
        isRefreshing = true
        currentPage = 0
        likedPosts.removeAll()
        hasMorePosts = true
        error = nil
        
        // Create new task for this refresh
        currentTask = Task {
            do {
                let response = try await client
                    .from("posts")
                    .select("""
                            *,
                            profiles!posts_author_id_fkey (
                              username,
                              verified
                            ),
                            likes!inner(*)
                        """)
                    .eq("likes.user_id", value: userId)
                    .order("created_at", ascending: false)
                    .range(from: 0, to: pageSize - 1)
                    .execute()
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                let newLikedPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
                likedPosts = newLikedPosts
                currentPage = 1
                hasMorePosts = newLikedPosts.count == pageSize
                
                // If we have more posts and task wasn't cancelled, fetch the next batch
                if hasMorePosts && !Task.isCancelled {
                    await fetchLikedPosts()
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    print("Error refreshing liked posts: \(error)")
                }
            }
            
            isRefreshing = false
        }
    }
    
    deinit {
        currentTask?.cancel()
    }
}
