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
    
    @State private var isHovered: Bool = false
    
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
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
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
                            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
                            .scaleEffect(isHovered ? 1.02 : 1.0)
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
            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .zIndex(isHovered ? 10 : 0)
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
                        .lineLimit(1)
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
                
                if post.post_type == "design" {
                    Button(action: {
                        onOpen?(post)
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .contentShape(Rectangle()) // Make the whole area hoverable/tappable
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 200)
            .overlay(
                WebImage(url: URL(string: media)) { image in
                    if !isComponent {
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
            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}
