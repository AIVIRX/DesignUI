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
    @State private var query: String = ""
    @State private var suggestions: [String] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    private let db = Firestore.firestore()
    @State private var searchCancellable: AnyCancellable? = nil
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        performSearch(for: suggestion)
                    }) {
                        Text(suggestion)
                    }
                }
                .padding(.top, 100)
                
                ScrollView(.vertical){
                    VStack{
                        LargeCardView(name: "SF Symbols", height: 200, fontSize: 30, padding: 20, colors: [.cyan, .indigo, .purple, .red, .yellow], destination: SFIconsView())
                        
                        PostCollectionView(collectionName: "Most Liked", type: "mostLiked")
                        
                        PostCollectionView(collectionName: "Most Viewed", type: "mostViewed")
                    }
                }
                .padding(8)
                .padding(.top, 80)
                
                // Custom SearchBarView
                SearchBarView(searchText: $query)
                    .padding(.top, 10)
                
                
                // Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 150)
                }
            }
        }
    }

    // Fetch suggestions from Firestore based on the current query
    private func fetchSuggestions(for query: String) {
        isLoading = true
        errorMessage = nil
        
        // Perform a case-insensitive search for suggestions containing the query text
        db.collection("suggestions")
            .whereField("suggestion", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("suggestion", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
            .order(by: "popularityScore", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        errorMessage = "Error fetching suggestions: \(error.localizedDescription)"
                        suggestions = []
                    } else {
                        suggestions = snapshot?.documents.compactMap {
                            $0.data()["suggestion"] as? String
                        } ?? []
                    }
                }
            }
    }

    // Handle search action when a suggestion is clicked
    private func performSearch(for suggestion: String) {
        print("Searching for posts related to: \(suggestion)")
    }
}

#Preview {
    ExploreView()
}

struct PostCollectionView: View {
    @State private var postImages: [String] = []
    @State private var mostLikedPosts: [DesignPost] = []
    @State private var mostViewedPosts: [DesignPost] = []
    @State private var isLoading: Bool = false
    let db = Firestore.firestore()
    let collectionName: String
    let type: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(collectionName)
                .font(.title2).bold()
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: gridColumns) {
                    if type == "mostLiked" {
                        ForEach(Array(mostLikedPosts.enumerated()), id: \.offset) { index, post in
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
                            .frame(width: 200)
                            .aspectRatio(9/16, contentMode: .fit)
                            .cornerRadius(12)
                        }
                    }
                    if type == "mostViewed" {
                        ForEach(Array(mostViewedPosts.enumerated()), id: \.offset) { index, post in
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
                            .frame(width: 200)
                            .aspectRatio(9/16, contentMode: .fit)
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .frame(height: 360)
        }
        .task {
            if type == "mostLiked" {
                await fetchMostLikedPosts()
            }
             if type == "mostViewed"{
                await fetchMostViewedPosts()
            }
        }
    }
    
    func fetchMostLikedPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do{
            // Query to fetch only (5 posts)(public)(by date)
            let query = db.collection("posts")
                .whereField("visibility", isEqualTo: "public")
                .order(by: "likesCount", descending: true)
                .limit(to: 5)
            
            let querySnapshot = try await query.getDocuments()
            
            DispatchQueue.main.async {
                let newPosts = querySnapshot.documents.compactMap { document in
                    try? document.data(as: DesignPost.self)
                }
                self.mostLikedPosts.append(contentsOf: newPosts)
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }
    
    func fetchMostViewedPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do{
            // Query to fetch only (5 posts)(public)(by date)
            let query = db.collection("posts")
                .whereField("visibility", isEqualTo: "public")
                .order(by: "viewCount", descending: true)
                .limit(to: 5)
            
            let querySnapshot = try await query.getDocuments()
            
            DispatchQueue.main.async {
                let newPosts = querySnapshot.documents.compactMap { document in
                    try? document.data(as: DesignPost.self)
                }
                self.mostViewedPosts.append(contentsOf: newPosts)
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }
}

    
