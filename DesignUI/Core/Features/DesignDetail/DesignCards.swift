//
//  DesignCards.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI
import FirebaseFirestore

struct DesignCards: View {
    var id: String
    var media: String
    var title: String
    var authorUID: String
    var description: String
    var codeSnippet: String
    var published: String
    var type: String
    var tags: [String]?
    @State private var isLiked: Bool = false
    @State private var authorName: String = "Dock UI Team"
    @State private var isAuthorVerified: Bool = false

    init(id: String, media: String, title: String, authorUID: String, description: String, codeSnippet: String, published: String, type: String, tags: [String]?) {
        self.id = id
        self.media = media
        self.title = title
        self.authorUID = authorUID
        self.description = description
        self.codeSnippet = codeSnippet
        self.published = published
        self.type = type
        self.tags = tags
    }
    
    var body: some View {
        NavigationLink(destination: DetailView(
            id: id,
            mediaURL: media,
            title: title,
            description: description,
            author: authorName,
            codeSnippet: codeSnippet,
            creationDate: published,
            type: type,
            isAuthorVerified: isAuthorVerified, 
            isLiked: $isLiked
        )) {
            VStack(alignment: .leading) {
                if type == "image" {
                    Image(media)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 139, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 0.8)
                        )
                }
                if type == "fetched" {
                    WebImage(url: URL(string: media)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 160, height: 130)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary, lineWidth: 0.2)
                                )
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary, lineWidth: 0.2)
                                )
                                .scaledToFill()
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body).bold()
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                    
                    HStack {
                        Text(authorName)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        if isAuthorVerified ||  type == "image"{
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 150)
            .padding(0)
            .onAppear {
                if type == "fetched" {
                    fetchAuthorName()
                }
            }
        }
    }
    
    func fetchAuthorName() {
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(authorUID)
        userDocRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let displayName = data?["displayName"] as? String ?? "Unknown Author"
                let isVerified = data?["isVerified"] as? Bool ?? false
                DispatchQueue.main.async {
                    self.authorName = displayName
                    self.isAuthorVerified = isVerified
                }
            } else {
                DispatchQueue.main.async {
                    self.authorName = "Unknown Author"
                    self.isAuthorVerified = false
                }
            }
        }
    }
}

#Preview {
    DesignCards(
        id: "123",
        media: "ArticleTemplate",
        title: "Sample Title",
        authorUID: "sampleUID",
        description: "Sample description of the design.",
        codeSnippet: "Sample code snippet.",
        published: "\(Timestamp(date: Date()))",
        type: "image",
        tags: ["tag1", "tag2"]
    )
}
