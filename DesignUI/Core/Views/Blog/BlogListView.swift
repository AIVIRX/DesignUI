//
//  BlogListView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct NewsListView: View {
    @StateObject var viewModel = NewsViewModel()
    @State private var selectedPost: NewsPost?
    @State private var searchText: String = ""
    
    // Responsive columns - iPad now matches Mac
    var columns: [GridItem] {
        return [GridItem(.adaptive(minimum: 280, maximum: 280))]
    }
    
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
                VStack(alignment: .leading, spacing: 16) {
                    
                    LargeHero(name: "Hello Developer", description: "Discover the latest design trends, tips, and stories. Stay inspired and connected with designers worldwide.", height: 200, padding: 0)
                        .padding(.top, 16)
                    
                    // Grid of remaining blogs
                    let gridPosts = Array(filteredPosts)
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
                        .frame(maxWidth: 1400)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .navigationTitle("News")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .refreshable {
                await viewModel.fetchNews()
            }
            .searchable(text: $searchText, prompt: "Search posts")
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
        return 280
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
        return 150
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
                #if os(iOS)
                .lineLimit(2)
                #endif
                .multilineTextAlignment(.leading)
                #if os(macOS)
                .frame(height: 56, alignment: .top)
                #else
                .frame(height: 48, alignment: .top)
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
