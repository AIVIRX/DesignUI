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
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray
                    }
                    .aspectRatio(16/9, contentMode: .fill)
                    .cornerRadius(12)
                }
                Text(post.title)
                    .font(.largeTitle)
                    .bold()
                Text(formattedDate(from: post.created_at))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Divider()
                NewsContentView(blocks: post.blocks)
            }
            .padding()
        }
        .navigationTitle(post.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
