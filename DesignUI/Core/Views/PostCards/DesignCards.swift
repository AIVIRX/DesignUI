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
    let post: DesignPost
    var showLikeButton: Bool = true
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil
    
    // Computed properties for cleaner access
    private var id: String { post.id }
    private var media: String { post.preview_image_url }
    private var title: String { post.title }
    private var authorName: String { post.profiles.username }
    private var isVerified: Bool { post.profiles.verified }
    private var isPremium: Bool { post.isPremium == true }
    private var description: String { post.description }
    private var codeSnippet: String { post.code_snippet }
    private var published: String { post.created_at }
    private var isComponent: Bool {
        let postType = post.post_type?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return postType == "component"
    }
    
    @State private var isHovered: Bool = false
    @State private var isLikedByUser: Bool = false
    @State private var userId: String? = nil
    let client = SupabaseManager.shared.client
    
    init(
        post: DesignPost,
        showLikeButton: Bool = true,
        showDeleteButton: Bool = false,
        onDelete: (() -> Void)? = nil
    ) {
        self.post = post
        self.showLikeButton = showLikeButton
        self.showDeleteButton = showDeleteButton
        self.onDelete = onDelete
    }
    
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
                    isPremium: isPremium,
                    isComponent: isComponent
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
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.clear)
                                .overlay(
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                                        .mask(
                                            Image(systemName: "crown.fill")
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
                isPremium: isPremium,
                isComponent: isComponent
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
        // Calculate max size based on screen size to reduce memory usage
        #if os(iOS)
        let maxWidth = min(UIScreen.main.bounds.width * 2, 800) // 2x for retina, but cap at 800px
        #else
        let maxWidth: CGFloat = 800 // Mac: reasonable max width
        #endif
        
        WebImage(url: URL(string: media)) { image in
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
                                Image(systemName: "crown.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.clear)
                                        .overlay(
                                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                                                .mask(
                                                Image(systemName: "crown.fill")
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
        } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
        .id(media)
    }
}
