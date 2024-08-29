//
//  SimilarPosts.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/25/24.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct SimilarPost: Identifiable {
    var id: String
    var title: String
    var mediaURL: String
    var description: String
    var authorUID: String // Store the UID of the author
    var authorName: String = "Unknown Author" // Add this to store the display name
    var isAuthorVerified: Bool = false // Add this to store the verification status
    var codeSnippet: String
    var creationDate: String
    var tags: [String]
    var type: String
}

struct SimilarPostsView: View {
    var currentPostId: String
    var tags: [String]
    @State private var isLiked: Bool = false
    @State private var similarPosts: [SimilarPost] = []
    var body: some View {
        VStack(alignment: .leading) {
            Text("Similar Posts")
                .font(.title2)
                .bold()
                .padding(.bottom, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(similarPosts) { post in
                        NavigationLink(destination: DetailView(
                            id: post.id,
                            mediaURL: post.mediaURL,
                            title: post.title,
                            description: post.description, // Fetch description from Firestore
                            author: post.authorName, // Fetches author from Firestore
                            codeSnippet: post.codeSnippet, // Fetches codeSnippet from Firestore
                            creationDate: post.creationDate, // Fetch creationDate from Firestore
                            type: post.type,
                            isAuthorVerified: false, // Fetch verification status from Firestore if needed
                            tags: post.tags,  // Fetch tags from Firestore if needed
                            isLiked: $isLiked, // Fetch like status from Firestore if needed
                            likes: 69,
                            views: 69
                        )) {
                            VStack(alignment:.leading){
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 380)
#if os(iOS)
                                    .frame(height: 280)
#endif
                                
#if os(macOS)
                                    .frame(height: 280)
#endif
                                
                                
#if os(iOS)
                                    .foregroundStyle(.thinMaterial)
#endif
                                
#if os(macOS)
                                    .foregroundStyle(Color.gray.opacity(0.2))
#endif
                                    .overlay{
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
                                VStack(alignment: .leading){
                                    Text(post.title)
                                        .font(.body).bold()
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .truncationMode(.tail)
                                    
                                    HStack {
                                        Text(post.authorName)
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                        
                                        if post.isAuthorVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 13))
                                                .foregroundColor(.blue)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .onAppear {
            fetchSimilarPosts(currentPostId: currentPostId, tags: tags) { posts in
                self.similarPosts = posts
            }
        }
    }
}

func fetchAuthorName(authorUID: String, completion: @escaping (String, Bool) -> Void) {
    let db = Firestore.firestore()
    let userDocRef = db.collection("users").document(authorUID)
    userDocRef.getDocument { document, error in
        if let document = document, document.exists {
            let data = document.data()
            let displayName = data?["displayName"] as? String ?? "Unknown Author"
            let isVerified = data?["isVerified"] as? Bool ?? false
            completion(displayName, isVerified)
        } else {
            completion("Unknown Author", false)
        }
    }
}

func fetchSimilarPosts(currentPostId: String, tags: [String], completion: @escaping ([SimilarPost]) -> Void) {
    let db = Firestore.firestore()
    let postsRef = db.collection("posts")

    postsRef
        .whereField("tags", arrayContainsAny: tags)
        .whereField("id", isNotEqualTo: currentPostId) // Exclude current post
        .limit(to: 3)  // Limit the number of similar posts fetched
        .getDocuments { querySnapshot, error in
            var similarPosts: [SimilarPost] = []

            if let documents = querySnapshot?.documents {
                let dispatchGroup = DispatchGroup()

                for document in documents {
                    let data = document.data()
                    let creationDateTimestamp = data["creationDate"] as? Timestamp ?? Timestamp(date: Date())
                    let creationDateString = formattedDate(from: creationDateTimestamp)
                    let authorUID = data["author"] as? String ?? ""
                    let post = SimilarPost(
                        id: document.documentID,
                        title: data["title"] as? String ?? "Untitled",
                        mediaURL: data["media"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        authorUID: authorUID, // Store the author UID
                        codeSnippet: data["codeSnippet"] as? String ?? "",
                        creationDate: creationDateString, // Use the formatted date string
                        tags: data["tags"] as? [String] ?? [""],
                        type: data["type"] as? String ?? ""
                    )

                    dispatchGroup.enter()
                    fetchAuthorName(authorUID: authorUID) { authorName, isVerified in
                        var updatedPost = post
                        updatedPost.authorName = authorName
                        updatedPost.isAuthorVerified = isVerified
                        similarPosts.append(updatedPost)
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(similarPosts)
                }
            } else {
                completion(similarPosts)
            }
        }
}



