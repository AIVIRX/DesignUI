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
    private let searchQuerySubject = PassthroughSubject<String, Never>()
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
                
                ScrollView{
                    VStack(alignment: .leading){
                        LargeCardView(name: "SF Symbols", height: 200, fontSize: 30, padding: 20, colors: [.cyan, .indigo, .purple, .red, .yellow], destination: SFIconsView())
                        
                        PostCollectionView(CollectionName: "Most Liked", type: "mostLiked")
                        
                        PostCollectionView(CollectionName: "Most Liked", type: "mostLiked")
                    }
                }
                .padding(8)
                .padding(.top, 80)
                
                // Custom SearchBarView
                SearchBarView(searchText: $query)
                    .padding(.top, 10)
                    .onChange(of: query) { oldValue, newValue in
                        searchQuerySubject.send(newValue)
                    }
                
                // Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 150) // Adjust based on your UI layout
                }
            }
        }
        .onAppear {
            setupDebounce()
        }
    }
    
    // Setup debounce mechanism using PassthroughSubject
    private func setupDebounce() {
        searchCancellable = searchQuerySubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) //ms between stop typing and fetching suggestions
            .sink { newValue in
                if !newValue.isEmpty {
                    fetchSuggestions(for: newValue)
                } else {
                    suggestions = []  // Directly access @State without needing self
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
        // You can navigate to a feed view or display posts related to the selected suggestion
        print("Searching for posts related to: \(suggestion)")
    }
}

#Preview {
    ExploreView()
}

struct PostCollectionView: View {
    @State var postImages: [String] = []
    let CollectionName: String
    let type: String
    var body: some View {
        VStack(alignment: .leading){
            Text(CollectionName)
                .font(.title2).bold()
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray)
                
                HStack(spacing: 1) {
                    ForEach(postImages.prefix(4), id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 200)
                                .colorMultiply(Color.white)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 90, height: 200)
                        }
                    }
                }
            }
            .frame(height: 195)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.black, lineWidth: 1)
            )
            .onTapGesture {
                showFullPostList()
            }
            .onAppear {
                if(type == "mostLiked"){
                    fetchMostLikedPosts()
                }
            }
        }
        .padding()
    }
    
    
    func fetchMostLikedPosts() {
        let db = Firestore.firestore()
        db.collection("posts")
            .order(by: "likesCount", descending: true)
            .limit(to: 4)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    postImages = documents.compactMap { document in
                        document.get("media") as? String
                    }
                }
            }
    }
    
    // Function to navigate to full post list
    func showFullPostList() {
        
    }
}
    
