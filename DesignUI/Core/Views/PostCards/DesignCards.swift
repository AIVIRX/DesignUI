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
    var showLikeButton: Bool = true // Whether to show the like button
    var showDeleteButton: Bool = false // Whether to show the delete button
    var onDelete: (() -> Void)? = nil // Delete action callback
    
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
    
    init(id: String, media: String, title: String, authorName: String, isVerified: Bool, description: String, codeSnippet: String, published: String, isLiked: Bool, isPremium: Bool = false, isComponent: Bool = false, showLikeButton: Bool = true, showDeleteButton: Bool = false, onDelete: (() -> Void)? = nil) {
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
        self.showLikeButton = showLikeButton
        self.showDeleteButton = showDeleteButton
        self.onDelete = onDelete
    }
    
    private var aspectRatio: CGFloat {
        // Components: horizontal/landscape (1.6 = width > height)
        // Templates: vertical/portrait (0.55 = height > width)
        isComponent ? 1.6 : 0.55
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
#if os(macOS)
            // macOS: Use ZStack to separate NavigationLink from LikeButton
            ZStack(alignment: .topTrailing) {
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
                    imageView
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accentColor(.clear)
                
                // Like/Delete button outside NavigationLink to prevent tap propagation
                if showLikeButton || isPremium || showDeleteButton {
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
                        }
                        if showLikeButton {
                            LikeButton(postId: id)
                        }
                        if showDeleteButton, let onDelete = onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(.black.opacity(0.8), in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    .contentShape(Capsule())
                    .allowsHitTesting(true)
                    .offset(x: -6, y: 6)
                }
            }
            .overlay(
                Color.white.opacity(isHovered ? 0.1 : 0)
                    .blendMode(.screen)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .allowsHitTesting(false)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .zIndex(isHovered ? 10 : 0)
            .onHover { hovering in
                isHovered = hovering
            }
#else
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
                imageView
                    .buttonStyle(PlainButtonStyle())
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.triggerImpact(style: .heavy)
            })
#endif
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
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
                        #if os(iOS)
                        if showLikeButton || isPremium || showDeleteButton {
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
                                }
                                if showLikeButton {
                                    LikeButton(postId: id)
                                }
                                if showDeleteButton, let onDelete = onDelete {
                                    Button(action: onDelete) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(6)
                            .background(.black.opacity(0.8), in: Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                            .padding(6)
                        }
                        #endif
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
            @unknown default:
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
        .onDisappear {
            SDImageCache.shared.clearMemory()
        }
    }
}
