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
    @State private var authorName: String = "DockUI Team"

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
            isLiked: $isLiked
        )) {
            VStack(alignment: .leading) {
                if type == "image" {
                    Image(media)
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
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 160)
            .padding(3)
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
                DispatchQueue.main.async {
                    self.authorName = displayName
                }
            } else {
                DispatchQueue.main.async {
                    self.authorName = "Unknown Author"
                }
            }
        }
    }
}

#Preview {
    DesignCards(
        id: "123",
        media: "https://example.com/image.jpg",
        title: "Sample Title",
        authorUID: "sampleUID",
        description: "Sample description of the design.",
        codeSnippet: "Sample code snippet.",
        published: "2024-06-11",
        type: "image",
        tags: ["tag1", "tag2"]
    )
}
