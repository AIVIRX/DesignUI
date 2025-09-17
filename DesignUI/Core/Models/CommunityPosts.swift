//
//  CommunityPosts.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/15/24.
//

import SwiftUI
import Supabase

class LatestPostsViewModel: ObservableObject {
    @Published var posts: [DesignPost] = []
    @Published var isLoading: Bool = false
    @Published var hasMorePosts: Bool = true
    @Published var error: Error?
    
    private var currentPage: Int = 0
    private let pageSize: Int = 6
    private let client = SupabaseManager.shared.client
    private var lastRefreshTime: Date?
    private let refreshCooldown: TimeInterval = 1
    private var isRefreshing = false
    private var currentTask: Task<Void, Never>?
    
    @MainActor
    func loadMorePostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing else { return }
        
        guard let item = item else {
            await fetchPosts()
            return
        }
        
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: -1)
        if let itemIndex = posts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            await fetchPosts()
        }
    }
    
    @MainActor
    func searchPosts(query: String) async {
        guard !query.isEmpty else {
            await refreshPosts() // Reset to default posts if query is cleared
            return
        }
        
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
                    )
                """)
                .eq("public", value: true)
                .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .limit(pageSize)
                .execute()
            
            let searchResults = try JSONDecoder().decode([DesignPost].self, from: response.data)
            posts = searchResults
            hasMorePosts = false
        } catch {
            self.error = error
            // Only log non-cancelled errors
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Silently handle cancelled requests - these are usually due to view lifecycle changes
                return
            }
            print("Error searching posts: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchPosts() async {
        guard !isLoading && hasMorePosts && !isRefreshing else { return }
        
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
                    .eq("public", value: true)
                    .order("created_at", ascending: false)
                    .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                    .execute()
                
                let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
                
                posts.append(contentsOf: newPosts)
                currentPage += 1
                hasMorePosts = newPosts.count == pageSize
            } catch {
                self.error = error
                // Only log non-cancelled errors
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    // Silently handle cancelled requests - these are usually due to view lifecycle changes
                    return
                }
                print("Error fetching posts: \(error)")
            }
            
            isLoading = false
            currentTask = nil
        }
    }
    
    @MainActor
    func refreshPosts() async {
        guard !isRefreshing else { return }
        
        let now = Date()
        if let lastRefresh = lastRefreshTime,
           now.timeIntervalSince(lastRefresh) < refreshCooldown {
            return
        }
        
        isRefreshing = true
        lastRefreshTime = now
        currentPage = 0
        error = nil
        posts.removeAll()
        hasMorePosts = true
        
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
                .eq("public", value: true)
                .order("created_at", ascending: false)
                .range(from: 0, to: pageSize - 1)
                .execute()
            
            let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
            posts = newPosts
            currentPage = 1
            hasMorePosts = newPosts.count == pageSize
            
            if hasMorePosts {
                await fetchPosts()
            }
        } catch {
            self.error = error
            // Only log non-cancelled errors
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Silently handle cancelled requests - these are usually due to view lifecycle changes
                return
            }
            print("Error refreshing posts: \(error)")
        }
        
        isRefreshing = false
    }
    
    @MainActor
    func fetchMostLikedPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        posts.removeAll()
        
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
                .eq("public", value: true)
                .order("likes_count", ascending: false)
                .limit(5)
                .execute()
            
            let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
            posts = newPosts
        } catch {
            self.error = error
            // Only log non-cancelled errors
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Silently handle cancelled requests - these are usually due to view lifecycle changes
                return
            }
            print("Error fetching most liked posts: \(error)")
        }
        
        isLoading = false
    }
}
