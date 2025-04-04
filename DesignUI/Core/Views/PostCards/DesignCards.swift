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
    var authorName: String
    var isVerified: Bool
    var description: String
    var codeSnippet: String
    var published: String
    var likesCount: Int
    var isLiked: Bool
    
    @State private var isHovered: Bool = false
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var isVisible = false
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var isLikedByUser: Bool = false
    @State private var userId: String? = nil
    
    let client = SupabaseManager.shared.client

    func checkIfUserLikedPost() async {
        guard let userId = userId else { return }
        
        do {
            let result = try await client
                .from("likes")
                .select()
                .eq("user_id", value: userId)
                .eq("post_id", value: id)
                .execute()
                .data
            
            DispatchQueue.main.async {
                isLikedByUser = !result.isEmpty
            }
        } catch {
            print("Error checking like status: \(error)")
        }
    }
    
    init(id: String, media: String, title: String, authorName: String, isVerified: Bool, description: String, codeSnippet: String, published: String, likesCount: Int, isLiked: Bool) {
        self.id = id
        self.media = media
        self.title = title
        self.authorName = authorName
        self.isVerified = isVerified
        self.description = description
        self.codeSnippet = codeSnippet
        self.published = published
        self.likesCount = likesCount
        self.isLiked = isLiked
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
            isAuthorVerified: isVerified
        )) {
            VStack(alignment: .center) {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .foregroundStyle(.regularMaterial)
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
                            .scaleEffect(isHovered ? 1.02 : 1.0)
                            .colorMultiply(isHovered ? Color.white : Color(white: 0.93))
                            .animation(.easeInOut(duration: 0.2), value: isHovered)
                            .background(Color.clear)
                            .zIndex(isHovered ? 1 : 0)
                            .onHover { hovering in
                                isHovered = hovering
                            }
                            .padding(.top, 5)
                        
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
                    Text(title).bold()
                        .font(.system(size: 16))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                    
                    HStack {
                        Text("@\(authorName)")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        LikeButton(
                            postId: id,
                            initialLikeCount: likesCount
                        )
                    }
                    .padding(.bottom, 5)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onHover { hovering in
                        isHovered = hovering
                    }
                }
                .padding(.top, 1)
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isVisible = true
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
#if os(iOS)
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.triggerImpact(style: .heavy)
        })
#endif
    }
}
