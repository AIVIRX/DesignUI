//
//  BlogListView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI
import StoreKit

struct NewsListView: View {
    @StateObject var viewModel = NewsViewModel()
    @State private var selectedPost: NewsPost?
    @State private var searchText: String = ""
    @EnvironmentObject private var store: Store
    
    // Responsive columns for iPad
    var columns: [GridItem] {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [GridItem(.adaptive(minimum: 320, maximum: 320)), GridItem(.adaptive(minimum: 320, maximum: 400))]
        } else {
            return [GridItem(.adaptive(minimum: 215, maximum: 215))]
        }
#else
        return [GridItem(.adaptive(minimum: 215, maximum: 215))]
#endif
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
                    // Responsive LargeCardView for iPad
#if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        LargeHero(name: "Hello Developer", description: "Discover the latest design trends, tips, and stories. Stay inspired and connected with designers worldwide.", height: 200, padding: 0, colors: [.mint,.indigo,.pink,.blue,.mint])
                            .padding(.top, 32)
                    } else {
                        LargeHero(name: "Hello Developer", description: "Discover the latest design trends, tips, and stories. Stay inspired and connected with designers worldwide.", height: 200, padding: 0, colors: [.mint,.indigo,.pink,.blue,.mint])
                            .padding(.top, 16)
                    }
#else
                    LargeHero(name: "Hello Developer", description: "Discover the latest design trends, tips, and stories. Stay inspired and connected with designers worldwide.", height: 200, padding: 0, colors: [.mint,.indigo,.pink,.blue,.mint])
                        .padding(.top, 16)
#endif
                    Text("Latest News")
                        .font(.largeTitle).bold()
                        .padding(.top, 16)
                    Divider()
                    // Grid of remaining blogs
                    let gridPosts = Array(filteredPosts)
                    if !gridPosts.isEmpty {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(gridPosts) { post in
                                NavigationLink(destination: NewsDetailView(post: post)) {
                                    BlogGridCard(post: post)
                                        .padding(.vertical, 12)
                                        .animation(.easeInOut(duration: 0.15), value: post.id)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(maxWidth: 1400)
                    }
                }
#if os(iOS)
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 48 : 16)
#else
                .padding(.horizontal)
#endif
                .frame(maxWidth: .infinity)
                .navigationTitle("News")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .refreshable {
                await viewModel.fetchNews()
            }
            .searchable(text: $searchText)
#if os(iOS)
            .sheet(item: $selectedPost) { post in
                NewsDetailView(post: post)
            }
#endif
            .task { await viewModel.fetchNews() }
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                if !store.completedPurchases.isEmpty{
                } else {
                    AdView(adUnitID: AdUnitID.finalAd)
                        .frame(width: 468, height: 60)
                        .padding(5)
                }
            }
#endif
        }
    }
}

struct BlogGridCard: View {
    let post: NewsPost
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var cardWidth: CGFloat {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return min(UIScreen.main.bounds.width * 0.35, 320)
        } else {
            return min(UIScreen.main.bounds.width * 0.9, 400)
        }
#else
        return 210
#endif
    }
    
    var cardHeight: CGFloat {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 180
        } else {
            return 260
        }
#else
        return 118
#endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlString = post.image_url, let url = URL(string: urlString) {
                WebImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: cardWidth, height: cardHeight)
                    case .success(let image):
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
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth, height: cardHeight)
                            .foregroundColor(.gray.opacity(0.5))
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    @unknown default:
                        Color.gray.opacity(0.2)
                            .frame(width: cardWidth, height: cardHeight)
                            .cornerRadius(12)
                    }
                }
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: cardWidth, height: cardHeight)
                    .cornerRadius(12)
            }
            Text(post.title)
                .font(.title3.bold())
                .fontWeight(.semibold)
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
