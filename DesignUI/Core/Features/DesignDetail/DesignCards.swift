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
import FirebaseAuth

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
    var hexa: String
    
    @State private var isHovered: Bool = false
    @State private var isLiked: Bool = false
    @State private var authorName: String = "DockUI Team"
    @State private var isAuthorVerified: Bool = false
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var likesCount: Int = 0
    @State private var viewCount: Int = 0
    
    init(id: String, media: String, title: String, authorUID: String, description: String, codeSnippet: String, published: String, type: String, tags: [String], likes: Int, views: Int, hexa: String) {
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
        self.hexa = hexa
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
            views: views, 
            hexa: hexa
        )) {
            VStack(alignment: .center) {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .foregroundStyle(Color(hex: hexa))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray, lineWidth: 0.5) // Adjust the stroke color and width as needed
                        )
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
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        if isAuthorVerified ||  type == "image"{
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if type == "fetched"{
                            HStack{
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .gray)
                                    .font(.system(size: 15))
                                Text("\(formatCount(likesCount))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal,2)
                            
                            
#if os(iOS)
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                HStack{
                                    Image(systemName: "eye")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 15))
                                    Text("\(formatCount(viewCount))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal,2)
                            }
#endif
                        }
                    }
                }
                .padding(.bottom, 6)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
#if os(iOS)
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 10)
#endif
            
#if os(macOS)
            .padding(.horizontal, 10)
#endif
            .onAppear {
                if type == "fetched" {
                    fetchAuthorName()
                }
                fetchLikeStatusAndViewCount()
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
    
    func fetchLikeStatusAndViewCount() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userLikedPostRef = db.collection("users").document(user.uid).collection("likedPosts").document(id)
        let postRef = db.collection("posts").document(id)
        
        // Use Firestore's batch to get both documents
        var isLikedStatus = false
        var likesCount = 0
        var viewCount = 0
        
        // Fetch user liked status and post details in parallel
        userLikedPostRef.getDocument { likedDocument, error in
            if let likedDocument = likedDocument, likedDocument.exists {
                isLikedStatus = true
            } else {
                isLikedStatus = false
            }
            
            postRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data() {
                        if let likes = data["likesCount"] as? Int {
                            likesCount = likes
                        }
                        if let views = data["viewCount"] as? Int {
                            viewCount = views
                        }
                    }
                }
                
                // Update UI on the main thread
                DispatchQueue.main.async {
                    self.isLiked = isLikedStatus
                    self.likesCount = likesCount
                    self.viewCount = viewCount
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
        views: 69420,
        hexa: "#FFFFFF"
    )
}
