//
//  DesignCards.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct DesignCards: View {
    var id: String
    var media: String
    var title: String
    var author: String
    var description: String
    var codeSnippet: String
    var published: String
    var type: String
    var tags: [String]?
    @State private var isLiked: Bool = false

    init(id: String, media: String, title: String, author: String, description: String, codeSnippet: String, published: String, type: String, tags: [String]?) {
        self.id = id
        self.media = media
        self.title = title
        self.author = author
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
            author: author,
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
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .scaledToFill()
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    HStack {
                        Text(author)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 160)
            .padding(3)
        }
    }
}
