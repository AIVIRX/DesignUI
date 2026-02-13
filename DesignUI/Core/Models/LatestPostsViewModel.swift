//
//  CommunityPosts.swift
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
    @Published var isRefreshing = false
    
    private var currentPage: Int = 0
    private let pageSize: Int = 6
    private let client = SupabaseManager.shared.client
    private var lastRefreshTime: Date?
    private let refreshCooldown: TimeInterval = 1
    private var currentTask: Task<Void, Never>?
    
    // Memory management: Keep max 150 items, remove oldest when limit reached
    private let maxItemsInMemory: Int = 150
    private let itemsToRemoveWhenFull: Int = 50
    
    // Lightweight query for feed - excludes code_snippet and description to save memory
    private let feedSelectQuery = """
        id,
        slug,
        preview_image_url,
        title,
        created_at,
        isPremium,
        post_type,
        status,
        public,
        design_json,
        profiles!posts_author_id_fkey (
          username,
          verified
        )
    """
    
    @MainActor
    func loadMorePostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        guard let item = item else {
            await fetchPosts(postType: currentFilterType)
            return
        }
        
        // Load more when we're within the last 3 items
        let thresholdOffset = min(3, posts.count)
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: -thresholdOffset, limitedBy: posts.startIndex) ?? posts.startIndex
        if let itemIndex = posts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            await fetchPosts(postType: currentFilterType)
        }
    }
    
    @MainActor
    func fetchPosts(postType: String? = nil) async {
        // Don't block on isRefreshing - allow pagination after refresh completes
        guard !isLoading && hasMorePosts else { return }
        
        // Cancel any existing task
        currentTask?.cancel()
        
        isLoading = true
        error = nil
        
        currentTask = Task {
            do {
                var query = client
                    .from("posts")
                    .select(feedSelectQuery)
                    .eq("public", value: true)
                
                // Apply filter based on current mode
                let filterType = postType ?? currentFilterType
                if isAllPostsMode {
                    // No filter - fetch all posts
                } else if let filterType = filterType {
                    query = query.eq("post_type", value: filterType)
                } else {
                    // Templates: exclude components
                    query = query.or("post_type.neq.component,post_type.is.null")
                }
                
                let response = try await query
                    .order("created_at", ascending: false)
                    .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                    .execute()
                
                let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
                
                posts.append(contentsOf: newPosts)
                
                // Memory management: Remove oldest items if we exceed the limit
                if posts.count > maxItemsInMemory {
                    let itemsToRemove = min(itemsToRemoveWhenFull, posts.count - maxItemsInMemory)
                    posts.removeFirst(itemsToRemove)
                }
                
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
    
    private var isAllPostsMode: Bool = true
    
    @MainActor
    func fetchPostsByType(postType: String?, isAllPosts: Bool = false) async {
        // Cancel any in-flight fetch
        currentTask?.cancel()
        
        // Reset pagination and fetch fresh posts with filter
        currentPage = 0
        posts.removeAll()
        hasMorePosts = true
        currentFilterType = postType
        isAllPostsMode = isAllPosts
        
        await fetchFilteredPosts(filterType: postType, isAllPosts: isAllPosts)
    }
    
    @MainActor
    private func fetchFilteredPosts(filterType: String?, isAllPosts: Bool) async {
        // Allow this to run during refresh
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // Use defer to ensure isLoading is always reset, even if cancelled
        defer {
            isLoading = false
        }
        
        do {
            var query = client
                .from("posts")
                .select(feedSelectQuery)
                .eq("public", value: true)
            
            if isAllPosts {
                // Fetch all posts - no post_type filter
                // Don't add any post_type filter
            } else if let filterType = filterType {
                // Filter for specific post_type (e.g., "component")
                query = query.eq("post_type", value: filterType)
            } else {
                // For templates: exclude components (post_type is NOT "component" or is null)
                query = query.or("post_type.neq.component,post_type.is.null")
            }
            
            let response = try await query
                .order("created_at", ascending: false)
                .range(from: 0, to: pageSize - 1)
                .execute()
            
            // Check for cancellation before processing results
            try Task.checkCancellation()
            
            let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
            posts = newPosts
            currentPage = 1
            hasMorePosts = newPosts.count == pageSize
            
            // Continue loading if needed
            // Only skip if we're in the middle of a refresh (will be handled after refresh completes)
            if hasMorePosts && !isRefreshing {
                await fetchPosts(postType: filterType)
            }
        } catch {
            // Check if it's a cancellation error
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return // Silently handle cancelled requests
            }
            if error is CancellationError {
                return // Silently handle cancellation
            }
            
            self.error = error
            print("Error fetching filtered posts: \(error)")
        }
    }
    
    private var currentFilterType: String? = nil
    
    @MainActor
    func refreshPosts(filterType: String? = nil, isAllPosts: Bool? = nil) async {
        guard !isRefreshing else { return }
        
        let now = Date()
        if let lastRefresh = lastRefreshTime,
           now.timeIntervalSince(lastRefresh) < refreshCooldown {
            return
        }
        
        isRefreshing = true
        lastRefreshTime = now
        
        // Cancel any in-flight fetch
        currentTask?.cancel()
        
        // Reset pagination state completely
        currentPage = 0
        hasMorePosts = true
        
        if let filterType = filterType {
            currentFilterType = filterType
        }
        if let isAllPosts = isAllPosts {
            isAllPostsMode = isAllPosts
        }
        error = nil
        
        // Store current posts as backup
        let previousPosts = posts
        
        await fetchFilteredPosts(filterType: filterType ?? currentFilterType, isAllPosts: isAllPosts ?? isAllPostsMode)
        
        // Only restore if fetch failed and we have an error
        if error != nil && posts.isEmpty {
            posts = previousPosts
            hasMorePosts = true // Ensure pagination can continue even after error
        }
        
        isRefreshing = false
        
        // After refresh completes, continue loading more posts if available
        // This ensures pagination works after refresh
        if hasMorePosts && !isLoading {
            await fetchPosts(postType: filterType ?? currentFilterType)
        }
    }
}

// MARK: - Fetch Full Post Details
/// Fetches complete post data including code_snippet and description
/// Used by DetailView to lazy-load heavy content
enum PostFetcher {
    private static let client = SupabaseManager.shared.client
    
    static func fetchPostDetails(id: String) async throws -> DesignPost {
        let response = try await client
            .from("posts")
            .select("""
                id,
                slug,
                preview_image_url,
                title,
                description,
                code_snippet,
                created_at,
                isPremium,
                post_type,
                status,
                design_json,
                profiles!posts_author_id_fkey (
                  username,
                  verified
                )
            """)
            .eq("id", value: id)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DesignPost.self, from: response.data)
    }
}
