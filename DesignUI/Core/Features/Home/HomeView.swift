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
    @ObservedObject var userViewModel = UserViewModel.shared
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var communityPosts: [DesignPost] = []
    @State private var hasMoreCommunityPosts = false
    @State private var isLoading: Bool = false
    @State private var showSearchResults = false
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var isCommunityPostsLoaded = false
    @Namespace private var namespace
    let client = SupabaseManager.shared.client
    var body: some View {
        NavigationStack {
                       ScrollView {
                           LazyVGrid(columns: gridColumns, spacing: 16) {
                               // Loop through the posts using ForEach
                               ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { index, post in
                                   DesignCards(
                                       id: post.id,
                                       media: post.image_url,
                                       title: post.title,
                                       authorUID: post.author.id,
                                       authorName: post.author.display_name,
                                       isVerified: post.author.is_verified,
                                       description: post.description,
                                       codeSnippet: post.code_snippet,
                                       published: post.created_at,
                                       likes: post.likes_count,
                                       views: post.view_count,
                                       hexa: post.hexadecimal,
                                       visibility: post.visibility
                                   )
                                   .onAppear {
                                       // Trigger fetching more posts when the last post appears
                                       if index == viewModel.posts.count - 1 {
                                           Task {
                                               await viewModel.fetchPosts()
                                           }
                                       }
                                   }
                               }
                           }
                           .padding(.horizontal)
                       }
                       
                       .navigationTitle("Latest Posts")
                       .onAppear {
                           // Fetch the initial set of posts
                           Task {
                               await viewModel.fetchPosts()
                           }
                           print(viewModel.posts)
                       }
                   
               
           
            .frame(maxWidth: 1600)
            .navigationTitle("Home")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: HStack {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
            })
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
            
            Task {
                await userViewModel.fetchProfileData()
            }
            
            store.loadStoredPurchases()
        }
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

