//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import FirebaseFirestore
#if os(iOS)
import StatefulTabView
#endif
import SDWebImage
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var communityPosts: [DesignPost] = []
    @State private var lastFetchedDocument: DocumentSnapshot?
    @State private var hasMoreCommunityPosts = false
    @State private var isLoading: Bool = false
    @State private var searchText = ""
    @State private var showSearchResults = false
    @Environment(\.colorScheme) var colorScheme
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var isCommunityPostsLoaded = false
    private let postsLimit = 2
    var body: some View {
        NavigationStack {
            VStack {
                if isCommunityPostsLoaded && !communityPosts.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
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
                    }
                    .refreshable {
                        try? await Task.sleep(nanoseconds: UInt64(2.0) * 1_000_000_000)
                        
                        await fetchCommunityPosts(reset: true)
                    }
                } else if isLoading && communityPosts.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView("Loading posts...")
                        Spacer()
                    }
                    
                }
            }
            .frame(maxWidth: 1600)
            .navigationTitle("Home")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: HStack {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
            })
#endif
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                startAnimation = true
                opacity = 1.0
            }
            
            store.loadStoredPurchases()
        }
        .task {
            if !isCommunityPostsLoaded {
                //Delay of 2 seconds (specified in nanoseconds: 2 * 1_000_000_000)
                try? await Task.sleep(nanoseconds: UInt64(1) * 1_000_000_000)

                // Now fetch the posts
                await fetchCommunityPosts(reset: true)
                isCommunityPostsLoaded = true
            }
        }
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
            
            var query = db.collection("posts").whereField("visibility", isEqualTo: "public").order(by: "creationDate", descending: true).limit(to: postsLimit)
            
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

extension Bundle {
    /// Retrieves the build version number from the app's Info.plist.
    /// - Returns: A string representing the build version number, or nil if not found.
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

