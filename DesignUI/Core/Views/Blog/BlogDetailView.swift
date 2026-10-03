//
//  BlogDetailView.swift
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
            contentLayout
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
            }
#endif
#if os(macOS)
            ToolbarItem() {
                shareButton
            }
#endif
        }
    }

    private var contentLayout: some View {
        VStack {
            articleContent
        }
        .frame(maxWidth: .infinity)
    }

    private var articleContent: some View {
        VStack(spacing: 32) {
            titleView
            featuredImageView
            mainContentCard
        }
        .frame(maxWidth: 800, alignment: .center)
        .padding(.horizontal)
        .padding(.vertical, 40)
    }

    private var titleView: some View {
        Text(post.title)
#if os(macOS)
            .font(.system(size: 34, weight: .bold))
#else
            .font(.title)
            .fontWeight(.bold)
#endif
            .foregroundColor(.primary)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var featuredImageView: some View {
        if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
            ZStack {
                WebImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(15)
                } placeholder: {
                    ProgressView()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var mainContentCard: some View {
        VStack(alignment: .leading) {
            descriptionView
            Divider().padding(.vertical)
            NewsContentView(blocks: post.blocks)
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        if let desc = post.description {
            Text(desc)
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }

    private var shareURL: URL {
        URL(string: "https://dockui.com/news/\(post.slug)")!
    }

    private var shareButton: some View {
        ShareLink(item: shareURL) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
