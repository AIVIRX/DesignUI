//
//  BlogDetailView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI
import SDWebImage
import SDWebImageSwiftUI

struct NewsDetailView: View {
    let post: NewsPost
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        ScrollView {
            VStack{
                VStack(spacing: 32) {
                    Text(post.title)
                        #if os(macOS)
                        .font(.system(size: 34, weight: .bold))
                        #else
                        .font(.title)
                        .fontWeight(.bold)
                        #endif
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .frame(maxWidth: 700, alignment: .leading)
                    // Featured image/card
                    if let imageUrl = post.image_url, let url = URL(string: imageUrl) {
                        ZStack {
                            WebImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: 700, maxHeight: 394)
                                        .clipped()
                                        .cornerRadius(15)
                            } placeholder: {
                                ProgressView()
                                        .frame(maxWidth: 700, maxHeight: 394)
                            }
                        }
                        .frame(maxWidth: 700, maxHeight: 394)
                    }
                    
                    // Main content card
                    VStack(alignment: .leading) {
                        if let desc = post.description {
                            Text(desc)
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                        Divider().padding(.vertical)
                        
                        NewsContentView(blocks: post.blocks)
                    }
                }
                .frame(maxWidth: 700, alignment: .center)
                .padding(.horizontal)
                .padding(.vertical, 40)
            }
            .frame(maxWidth: .infinity)
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
    
    private func downloadResources() {
        // Implement download logic here
        print("Downloading resources for: \(post.title)")
        // You can add actual download functionality here
    }
}
