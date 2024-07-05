//
//  LikedView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/13/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImage
import SDWebImageSwiftUI

class LikedPostsViewModel: ObservableObject {
    @Published var likedPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var lastDocument: DocumentSnapshot?

    private let db = Firestore.firestore()
    private let batchSize = 2
    
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
        ScrollView {
            ForEach(viewModel.likedPosts) { post in
                NavigationLink(destination: DetailView(id: post.id, mediaURL: post.mediaURL, title: post.title, description: post.description, author: post.author, codeSnippet: "", creationDate: post.creationDate, type: post.type, isLiked: $isLiked)) {
                        HStack{
                            WebImage(url: URL(string: post.mediaURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 130, height: 100)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 130, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary, lineWidth: 0.2)
                                        )
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 130, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary, lineWidth: 0.2)
                                        )
                                        .scaledToFill()
                                }
                            }
                            
                            VStack(alignment:.leading) {
                                Text(post.title)
                                    .font(.title3)
                                Text(post.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding()
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .onAppear {
                        viewModel.fetchLikedPosts()
                    }
            } else if viewModel.likedPosts.isEmpty {
                VStack{
                    Text("No liked posts found.")
                        .foregroundColor(.gray)
                    Image(systemName: "heart.slash")
                        .font(.system(size: 25))
                }
            } else {
                Button(action: {
                    viewModel.fetchLikedPosts()
                }) {
                    Text("Load More")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThickMaterial)
                        .cornerRadius(8)
                        .padding(.horizontal)
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
