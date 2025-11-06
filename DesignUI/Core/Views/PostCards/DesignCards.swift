//
//  DesignCards.swift
//  DockUI
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
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(width: 32, height: 32)
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
#endif
#if os(macOS)
                    // Templates: portrait style (up/down long) - aspect ratio < 1 (height > width)
                    // Components: landscape style (horizontal left/right) - aspect ratio > 1 (width > height)
                    let aspectRatio: CGFloat = isComponent ? 1.6 : 0.55
                    ZStack(alignment: .topTrailing) {
                        WebImage(url: URL(string: media)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        Color.clear
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            )
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
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray.opacity(0.5))
                                    )
                            }
                        }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.3))
                        .onDisappear {
                            SDImageCache.shared.clearMemory()
                        }
                        
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
                        .background(.thickMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .padding(6)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .contentShape(Rectangle())
                    .overlay(
                        Color.white.opacity(isHovered ? 0.1 : 0)
                            .blendMode(.screen)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    )
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                    .zIndex(isHovered ? 10 : 0)
                    .allowsHitTesting(true)
                    .onHover { hovering in
                        isHovered = hovering
                    }
#endif
                }
                .buttonStyle(PlainButtonStyle())
            }
#if os(macOS)
            .buttonStyle(PlainButtonStyle())
            .accentColor(.clear)
#endif
#if os(iOS)
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.triggerImpact(style: .heavy)
            })
#endif
        }
    }
}
