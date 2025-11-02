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
    var isPremium: Bool
    var description: String
    var codeSnippet: String
    var published: String
    var isLiked: Bool
    var isComponent: Bool = false // New property to distinguish components
    
    @State private var isHovered: Bool = false
    @State private var isLikedByUser: Bool = false
    @State private var userId: String? = nil
    @StateObject private var viewModel = LatestPostsViewModel()
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
    
    init(id: String, media: String, title: String, authorName: String, isVerified: Bool, description: String, codeSnippet: String, published: String, isLiked: Bool, isPremium: Bool = false, isComponent: Bool = false) {
        self.id = id
        self.media = media
        self.title = title
        self.authorName = authorName
        self.isVerified = isVerified
        self.description = description
        self.codeSnippet = codeSnippet
        self.published = published
        self.isLiked = isLiked
        self.isPremium = isPremium
        self.isComponent = isComponent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: DetailView(
                id: id,
                mediaURL: media,
                title: title,
                description: description,
                author: authorName,
                codeSnippet: codeSnippet,
                creationDate: published,
                isAuthorVerified: isVerified,
                isPremium: isPremium
            )) {
                VStack(alignment: .leading, spacing: 8) {
#if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        // Templates: portrait style (up/down long) - aspect ratio < 1 (height > width)
                        // Components: landscape style (horizontal left/right) - aspect ratio > 1 (width > height)
                        let aspectRatio: CGFloat = isComponent ? 1.6 : 0.55
                        WebImage(url: URL(string: media)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        ProgressView()
                                    )
                            case .success(let image):
                                Color.clear
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .overlay(
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    )
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(alignment: .topTrailing) {
                                        HStack {
                                            if isPremium {
                                                Image(systemName: "sparkle")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.clear)
                                                    .overlay(
                                                        LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                                            .mask(
                                                                Image(systemName: "sparkle")
                                                                    .font(.system(size: 14, weight: .semibold))
                                                            )
                                                    )
                                                    .padding(.leading, 8)
                                            }
                                            LikeButton(postId: id)
                                        }
                                        .background(.thickMaterial, in: Capsule())
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                                        .padding(6)

                                    }
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray.opacity(0.5))
                                    )
                            }
                        }
                        .onDisappear {
                            SDImageCache.shared.clearMemory()
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
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                    .overlay(alignment: .topTrailing) {
                                        HStack(spacing: 6) {
                                            if isPremium {
                                                Image(systemName: "sparkle")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.clear)
                                                    .overlay(
                                                        LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                                            .mask(
                                                                Image(systemName: "sparkle")
                                                                    .font(.system(size: 14, weight: .semibold))
                                                            )
                                                    )
                                                    .padding(.leading, 8)
                                            }
                                            LikeButton(postId: id)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.trailing, 6)
                                        .background(.regularMaterial, in: Capsule())
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                                        .padding()
                                    }
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 420)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
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
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .overlay(alignment: .topTrailing) {
                                    HStack(spacing: 6) {
                                        if isPremium {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.clear)
                                                .overlay(
                                                    LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                                        .mask(
                                                            Image(systemName: "sparkles")
                                                                .font(.system(size: 14, weight: .semibold))
                                                        )
                                                )
                                                .padding(.leading, 8)
                                        }
                                        LikeButton(postId: id)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.trailing, 6)
                                    .background(.regularMaterial, in: Capsule())
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                                    .padding(12)
                                }
                                .scaleEffect(isHovered ? 1.02 : 1.0)
                                .colorMultiply(isHovered ? Color.white : Color(white: 0.94))
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
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .padding(.top)
                        }
                    }
#endif
                }
                .buttonStyle(PlainButtonStyle())
            }
#if os(iOS)
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.triggerImpact(style: .heavy)
            })
#endif
        }
    }
}
