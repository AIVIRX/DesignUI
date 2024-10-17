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
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    var isFetching: Bool = false
    let client = SupabaseManager.shared.client
    
    init() {
        Task {
            await fetchPosts()
        }
    }
    
    func fetchPosts() async {
        guard !isFetching else { return }
        isFetching = true
        
        do {
            if let currentUser = client.auth.currentUser?.id {
                // Fetching posts along with author profiles using the specific foreign key relationship
                let response = try await client
                    .from("posts")
                    .select("""
                        *,
                        author:profiles!posts_author_fkey (id, display_name, is_verified)
                        isLiked:likes(post_id, user_id).eq.\(currentUser)
                    """)
                    .range(from: currentPage * pageSize, to: (currentPage + 1) * pageSize - 1)
                    .execute()
                
                // Debug: Print the raw response data
                print("Raw response data: \(response.data)")
                
                // Decode the response into DesignPostWithProfile struct
                let designPostsWithProfiles = try JSONDecoder().decode([DesignPost].self, from: response.data)
                
                // Debug: Print the decoded posts with profiles
                print("Decoded posts with profiles: \(designPostsWithProfiles)")
                
                // Update the posts array on the main thread
                DispatchQueue.main.async {
                    self.posts.append(contentsOf: designPostsWithProfiles)
                    self.currentPage += 1
                    self.isFetching = false
                }
            }
        } catch {
            print("Error fetching posts: \(error)")
            isFetching = false
        }
    }
    
    
}
