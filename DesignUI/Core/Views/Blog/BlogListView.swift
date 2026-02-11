//
//  BlogListView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import FluidGradient
import SDWebImage
import SDWebImageSwiftUI

struct NewsListView: View {
    @StateObject var viewModel = NewsViewModel()
    
    var columns: [GridItem] {
        return [GridItem(.adaptive(minimum: 300, maximum: 300))]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    NewsHeroHeaderView()
                        .padding(.horizontal)
                        .padding(.top, 16)
                    let gridPosts = Array(viewModel.posts)
                    if !gridPosts.isEmpty {
                        LazyVGrid(columns: columns) {
                            ForEach(gridPosts) { post in
                                NavigationLink(destination: NewsDetailView(post: post)) {
                                    BlogGridCard(post: post)
                                        .padding(.vertical, 5)
                                        .animation(.easeInOut(duration: 0.15), value: post.id)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(maxWidth: 1800)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 24)
                    } else {
                        VStack(spacing: 8) {
                            Text("No posts found")
                                .font(.headline)
                            Text(viewModel.errorMessage ?? "Check back soon for updates.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)
                    }
                }
                .frame(maxWidth: .infinity)
                .navigationTitle("News")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .refreshable {
                await viewModel.fetchNews()
            }
            .task {
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    await viewModel.fetchNews()
                }
            }
        }
    }
}

struct NewsHeroHeaderView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        
        ZStack {
            FluidGradient(blobs: [.purple, .blue, .cyan],
                          speed: 0.4,
                          blur: 0.75)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            
            Text("Newsroom")
                .font(.system(size: isCompact ? 32 : 44, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: isCompact ? 190 : 220)
    }
}

struct BlogGridCard: View {
    let post: NewsPost
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var cardWidth: CGFloat {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return min(UIScreen.main.bounds.width * 0.9, 480)
        } else {
            // iPad: use same as Mac
            return 280
        }
#else
        return 300
#endif
    }
    
    var cardHeight: CGFloat {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 220
        } else {
            // iPad: use same as Mac
            return 150
        }
#else
        return 169
#endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlString = post.image_url, let url = URL(string: urlString) {
                WebImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth, height: cardHeight)
                            .scaleEffect(isHovered ? 1.05 : 1.0)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isHovered)
                } placeholder: {
                    ProgressView()
                            .frame(width: cardWidth, height: cardHeight)
                }
                .cornerRadius(12)
                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isHovered)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .cornerRadius(12)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isHovered)
            }
            Text(post.title)
                #if os(macOS)
                .font(.title2).bold()
                #else
                .font(.title3).bold()
                #endif
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                #if os(macOS)
                .frame(height: 56, alignment: .top)
                #else
                .frame(minHeight: 48, maxHeight: 60, alignment: .top)
                #endif
                .padding(.bottom, 8)
        }
        .cornerRadius(12)
        .shadow(
            color: isHovered ? Color.black.opacity(0.15) : Color.black.opacity(0.08),
            radius: isHovered ? 8 : 4,
            x: 0,
            y: isHovered ? 4 : 2
        )
        .frame(width: cardWidth)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .colorMultiply(isHovered ? Color.white : Color(white: 0.94))
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
