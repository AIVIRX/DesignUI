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
    var authorUID: String
    var authorName: String
    var isVerified: Bool
    var description: String
    var codeSnippet: String
    var published: String
    var likes: Int
    var views: Int
    var hexa: String
    var visibility: String
    
    @State private var isHovered: Bool = false
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var likesCount: Int = 0
    @State private var viewCount: Int = 0
    @State private var isVisible = false
    @State private var isLiked = false
    let client = SupabaseManager.shared.client
    @StateObject private var viewModel = LatestPostsViewModel()
    
    init(id: String, media: String, title: String, authorUID: String, authorName:String, isVerified: Bool, description: String, codeSnippet: String, published: String, likes: Int, views: Int, hexa: String, visibility: String) {
        self.id = id
        self.media = media
        self.title = title
        self.authorUID = authorUID
        self.authorName = authorName
        self.isVerified = isVerified
        self.description = description
        self.codeSnippet = codeSnippet
        self.published = published
        self.likes = likes
        self.views = views
        self.hexa = hexa
        self.visibility = visibility
    }
    
    var body: some View {
        NavigationLink(destination: DetailView(
            id: id,
            mediaURL: media,
            title: title,
            description: description,
            author: authorName,
            authorUID: authorUID,
            codeSnippet: codeSnippet,
            creationDate: published,
            isAuthorVerified: isVerified,
            isLiked: isLiked,
            likes: likes,
            views: views,
            hexa: hexa,
            visibility: visibility
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
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .overlay{
                            RoundedRectangle(cornerRadius: 15)
                                .frame(width: 115,height: 250)
                                .overlay{
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
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .clipped()
                                                .shadow(radius: 8)
                                                .onDisappear {
                                                    SDImageCache.shared.clearMemory()
                                                }
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity, maxHeight: 250)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .clipped()
                                                .shadow(radius: 8)
                                        }
                                        
                                    }
                                }
                        }
                }
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    WebImage(url: URL(string: media)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 200, height: 420)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 430)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 0.8)
                                )
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 420)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 0.8)
                                )
                        }
                    }
                }
#endif
                
#if os(macOS)
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
#endif
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 16).bold())
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                    
                    HStack {
                        Text(authorName)
                            .font(.system(size: 14)).bold()
                            .foregroundColor(.secondary)
                        
                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        HStack{
                            Image(systemName: "heart.fill")
                                .foregroundColor(isLiked ? .red : .gray)
                                .font(.system(size: 16))
                            Text("\(formatCount(likes))")
                                .font(.subheadline).bold()
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal,2)
#if os(iOS)
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            HStack{
                                Image(systemName: "eye")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                Text("\(formatCount(views))")
                                    .font(.subheadline).bold()
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal,2)
                        }
#endif
                    }
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onHover { hovering in
                        isHovered = hovering
                    }
                }
                .opacity(isVisible ? 1 : 0)
#if os(iOS)
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 10)
#endif
                
#if os(macOS)
                .padding(.horizontal, 10)
#endif
                .onAppear {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isVisible = true
                    }
                    
                    
                    if let userID = client.auth.currentUser?.id.uuidString {
                        Task{
                            await checkIfLiked(postID: id, userID: userID)
                        }
                    }
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
    
    func checkIfLiked(postID: String, userID: String) async {
        do {
            let response = try await client
                .from("likes")
                .select("*", head: true, count: .exact)
                .eq("post_id", value: postID)
                .eq("user_id", value: userID)
                .execute()
            
            print("Response: \(response)")  // Print the entire response for debugging
            
            if response.count ?? 0 > 0 {
                isLiked = true
                print("Count is greater than 0: Liked Set to true")
            } else {
                isLiked = false
                print("Count is 0: Liked Set to false")
            }
        } catch {
            print("Error checking if post is liked: \(error)")
            isLiked = false
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
