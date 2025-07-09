//
//  BlogDetailView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct NewsDetailView: View {
    let post: NewsPost

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Featured image/card
                if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
                    ZStack {
                        WebImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: 700, maxHeight: 394)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: 700, maxHeight: 394)
                                    .clipped()
                                    .cornerRadius(15)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: 700, maxHeight: 394)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(15)
                            @unknown default:
                                Color.gray.opacity(0.2)
                                    .frame(maxWidth: 700, maxHeight: 394)
                                    .cornerRadius(15)
                            }
                        }
                    }
                    .frame(maxWidth: 700, maxHeight: 394)
                    .padding(.horizontal)
                }

                // Main content card
                VStack(alignment: .leading) {
                    Text(post.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                    Text(formattedDate(from: post.created_at))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let desc = post.description {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top)
                    }
                    Divider().padding(.vertical)
                    NewsContentView(blocks: post.blocks)
                    
                }
                .frame(maxWidth: 700)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        }
        .navigationTitle("")
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: URL(string: "https://dockui.com/news/\(post.slug)")!) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
#endif
#if os(macOS)
            ToolbarItem() {
                ShareLink(item: URL(string: "https://dockui.com/news/\(post.slug)")!) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
#endif
        }
    }
}
