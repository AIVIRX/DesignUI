//
//  BlogListView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI

struct NewsListView: View {
    @StateObject var viewModel = NewsViewModel()
    @State private var selectedPost: NewsPost?
    @State private var searchText: String = ""

    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 420, maximum: 520), spacing: 32)
    ]

    var filteredPosts: [NewsPost] {
        if searchText.isEmpty {
            return viewModel.posts
        } else {
            return viewModel.posts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.description ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center) {
                    // Featured Blog
                    if let featured = filteredPosts.first {
                        NavigationLink(destination: NewsDetailView(post: featured)) {
                            FeaturedBlogCard(post: featured)
                                .frame(maxWidth: 700)
                                .padding(.vertical, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    // Grid of remaining blogs
                    let gridPosts = Array(filteredPosts.dropFirst())
                    if !gridPosts.isEmpty {
                        LazyVGrid(columns: columns, spacing: 32) {
                            ForEach(gridPosts) { post in
                                NavigationLink(destination: NewsDetailView(post: post)) {
                                    BlogGridCard(post: post)
                                        .frame(maxWidth: 500)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.thinMaterial)
                                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                                        )
                                        .animation(.easeInOut(duration: 0.15), value: post.id)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 40)
                        .frame(maxWidth: 1400)
                    }
                }
                .frame(maxWidth: .infinity)
                .navigationTitle("News")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
            .searchable(text: $searchText)
#if os(iOS)
            .sheet(item: $selectedPost) { post in
                NewsDetailView(post: post)
            }
#endif
            .task { await viewModel.fetchNews() }
        }
    }
}

struct BlogGridCard: View {
    let post: NewsPost

    var cardWidth: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return min(UIScreen.main.bounds.width * 0.8, 600) // wider for iPad
        } else {
            return min(UIScreen.main.bounds.width * 0.9, 400) // normal for iPhone
        }
        #else
        return 400
        #endif
    }

    var cardHeight: CGFloat {
        #if os(iOS)
        return 260 // or larger
        #else
        return 220 // or larger
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = URL(string: post.image_url ?? "") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    Color.gray.opacity(0.2)
                        .frame(width: cardWidth, height: cardHeight)
                        .cornerRadius(12)
                }
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: cardWidth, height: cardHeight)
                    .cornerRadius(12)
            }
            Text(post.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(12)
        .background(.regularMaterial.opacity(0.9))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(width: cardWidth)
    }
}

struct GridNewsCard: View {
    let post: NewsPost
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(10)
            }
            Text(post.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(post.description ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(.regularMaterial.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Small horizontal card
struct SmallNewsCard: View {
    let post: NewsPost
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let url = URL(string: post.image_url ?? "") {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 180, height: 100)
                .clipped()
                .cornerRadius(12)
            }
            Text(post.title)
                .font(.subheadline).bold()
                .foregroundColor(.white)
            Text(post.description ?? "")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
        }
        .frame(width: 180)
        .padding(8)
        .background(.regularMaterial.opacity(0.9))
        .cornerRadius(16)
    }
}

// Add a new FeaturedBlogCard view for the featured post
struct FeaturedBlogCard: View {
    let post: NewsPost
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let url = URL(string: post.image_url ?? "") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(16/7, contentMode: .fill)
                        .frame(height: 260)
                        .clipped()
                        .cornerRadius(18)
                } placeholder: {
                    Color.gray.opacity(0.2)
                        .frame(height: 260)
                        .cornerRadius(18)
                }
            }
            Text(post.title)
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .lineLimit(3)
            if let desc = post.description {
                Text(desc)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(28)
    }
}

