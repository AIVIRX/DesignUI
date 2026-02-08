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
    var onOpen: ((DesignPost) -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var id: String { post.id }
    private var slug: String { post.slug }
    private var media: String { post.preview_image_url }
    private var title: String { post.title }
    private var authorName: String { post.profiles.username }
    private var isVerified: Bool { post.profiles.verified }
    private var isPremium: Bool { post.isPremium == true }
    private var published: String { post.created_at }
    private var isComponent: Bool {
        let postType = post.post_type?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return postType == "component"
    }
    
    @State private var isImageHovered: Bool = false
    
    init(
        post: DesignPost,
        showDeleteButton: Bool = false,
        onOpen: ((DesignPost) -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.post = post
        self.showDeleteButton = showDeleteButton
        self.onOpen = onOpen
        self.onDelete = onDelete
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
                    VStack(alignment: .leading, spacing: 8) {
                        // Template Preview
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.secondary.opacity(0.05))
                            .frame(height: 240)
                            .overlay(
                                WebImage(url: URL(string: media)) { image in
                                    if !isComponent{
                                        image
                                            .renderingMode(.original)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .clipped()
                                            .padding()
                                    } else {
                                        image
                                            .renderingMode(.original)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .clipped()
                                            .padding()
                                    }
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 30, height: 30)
                                }
                                .indicator(.activity)
                                .transition(.fade(duration: 0.3))
                            )
                            .shadow(color: .black.opacity(isImageHovered ? 0.15 : 0.05), radius: isImageHovered ? 8 : 4, y: isImageHovered ? 4 : 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .scaleEffect(isImageHovered ? 1.02 : 1.0)
                            .onHover { hovering in
                                isImageHovered = hovering
                            }
                    }
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
            .animation(.easeInOut(duration: 0.2), value: isImageHovered)
            .zIndex(isImageHovered ? 10 : 0)
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
                }
            }
            .buttonStyle(PlainButtonStyle()) // Needed for proper tap behavior in lists
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.triggerImpact(style: .soft)
            })
#endif
            // Title, Author and Open Button Row
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(horizontalSizeClass == .compact ? 2 : 1)
                        .minimumScaleFactor(0.85)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(authorName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                        }
                    }
                }
                
                Spacer()
                
                if !post.isDesignEmpty {
                    Button(action: {
                        print(" CommunityCards: Load button tapped for \(post.title)")
                        onOpen?(post)
                    }) {
                        Text("Open")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue, in: Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .contentShape(Capsule())
                }
            }
            .padding(.top, 2)
        }
        .contentShape(Rectangle()) // Keep the whole card clickable
        #if os(macOS)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        #endif
    }
    
    @ViewBuilder
    private var imageView: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.secondary.opacity(0.05))
            .frame(height: 220)
            .overlay(
                WebImage(url: URL(string: media)) { image in
                    image
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .padding()
                } placeholder: {
                    ProgressView()
                        .frame(width: 30, height: 30)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
            )
            .shadow(
                color: .black.opacity(isImageHovered ? 0.2 : 0.1),
                radius: isImageHovered ? 16 : 8,
                x: 0,
                y: isImageHovered ? 8 : 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isImageHovered ? 1.02 : 1.0)
            #if os(macOS)
            .onHover { hovering in
                isImageHovered = hovering
            }
            #endif

    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
    }
}
