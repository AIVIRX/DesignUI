//
//  BlogListView.swift
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

                    NewsGridSection(
                        posts: Array(viewModel.posts),
                        columns: columns,
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage
                    )
                }
                .frame(maxWidth: .infinity)
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .refreshable {
                await viewModel.fetchNews()
            }
            .task {
                await fetchNewsIfNeeded()
            }
        }
    }

    private func fetchNewsIfNeeded() async {
        guard viewModel.posts.isEmpty, !viewModel.isLoading else { return }
        await viewModel.fetchNews()
    }
}

private struct NewsGridSection: View {
    let posts: [NewsPost]
    let columns: [GridItem]
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        if !posts.isEmpty {
            NewsPostsGrid(posts: posts, columns: columns)
        } else if isLoading {
            ProgressView()
                .padding(.top, 24)
        } else {
            EmptyNewsStateView(errorMessage: errorMessage)
        }
    }
}

private struct NewsPostsGrid: View {
    let posts: [NewsPost]
    let columns: [GridItem]

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(posts) { post in
                NewsPostGridLink(post: post)
            }
        }
        .frame(maxWidth: 1800)
    }
}

private struct NewsPostGridLink: View {
    let post: NewsPost

    var body: some View {
        NavigationLink(destination: NewsDetailView(post: post)) {
            BlogGridCard(post: post)
                .padding(.vertical, 5)
                .animation(.easeInOut(duration: 0.15), value: post.id)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct EmptyNewsStateView: View {
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 8) {
            Text("No posts found")
                .font(.headline)
            Text(errorMessage ?? "Check back soon for updates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }
}

struct NewsHeroHeaderView: View {
    var body: some View {
        VStack {
            Text("Newsroom")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 160)
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
