//
//  DesignCards.swift
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
            macOSCard
#else
            iOSCard
#endif
            footer
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

    private var destinationView: some View {
        DetailView(
            id: id,
            slug: slug,
            mediaURL: media,
            title: title,
            author: authorName,
            isPremium: isPremium
        )
    }

    #if os(macOS)
    private var macOSCard: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: destinationView) {
                imageView
            }
            .buttonStyle(PlainButtonStyle())
            .accentColor(.clear)

            if isPremium || showDeleteButton {
                premiumDeleteBadge
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isImageHovered)
        .zIndex(isImageHovered ? 10 : 0)
    }
    #else
    private var iOSCard: some View {
        NavigationLink(destination: destinationView) {
            imageView
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.triggerImpact(style: .soft)
        })
    }
    #endif

    private var footer: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
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
                openButton
            }
        }
        .padding(.top, 2)
    }

    private var openButton: some View {
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

    #if os(macOS)
    private var premiumDeleteBadge: some View {
        HStack(spacing: 6) {
            if isPremium {
                crownIcon
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
    #endif

    private var crownIcon: some View {
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

    private var baseImageCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.secondary.opacity(0.1))
            .frame(height: 240)
            .overlay(remoteImageOverlay)
            .overlay(imageBorderOverlay)
    }
    
    private var remoteImageOverlay: some View {
        WebImage(url: URL(string: media)) { image in
            image
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .padding()
        } placeholder: {
            ProgressView()
                .frame(width: 30, height: 30)
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
    }
    
    private var imageBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
    }
    
#if os(macOS)
    private var imageView: some View {
        macImageView
    }
    
    private var macImageView: some View {
        baseImageCard
            .shadow(color: .black.opacity(isImageHovered ? 0.15 : 0.05), radius: isImageHovered ? 8 : 4, y: isImageHovered ? 4 : 2)
            .scaleEffect(isImageHovered ? 1.02 : 1.0)
            .onHover { hovering in
                isImageHovered = hovering
            }
    }
#else
    private var imageView: some View {
        iosImageView
    }
    
    private var iosImageView: some View {
        baseImageCard
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .overlay(alignment: .topTrailing) {
                if isPremium {
                    premiumBadge
                }
            }
    }
    
    private var premiumBadge: some View {
        crownIcon
            .padding(6)
            .background(.black.opacity(0.8), in: Capsule())
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
            .offset(x: -6, y: 6)
    }
#endif
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
    }
}
