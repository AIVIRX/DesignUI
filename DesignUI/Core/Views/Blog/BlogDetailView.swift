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
                // Featured image/card
                if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
                    ZStack {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 700, height: 394)
                                .clipped()
                                .cornerRadius(12)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                                .frame(width: 700, height: 394)
                                .cornerRadius(12)
                        }
                    }
                    .frame(width: 700, height: 394)
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
    }
}
