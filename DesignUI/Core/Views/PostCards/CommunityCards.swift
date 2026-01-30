//
//  DesignCards.swift
//  DockUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct CommunityCards: View {
    let post: DesignPost
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil
    
    private var id: String { post.id }
    private var slug: String { post.slug }
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
    
    init(
        post: DesignPost,
        showDeleteButton: Bool = false,
        onDelete: (() -> Void)? = nil
    ) {
        self.post = post
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
                    slug: slug,
                    mediaURL: media,
                    title: title,
                    author: authorName,
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
                
                // Delete button outside NavigationLink to prevent tap propagation
                if isPremium || showDeleteButton {
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
            // Hover effect on the image
            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .zIndex(isHovered ? 10 : 0)
            
            // Title and Author Row
            HStack {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(authorName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 2)
            
#else
            NavigationLink(destination: DetailView(
                id: id,
                slug: slug,
                mediaURL: media,
                title: title,
                author: authorName,
                creationDate: published,
                isAuthorVerified: isVerified,
                isPremium: isPremium,
                isComponent: isComponent
            )) {
                VStack(alignment: .leading, spacing: 8) {
                    imageView
                    
                    HStack {
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(authorName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
            }
            .buttonStyle(PlainButtonStyle()) // Needed for proper tap behavior in lists
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.triggerImpact(style: .soft)
            })
#endif
        }
        .contentShape(Rectangle()) // Make the whole area hoverable/tappable
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        // Templates: portrait style (up/down long) - aspect ratio < 1 (height > width)
        // Components: landscape style (horizontal left/right) - aspect ratio > 1 (width > height)
        let aspectRatio: CGFloat = isComponent ? 1.6 : 0.55
        
        RippleImageView(mediaURL: media, aspectRatio: aspectRatio, cornerRadius: 12, showStroke: false) { location in
            // Optional: Handle logic on long press if needed
        }
        .id(media)
        .overlay(alignment: .topTrailing) {
            #if os(iOS)
            if isPremium || showDeleteButton {
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
    }
}
