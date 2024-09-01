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


struct LikedView: View {
    @StateObject private var viewModel = LikedPostsViewModel()
    @State private var isLiked: Bool = true
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(viewModel.likedPosts.enumerated()), id: \.element.id) { index, post in
                    NavigationLink(destination: DetailView(id: post.id, mediaURL: post.mediaURL, title: post.title, description: post.description, author: post.authorDisplayName, codeSnippet: post.snippet, creationDate: formattedDate(from: post.creationDate), type: post.type, isAuthorVerified: false, tags: post.tags, isLiked: $isLiked, likes: post.likesCount, views: post.viewCount, hexa: post.hexa)) {
                        VStack {
                            RoundedRectangle(cornerRadius: 15)
#if os(iOS)
                                .frame(height: 280)
#endif
#if os(macOS)
                                .frame(height: 280)
#endif
                                .foregroundStyle(.thinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
#if os(iOS)
                                        .frame(width: 115, height: 250)
#endif
#if os(macOS)
                                        .frame(width: 115, height: 250)
#endif
                                        .overlay {
                                            if post.type == "image" {
                                                Image(post.mediaURL)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
#if os(iOS)
                                                    .frame(maxWidth: .infinity, maxHeight: 250)
#endif
#if os(macOS)
                                                    .frame(maxWidth: .infinity, maxHeight: 250)
#endif
                                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                                    .clipped()
                                                    .shadow(radius: 8)
                                            } else if post.type == "fetched" {
                                                WebImage(url: URL(string: post.mediaURL)) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        ProgressView()
                                                            .frame(maxWidth: .infinity, maxHeight: 350)
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
#if os(iOS)
                                                            .frame(maxWidth: .infinity, maxHeight: 250)
#endif
#if os(macOS)
                                                            .frame(maxWidth: .infinity, maxHeight: 250)
#endif
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                            .clipped()
                                                            .shadow(radius: 8)
                                                    case .failure:
                                                        Image(systemName: "photo")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(maxWidth: .infinity, maxHeight: 250)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                            .clipped()
                                                            .shadow(radius: 8)
                                                    }
                                                }
                                            }
                                        }
                                }
                            VStack(alignment: .leading) {
                                Text(post.title)
                                    .font(.title3).bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text(post.authorDisplayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    HStack {
                                        Image(systemName: "heart")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                        Text("\(formatCount(post.likesCount))")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 3)
                                    
                                    HStack {
                                        Image(systemName: "eye")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                        Text("\(formatCount(post.viewCount))")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 3)
                                }
                                .padding(.bottom, 5)
                            }
                            .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
#if os(iOS)
                        .background(.ultraThickMaterial)
#endif
#if os(macOS)
                        .background(.gray.opacity(0.2))
#endif
                        .cornerRadius(15)
                        .padding([.vertical, .horizontal], 5)
                    }
#if os(macOS)
                    .buttonStyle(.plain)
#endif
                    .onAppear {
                        // Trigger the fetch for the next batch of posts when the last item appears
                        if index == viewModel.likedPosts.count - 1 && viewModel.hasMorePosts && !viewModel.isLoading {
                            print("Last post appeared, loading more posts...")
                            viewModel.fetchLikedPosts()
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            print("Initial fetch of liked posts.")
            viewModel.fetchLikedPosts(reset: true)
        }
    }
}

class LikedPostsViewModel: ObservableObject {
    @Published var likedPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var lastDocument: DocumentSnapshot?
    @Published var hasMorePosts: Bool = true
    private let db = Firestore.firestore()
    private let batchSize = 4
    
    struct Post: Identifiable, Equatable {
        var id: String
        var title: String
        var description: String
        var mediaURL: String
        var authorUID: String
        var authorDisplayName: String
        var creationDate: Timestamp
        var snippet: String
        var type: String
        var likesCount: Int
        var viewCount: Int
        var likeTimestamp: Timestamp
        var tags: [String]
        var hexa: String
    }
    
    func fetchLikedPosts(reset: Bool = false) {
        guard let user = Auth.auth().currentUser else { return }
        
        if reset {
            likedPosts = []
            lastDocument = nil
            hasMorePosts = true
        }
        
        guard hasMorePosts else {
            print("No more posts to load.")
            return
        }
        
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
                print("No documents found.")
                self.isLoading = false
                return
            }
            
            if documents.count < self.batchSize {
                self.hasMorePosts = false
            }
            
            if let last = documents.last {
                self.lastDocument = last
            }
            
            let likedPostInfos = documents.map { doc -> (String, Timestamp) in
                let postID = doc.documentID
                let likeTimestamp = doc.get("timestamp") as? Timestamp ?? Timestamp(date: Date())
                return (postID, likeTimestamp)
            }
            
            self.fetchPostDetails(for: likedPostInfos)
        }
    }
    
    private func fetchPostDetails(for likedPostInfos: [(postID: String, likeTimestamp: Timestamp)]) {
        let postRef = db.collection("posts")
        
        let dispatchGroup = DispatchGroup()
        
        for (postID, likeTimestamp) in likedPostInfos {
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
                    let authorUID = data?["author"] as? String ?? "Unknown Author"
                    let creationDate = data?["creationDate"] as? Timestamp ?? Timestamp(date: Date())
                    let type = data?["type"] as? String ?? "Unknown Type"
                    let snippet = data?["codeSnippet"] as? String ?? ""
                    let likesCount = data?["likesCount"] as? Int ?? 0
                    let viewCount = data?["viewCount"] as? Int ?? 0
                    let tags = data?["tags"] as? [String] ?? [""]
                    let hexa = data?["hexa"] as? String ?? ""
                    
                    self.fetchAuthorName(for: authorUID) { authorDisplayName in
                        let post = Post(id: id, title: title, description: description, mediaURL: mediaURL, authorUID: authorUID, authorDisplayName: authorDisplayName, creationDate: creationDate, snippet: snippet, type: type, likesCount: likesCount, viewCount: viewCount, likeTimestamp: likeTimestamp, tags: tags, hexa: hexa)
                        
                        DispatchQueue.main.async {
                            if !self.likedPosts.contains(where: { $0.id == id }) {
                                self.likedPosts.append(post)
                                print("Post added: \(post.title)")
                                // Sort the likedPosts array after adding a new post based on likeTimestamp
                                self.likedPosts.sort { $0.likeTimestamp.dateValue() > $1.likeTimestamp.dateValue() }
                            }
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
            print("Finished loading posts.")
        }
    }
    
    private func fetchAuthorName(for uid: String, completion: @escaping (String) -> Void) {
        let userDocRef = db.collection("users").document(uid)
        userDocRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let displayName = data?["displayName"] as? String ?? "Unknown Author"
                completion(displayName)
            } else {
                completion("Unknown Author")
            }
        }
    }
}


#Preview {
    LikedView()
}
