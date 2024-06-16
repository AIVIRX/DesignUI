//
//  LikedView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/13/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class LikedPostsViewModel: ObservableObject {
    @Published var likedPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var lastDocument: DocumentSnapshot?

    private let db = Firestore.firestore()
    private let batchSize = 1
    
    struct Post: Identifiable {
        var id: String
        var title: String
        var description: String
        var mediaURL: String
        var author: String
        var creationDate: String
        var type: String
    }
    
    func fetchLikedPosts(reset: Bool = false) {
        guard let user = Auth.auth().currentUser else { return }
        
        if reset {
            likedPosts = []
            lastDocument = nil
        }
        
        isLoading = true
        
        var query: Query = db.collection("users").document(user.uid).collection("likedPosts").limit(to: batchSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching liked posts: \(error)")
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.isLoading = false
                return
            }
            
            if let last = documents.last {
                self.lastDocument = last
            }
            
            let postIDs = documents.map { $0.documentID }
            self.fetchPostDetails(for: postIDs)
        }
    }
    
    private func fetchPostDetails(for postIDs: [String]) {
        let postRef = db.collection("CommunityPosts")
        
        let dispatchGroup = DispatchGroup()
        
        for postID in postIDs {
            dispatchGroup.enter()
            postRef.document(postID).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching post details: \(error)")
                    dispatchGroup.leave()
                    return
                }
                
                if let document = document, document.exists {
                    let data = document.data()
                    let id = document.documentID
                    let title = data?["title"] as? String ?? "No Title"
                    let description = data?["description"] as? String ?? "No Description"
                    let mediaURL = data?["media"] as? String ?? ""
                    let author = data?["author"] as? String ?? "Unknown Author"
                    let creationDate = data?["creationDate"] as? String ?? "Unknown Date"
                    let type = data?["type"] as? String ?? "Unknown Type"
                    
                    let post = Post(id: id, title: title, description: description, mediaURL: mediaURL, author: author, creationDate: creationDate, type: type)
                    
                    DispatchQueue.main.async {
                        if !self.likedPosts.contains(where: { $0.id == id }) {
                            self.likedPosts.append(post)
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
        }
    }
}

struct LikedView: View {
    @StateObject private var viewModel = LikedPostsViewModel()
    
    @State private var isLiked: Bool = true
    var body: some View {
        List {
            ForEach(viewModel.likedPosts) { post in
                NavigationLink(destination: DetailView(id: post.id, mediaURL: post.mediaURL, title: post.title, description: post.description, author: post.author, codeSnippet: "", creationDate: post.creationDate, type: post.type, isLiked: $isLiked)) {
                    VStack(alignment: .leading) {
                        Text(post.title)
                            .font(.headline)
                        Text(post.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .onAppear {
                        viewModel.fetchLikedPosts()
                    }
            } else if viewModel.likedPosts.isEmpty {
                Text("No liked posts found.")
                    .foregroundColor(.gray)
            } else {
                Button(action: {
                    viewModel.fetchLikedPosts()
                }) {
                    Text("Load More")
                }
            }
        }
        .onAppear {
            viewModel.fetchLikedPosts(reset: true)
        }
    }
}

#Preview {
    LikedView()
}
