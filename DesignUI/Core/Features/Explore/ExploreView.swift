//
//  ExploreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI
import Combine
import Firebase
import SDWebImage
import SDWebImageSwiftUI

struct ExploreView: View {
    private let db = Firestore.firestore()
    @State private var query: String = ""
    @State private var suggestions: [String] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchCancellable: AnyCancellable? = nil
    @State private var selectedTag: String? = "All"
    @State private var isExplorePostsLoaded = false
    @State private var communityPosts: [DesignPost] = []
    @State private var lastFetchedDocument: DocumentSnapshot?
    @State private var hasMoreCommunityPosts = false
    private let postsLimit = 2
    let availableTags = [ "All", "Animation", "Component", "Template"]
    @State private var debounceWorkItem: DispatchWorkItem? // For debouncing
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: true){
                    LargeCardView(name: "SF Symbols", height: 200, fontSize: 30, padding: 20, colors: [.cyan, .indigo, .purple, .red, .yellow], destination: SFIconsView())
                    
                    
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(availableTags, id: \.self) { tag in
                                    Button(action: {
                                        handleTagChange(tag) // Handle debounced tag change
                                    }) {
                                        Text(tag)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedTag == tag ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedTag == tag ? Color.blue : Color.primary)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedTag == tag ? Color.blue : Color.clear, lineWidth: 3)
                                            )
                                    }
                                    .animation(.easeInOut, value: selectedTag)
                                }
                            }
                            .padding(16)
                        }
                        .padding(-16)
                    
                    if isExplorePostsLoaded && !communityPosts.isEmpty {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(Array(communityPosts.enumerated()), id: \.offset) { index, post in
                                DesignCards(
                                    id: post.id,
                                    media: post.media,
                                    title: post.title,
                                    authorUID: post.author,
                                    description: post.description,
                                    codeSnippet: post.codeSnippet,
                                    published: formattedDate(from: post.creationDate),
                                    type: post.type,
                                    tags: post.tags,
                                    likes: post.likesCount,
                                    views: post.viewCount,
                                    hexa: post.hexa,
                                    visibility: post.visibility
                                )
                                .frame(maxWidth: .infinity)
                                .aspectRatio(9/16, contentMode: .fit)
                                .cornerRadius(12)
                                .clipped()
                                .onAppear {
                                    if index == communityPosts.count - 1 {
                                        loadMorePostsIfNeeded()
                                    }
                                }
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .frame(width: 185, height: 400)
                            }
                        }
                        .padding(.horizontal)
                    } else if isLoading && communityPosts.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading posts...")
                            Spacer()
                        }
                    }
                }
                .refreshable {
                    try? await Task.sleep(nanoseconds: UInt64(2.0) * 1_000_000_000)
                    
                    await fetchCommunityPosts(reset: true)
                }
            }
            .task {
                if !isExplorePostsLoaded {
                    //Delay of 2 seconds (specified in nanoseconds: 2 * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: UInt64(1) * 1_000_000_000)
                    
                    // Now fetch the posts
                    await fetchCommunityPosts(reset: true)
                    isExplorePostsLoaded = true
                }
            }
        }
    }
    
    // Handle debounced tag change
    private func handleTagChange(_ tag: String) {
        debounceWorkItem?.cancel() // Cancel any previous debounce work
        
        selectedTag = tag // Update the selected tag immediately for UI
        
        let workItem = DispatchWorkItem {
            Task {
                await fetchCommunityPosts(reset: true) // Fetch posts after delay
                isExplorePostsLoaded = true
            }
        }
        
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem) // Debounce with 1 sec delay
    }
    
    private func loadMorePostsIfNeeded() {
        guard hasMoreCommunityPosts && !isLoading else { return }
        Task {
            await fetchCommunityPosts()
        }
    }
    
    private func fetchCommunityPosts(reset: Bool = false) async {
        let db = Firestore.firestore()
        
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if reset {
                lastFetchedDocument = nil
                communityPosts.removeAll()
                print("Resetting community posts...")
            }
            
            var query =
            if let tag = selectedTag, tag != "All" {
                db.collection("posts")
                    .whereField("tags", arrayContains: tag)
                    .whereField("visibility", isEqualTo: "public")
                    .order(by: "creationDate", descending: true)
                    .limit(to: postsLimit)
            } else {
                db.collection("posts")
                    .whereField("visibility", isEqualTo: "public")
                    .order(by: "creationDate", descending: true)
                    .limit(to: postsLimit)
            }
            
            if let lastDocument = lastFetchedDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let querySnapshot = try await query.getDocuments()
            if querySnapshot.documents.isEmpty {
                DispatchQueue.main.async {
                    self.hasMoreCommunityPosts = false
                }
                print("No more posts to load.")
                return
            }
            
            DispatchQueue.main.async {
                self.lastFetchedDocument = querySnapshot.documents.last
                let newPosts = querySnapshot.documents.compactMap { document in
                    try? document.data(as: DesignPost.self)
                }
                
                self.communityPosts.append(contentsOf: newPosts)
                
                // Log the newly added posts
                for post in newPosts {
                    print("Loaded post: \(post.title) by \(post.author) with ID: \(post.id)")
                }
                
                self.hasMoreCommunityPosts = querySnapshot.documents.count == postsLimit
                print("Fetched \(querySnapshot.documents.count) posts.")
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }
}

#Preview {
    ExploreView()
}
    
