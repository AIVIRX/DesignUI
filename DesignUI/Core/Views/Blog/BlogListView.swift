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
        GridItem(.adaptive(minimum: 215, maximum: 215))
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
                    VStack(alignment: .leading, spacing: 16) {
                        BlogHeroView()
                            .padding(.top, 16)
                        
                        // Add a more prominent "Latest News" label
                        Text("Latest News")
                            .font(.largeTitle).bold()
                            .padding(.top, 16)
                        
                        Divider()
                        
                        // Grid of remaining blogs
                        let gridPosts = Array(filteredPosts)
                        if !gridPosts.isEmpty {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(gridPosts) { post in
                                    NavigationLink(destination: NewsDetailView(post: post)) {
                                        BlogGridCard(post: post)
                                            .padding(.vertical, 8)
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

struct BlogHeroView: View {
    var body: some View {
        ZStack {
            ZStack {
                Image("dockuicover")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.gray).opacity(0.7),
                        Color(.gray).opacity(0.3),
                        Color(.clear)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(height: 200)
            .overlay(
                // Glassmorphism effect: blurred, semi-transparent overlay
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
            )
            .overlay(
                // Subtle border for glass effect
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
            
            // Content
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hello Developer")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .shadow(color: Color.primary.opacity(0.18), radius: 2, x: 0, y: 1)
                    Text("Discover the latest design trends, tips, and stories. Stay inspired and connected with designers worldwide.")
                        .foregroundColor(.primary.opacity(0.9))
                        .font(.title3)
                        .shadow(color: Color.primary.opacity(0.10), radius: 1, x: 0, y: 1)
                        .frame(width: 500)
                        .lineLimit(2)
                }
                .padding(.leading, 32)
                .padding(.vertical, 32)
                Spacer()
            }
            .frame(height: 200)
        }
        .frame(height: 200)
    }
}

struct BlogGridCard: View {
    let post: NewsPost
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme

    var cardWidth: CGFloat {
    #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return min(UIScreen.main.bounds.width * 0.8, 600)
        } else {
            return min(UIScreen.main.bounds.width * 0.9, 400)
        }
    #else
        return 210
    #endif
    }
    var cardHeight: CGFloat {
    #if os(iOS)
        return 260
    #else
        return 118
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
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
                .font(.title3.bold())
                .fontWeight(.regular)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 8)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(width: cardWidth)
        .brightness(isHovered ? 0.1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
