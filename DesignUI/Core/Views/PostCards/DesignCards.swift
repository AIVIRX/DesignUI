//
//  DesignCards.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

// MARK: - Reusable WebImage Component
struct OptimizedWebImage: View {
    let url: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let isHovered: Bool
    let showHoverEffects: Bool
    
    init(url: String, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 20, isHovered: Bool = false, showHoverEffects: Bool = false) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.isHovered = isHovered
        self.showHoverEffects = showHoverEffects
    }
    
    var body: some View {
        WebImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: width, height: height)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .modifier(HoverEffectsModifier(isHovered: isHovered, showEffects: showHoverEffects))
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
    }
}

// MARK: - Hover Effects Modifier
struct HoverEffectsModifier: ViewModifier {
    let isHovered: Bool
    let showEffects: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: isHovered && showEffects ? Color.black.opacity(0.15) : Color.black.opacity(0.08),
                radius: isHovered && showEffects ? 8 : 4,
                x: 0,
                y: isHovered && showEffects ? 4 : 2
            )
            .scaleEffect(isHovered && showEffects ? 1.02 : 1.0)
            .colorMultiply(isHovered && showEffects ? Color.white : Color(white: 0.94))
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .zIndex(isHovered && showEffects ? 1 : 0)
    }
}

struct DesignCards: View {
    let id: String
    let media: String
    let title: String
    let authorName: String
    let isVerified: Bool
    let description: String
    let codeSnippet: String
    let published: String
    let likesCount: Int
    let isLiked: Bool
    
    @State private var isHovered = false
    @State private var isVisible = false
    
    // MARK: - Computed Properties
    private var cardDimensions: (width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return (width: 185, height: 280, cornerRadius: 15)
        } else {
            return (width: 200, height: 430, cornerRadius: 20)
        }
        #else
        return (width: 185, height: 400, cornerRadius: 20)
        #endif
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
                // Optimized WebImage with platform-specific styling
                OptimizedWebImage(
                    url: media,
                    width: cardDimensions.width,
                    height: cardDimensions.height,
                    cornerRadius: cardDimensions.cornerRadius,
                    isHovered: isHovered,
                    showHoverEffects: true
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                // Card Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                    
                    // Author and Like Button
                    HStack {
                        Text(authorName)
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
                    .contentShape(Rectangle())
                }
                .frame(width: cardDimensions.width)
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
