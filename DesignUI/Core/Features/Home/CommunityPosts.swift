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
    func fetchPosts() async {
        guard !isLoading && hasMorePosts && !isRefreshing else { return }
        
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
                .order("created_at", ascending: false)
                .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                .execute()
            
            let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
            
            posts.append(contentsOf: newPosts)
            currentPage += 1
            hasMorePosts = newPosts.count == pageSize
        } catch {
            self.error = error
            print("Error fetching posts: \(error)")
        }
        
        isLoading = false
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
            print("Error refreshing posts: \(error)")
        }
        
        isRefreshing = false
    }
}
