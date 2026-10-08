//
//  BlogListView.swift
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct NewsListView: View {
    @StateObject var viewModel = NewsViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var columns: [GridItem] {
        return [GridItem(.adaptive(minimum: 300, maximum: 300))]
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let threeColumns = usesThreeColumns(in: geometry)
                let inset: CGFloat = threeColumns ? 16 : 0
                let cardWidth = threeColumns ? max(1, (geometry.size.width - inset * 2 - 32) / 3) : nil

                ScrollView {
                    VStack(alignment: .center, spacing: 16) {
                        NewsGridSection(
                            posts: Array(viewModel.posts),
                            columns: threeColumns
                                ? Array(repeating: GridItem(.flexible(minimum: 0), spacing: 16), count: 3)
                                : columns,
                            isLoading: viewModel.isLoading,
                            errorMessage: viewModel.errorMessage,
                            cardWidth: cardWidth
                        )
                    }
                    .padding(.horizontal, inset)
                    .frame(maxWidth: .infinity)
                }
                .refreshable {
                    await viewModel.fetchNews()
                }
            }
            .navigationTitle("News")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .task {
                await fetchNewsIfNeeded()
            }
        }
    }

    private func usesThreeColumns(in geometry: GeometryProxy) -> Bool {
#if os(iOS)
        if #available(iOS 27.1, *) {
            return UIDevice.current.userInterfaceIdiom == .phone
                && horizontalSizeClass == .regular
                && geometry.size.width > geometry.size.height
                && !geometry.reservedRegions(kind: .division, options: .includeInactive).isEmpty
        }
#endif
        return false
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
    var cardWidth: CGFloat? = nil

    var body: some View {
        if !posts.isEmpty {
            NewsPostsGrid(posts: posts, columns: columns, cardWidth: cardWidth)
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
    var cardWidth: CGFloat? = nil

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(posts) { post in
                NewsPostGridLink(post: post, cardWidth: cardWidth)
            }
        }
        .frame(maxWidth: 1800)
    }
}

private struct NewsPostGridLink: View {
    let post: NewsPost
    var cardWidth: CGFloat? = nil

    var body: some View {
        NavigationLink(destination: NewsDetailView(post: post)) {
            BlogGridCard(post: post, preferredWidth: cardWidth)
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

struct BlogGridCard: View {
    let post: NewsPost
    var preferredWidth: CGFloat? = nil
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var cardWidth: CGFloat {
        if let preferredWidth { return preferredWidth }
#if os(iOS)
        if horizontalSizeClass == .compact {
            return 280
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
        if horizontalSizeClass == .compact {
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
