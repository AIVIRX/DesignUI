//
//  CommunityPosts.swift
//  DockUI
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
    private var filterTask: Task<Void, Never>?
    private var currentSearchQuery: String? = nil // Track current search query for pagination
    
    @MainActor
    func loadMorePostsIfNeeded(currentItem item: DesignPost?) async {
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        // If we're in search mode, use search pagination
        if let query = currentSearchQuery, !query.isEmpty {
            await loadMoreSearchResultsIfNeeded(currentItem: item)
            return
        }
        
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
    func searchPosts(query: String, filterType: String? = nil, isAllPosts: Bool? = nil) async {
        guard !query.isEmpty else {
            // Reset to current filter if query is cleared
            currentSearchQuery = nil
            await refreshPosts(filterType: currentFilterType, isAllPosts: isAllPostsMode)
            return
        }
        
        // If search query changed, reset pagination
        if currentSearchQuery != query {
            currentPage = 0
            posts.removeAll()
            hasMorePosts = true
            currentSearchQuery = query
        }
        
        // Update filter state if provided
        if let filterType = filterType {
            currentFilterType = filterType
        }
        if let isAllPosts = isAllPosts {
            isAllPostsMode = isAllPosts
        }
        
        // Load search results with pagination (same as normal feed)
        await loadSearchResults(query: query, isInitialLoad: currentPage == 0)
    }
    
    @MainActor
    private func loadSearchResults(query: String, isInitialLoad: Bool) async {
        guard !isLoading && (isInitialLoad || hasMorePosts) else { return }
        
        // Cancel any existing task
        currentTask?.cancel()
        
        isLoading = true
        error = nil
        
        currentTask = Task {
            do {
                var queryBuilder = client
                    .from("posts")
                    .select("""
                        *,
                        profiles!posts_author_id_fkey (
                          username,
                          verified
                        )
                    """)
                    .eq("public", value: true)
                
                // Apply current filter if not in "all posts" mode
                if !isAllPostsMode {
                    if let filterType = currentFilterType {
                        queryBuilder = queryBuilder.eq("post_type", value: filterType)
                    } else {
                        // Templates: exclude components
                        queryBuilder = queryBuilder.or("post_type.neq.component,post_type.is.null")
                    }
                }
                
                // Add search filter
                queryBuilder = queryBuilder.or("title.ilike.%\(query)%,description.ilike.%\(query)%")
                
                // Use pagination like normal feed
                let response = try await queryBuilder
                    .order("created_at", ascending: false)
                    .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                    .execute()
                
                let newPosts = try JSONDecoder().decode([DesignPost].self, from: response.data)
                
                if isInitialLoad {
                    posts = newPosts
                } else {
                    posts.append(contentsOf: newPosts)
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
                print("Error searching posts: \(error)")
            }
            
            isLoading = false
            currentTask = nil
        }
        
        await currentTask?.value
    }
    
    @MainActor
    func loadMoreSearchResultsIfNeeded(currentItem item: DesignPost?) async {
        guard let query = currentSearchQuery, !query.isEmpty else { return }
        
        // Use same logic as loadMorePostsIfNeeded but for search
        guard !isLoading, !isRefreshing, hasMorePosts else { return }
        
        guard let item = item else {
            await loadSearchResults(query: query, isInitialLoad: false)
            return
        }
        
        // Load more when we're within the last 3 items
        let thresholdOffset = min(3, posts.count)
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: -thresholdOffset, limitedBy: posts.startIndex) ?? posts.startIndex
        if let itemIndex = posts.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            await loadSearchResults(query: query, isInitialLoad: false)
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
                    .select("""
                        *,
                        profiles!posts_author_id_fkey (
                          username,
                          verified
                        )
                    """)
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
        // Cancel any pending filter task
        filterTask?.cancel()
        
        // Cancel any in-flight fetch
        currentTask?.cancel()
        
        // Reset pagination and fetch fresh posts with filter
        currentPage = 0
        posts.removeAll()
        hasMorePosts = true
        currentFilterType = postType
        isAllPostsMode = isAllPosts
        currentSearchQuery = nil // Clear search when filter changes
        
        await fetchFilteredPosts(filterType: postType, isAllPosts: isAllPosts)
    }
    
    @MainActor
    func fetchPostsByTypeDebounced(postType: String?, isAllPosts: Bool, delay: TimeInterval = 0.3) async {
        // Cancel previous filter task if any
        filterTask?.cancel()
        
        filterTask = Task { @MainActor in
            // Wait for debounce delay
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Check if task was cancelled
            guard !Task.isCancelled else {
                // Ensure loading state is reset if cancelled
                if isLoading {
                    isLoading = false
                }
                return
            }
            
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
        
        // Await the task - it handles its own errors and loading state internally
        // Since Task<Void, Never> never throws, we can safely await without try
        if let task = filterTask {
            await task.value
        }
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
                .select("""
                    *,
                    profiles!posts_author_id_fkey (
                      username,
                      verified
                    )
                """)
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
        filterTask?.cancel()
        
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
