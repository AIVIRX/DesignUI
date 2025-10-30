//
//  BlogDetailView.swift
//  DesignUI
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
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .frame(maxWidth: 700, alignment: .leading)
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
                        
                        // Resources section (no premium gating)
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Download Resources")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("Get the design files and assets for this article")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    downloadResources()
                                }) {
                                    Text("Download")
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                        
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
