//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
#if os(iOS)
import StatefulTabView
#endif
import SDWebImage
import SDWebImageSwiftUI
import Supabase

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    let client = SupabaseManager.shared.client
    
    private func makeDesignCard(for post: DesignPost, at index: Int) -> some View {
        DesignCards(
            id: post.id,
            media: post.preview_image_url,
            title: post.title,
            authorName: post.profiles.username,
            isVerified: post.profiles.verified,
            description: post.description,
            codeSnippet: post.code_snippet,
            published: post.created_at
        )
        .onAppear {
            if index == viewModel.posts.count - 1 {
                Task {
                    await viewModel.loadMorePostsIfNeeded(currentItem: post)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { index, post in
                        makeDesignCard(for: post, at: index)
                            .task {
                                await viewModel.loadMorePostsIfNeeded(currentItem: post)
                            }
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("Latest Posts")
            .task {
                await viewModel.loadMorePostsIfNeeded(currentItem: nil)
            }
            .frame(maxWidth: 1600)
            .navigationTitle("Home")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                startAnimation = true
                opacity = 1.0
            }
            
            store.loadStoredPurchases()
        }
        .refreshable {
            Task {
                await viewModel.refreshPosts()
            }
        }
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
