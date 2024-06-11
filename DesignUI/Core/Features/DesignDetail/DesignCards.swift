//
//  DesignCards.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct DesignCards: View {
    var id: String
    var image: String
    var title: String
    var author: String
    var description: String
    var codeSnippet: String
    var published: String
    var type: DesignType
    @State private var designPost: DesignPost
    @State private var isLiked: Bool = false
    init(id: String, image: String, title: String, author: String, description: String, codeSnippet: String, published: String, type: DesignType) {
        self.id = id
        self.image = image
        self.title = title
        self.author = author
        self.description = description
        self.codeSnippet = codeSnippet
        self.published = published
        self.type = type
        self._designPost = State(initialValue: DesignPost(id: id, image: image, title: title, author: author, description: description, codeSnippet: codeSnippet, published: "", type: .image))
    }
    
    var body: some View {
        NavigationLink(destination: DetailView(id: id, imageURL: image, title: title, description: description, author: author, codeSnippet: codeSnippet, published: published, type: type, isLiked: $isLiked)) {
            // Your view content here
            VStack(alignment: .leading){
                
                if type == .image{
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .scaledToFill()
                }
                VStack(alignment: .leading){
                    Text(title)
                        .font(.headline)
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    HStack{
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
