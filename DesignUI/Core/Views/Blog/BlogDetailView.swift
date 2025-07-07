//
//  BlogDetailView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI

struct NewsDetailView: View {
    let post: NewsPost

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Section label
                HStack {
                    Text("FEATURED")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                }
                .padding(.horizontal, 8)

                // Featured image/card
                if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(24)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                                .cornerRadius(24)
                        }
                    }
                    .frame(maxWidth: 600, minHeight: 320)
                    .padding(.horizontal)
                }

                // Main content card
                VStack(alignment: .leading, spacing: 16) {
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
                    }
                    // Optional: Add a link if available
                    if let url = URL(string: "https://yourapp.com/news/\(post.slug)") {
                        Link("View this year's winners and finalists >", destination: url)
                            .font(.body)
                            .foregroundColor(.accentColor)
                            .padding(.top, 8)
                    }
                    Divider()
                    NewsContentView(blocks: post.blocks)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.thinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .frame(maxWidth: 700)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
