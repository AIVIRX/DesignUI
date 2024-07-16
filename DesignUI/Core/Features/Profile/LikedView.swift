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
    @Published var hasMorePosts: Bool = true

    private let db = Firestore.firestore()
    private let batchSize = 5
    
    struct Post: Identifiable {
        var id: String
        var title: String
        var description: String
        var mediaURL: String
        var author: String
        var creationDate: Timestamp
        var type: String
        var likesCount: Int
        var viewCount: Int
    }
    
    func fetchLikedPosts(reset: Bool = false) {
        guard let user = Auth.auth().currentUser else { return }
        
        if reset {
            likedPosts = []
            lastDocument = nil
            hasMorePosts = true
        }
        
        guard hasMorePosts else { return }
        
        isLoading = true
        
        var query: Query = db.collection("users").document(user.uid).collection("likedPosts").order(by: "timestamp", descending: true).limit(to: batchSize)
        
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
            
            if documents.count < self.batchSize {
                self.hasMorePosts = false
            }
            
            if let last = documents.last {
                self.lastDocument = last
            }
            
            let postIDs = documents.map { $0.documentID }
            self.fetchPostDetails(for: postIDs)
        }
    }
    
    private func fetchPostDetails(for postIDs: [String]) {
        let postRef = db.collection("posts")
        
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
                    let creationDate = data?["creationDate"] as? Timestamp ?? Timestamp(date: Date())
                    let type = data?["type"] as? String ?? "Unknown Type"
                    let likesCount = data?["likesCount"] as? Int ?? 0
                    let viewCount = data?["viewCount"] as? Int ?? 0
                    
                    let post = Post(id: id, title: title, description: description, mediaURL: mediaURL, author: author, creationDate: creationDate, type: type, likesCount: likesCount, viewCount: viewCount)
                    
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
                NavigationLink(destination: DetailView(id: post.id, mediaURL: post.mediaURL, title: post.title, description: post.description, author: post.author, codeSnippet: "", creationDate: formattedDate(from: post.creationDate), type: post.type, isLiked: $isLiked)) {
                    HStack {
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
                        VStack(alignment: .leading) {
                            Text(post.title)
                                .font(.title3).bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            Text(post.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "heart")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Text("\(post.likesCount)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "eye")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Text("\(post.viewCount)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .padding(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding([.vertical, .horizontal], 5)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .onAppear {
                        viewModel.fetchLikedPosts()
                    }
            } else if viewModel.likedPosts.isEmpty {
                VStack {
                    Text("No liked posts found.")
                        .font(.headline)
                    Image(systemName: "heart.slash")
                        .font(.system(size: 30))
                        .padding()
                }
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThickMaterial)
                .cornerRadius(8)
                .padding(.horizontal)
            } else if viewModel.hasMorePosts {
                Button(action: {
                    viewModel.fetchLikedPosts()
                }) {
                    Text("Load More")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            viewModel.fetchLikedPosts(reset: true)
        }
    }

    private func formattedDate(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

#Preview {
    LikedView()
}
