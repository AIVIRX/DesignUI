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
    var tags: [String]
    var likes: Int
    var views: Int
    
    @State private var isHovered: Bool = false
    @State private var isLiked: Bool = false
    @State private var authorName: String = "DockUI Team"
    @State private var isAuthorVerified: Bool = false
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    
    init(id: String, media: String, title: String, authorUID: String, description: String, codeSnippet: String, published: String, type: String, tags: [String], likes: Int, views: Int) {
        self.id = id
        self.media = media
        self.title = title
        self.authorUID = authorUID
        self.description = description
        self.codeSnippet = codeSnippet
        self.published = published
        self.type = type
        self.tags = tags
        self.likes = likes
        self.views = views
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
            tags: tags,
            isLiked: $isLiked,
            likes: likes,
            views: views
        )) {
            VStack(alignment: .center) {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .foregroundStyle(.thickMaterial)
                        .overlay{
                            RoundedRectangle(cornerRadius: 15)
                                .frame(width: 115,height: 250)
                                .overlay{
                                    if type == "image" {
                                        Image(media)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity, maxHeight: 250)
                                            .frame(maxWidth: .infinity, maxHeight: 370)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .clipped()
                                            .shadow(radius: 8)
                                    }
                                    if type == "fetched" {
                                        WebImage(url: URL(string: media)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(maxWidth: .infinity, maxHeight: 350)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(maxWidth: .infinity, maxHeight: 250)
                                                    .frame(maxWidth: .infinity, maxHeight: 370)
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
                }
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if type == "image" {
                        Image(media)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 185, height: 400)
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
                                    .frame(width: 185, height: 400)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 185, height: 400)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray, lineWidth: 0.8)
                                    )
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 185, height: 400)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray, lineWidth: 0.8)
                                    )
                            }
                        }
                    }
                }
#endif
                
#if os(macOS)
                if type == "image" {
                    Image(media)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 185, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 0.8)
                        )
                        .scaleEffect(isHovered ? 1.02 : 1.0)
                        .colorMultiply(isHovered ? Color.white : Color(white: 0.95))
                        .animation(.easeInOut(duration: 0.2), value: isHovered)
                        .onHover { hovering in
                            isHovered = hovering
                        }
                        .padding(.top)
                }
                if type == "fetched" {
                    WebImage(url: URL(string: media)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 185, height: 400)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 185, height: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 0.8)
                                )
                                .scaleEffect(isHovered ? 1.02 : 1.0)  // Scale effect on hover
                                .colorMultiply(isHovered ? Color.white : Color(white: 0.95))
                                .animation(.easeInOut(duration: 0.2), value: isHovered)  // Animation
                                .background(Color.clear)  // Background to prevent clipping
                                .zIndex(isHovered ? 1 : 0)
                                .onHover { hovering in
                                    isHovered = hovering
                                }
                                .padding(.top)
                            
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 185, height: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 0.8)
                                )
                                .padding(.top)
                            
                        }
                    }
                }
#endif
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
                        
                        Text("\(likes)")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 6)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            //            #if os(iOS)
            //            .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 225)
            //            #endif
            
#if os(iOS)
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 3 : 10)
#endif
            
#if os(macOS)
            .padding(.horizontal, 10)
#endif
            .onAppear {
                if type == "fetched" {
                    fetchAuthorName()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        
#if os(iOS)
        .simultaneousGesture(TapGesture().onEnded {
            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
            impactHeavy.impactOccurred()
        })
#endif
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
        tags: ["tag1", "tag2"],
        likes: 420,
        views: 69420
    )
}
