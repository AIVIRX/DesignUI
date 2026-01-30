//
//  UserPostsView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 1/15/25.
//

import SwiftUI

struct UserPostsView: View {
    @StateObject private var viewModel = UserPostsViewModel()
    @State private var showDeleteAlert = false
    @State private var postToDelete: DesignPost?
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.userPosts.isEmpty {
                ProgressView()
                    .padding()
            } else if viewModel.userPosts.isEmpty {
                VStack {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding()
                    Text("No posts yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 5)
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                postsGridView
            }
        }
        .task {
            await viewModel.fetchUserPosts()
        }
        .refreshable {
            await viewModel.refreshPosts()
        }
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                postToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    Task { @MainActor in
                        do {
                            try await viewModel.deletePost(postId: post.id)
                            postToDelete = nil
                        } catch {
                            print("Error deleting post: \(error.localizedDescription)")
                            // Show error alert
                            postToDelete = nil
                        }
                    }
                } else {
                    postToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private var postsGridView: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                LazyMasonryView(
                    items: viewModel.userPosts,
                    columns: 2,
                    spacing: 8,
                    hasMorePosts: viewModel.hasMorePosts,
                    isLoading: viewModel.isLoading,
                    loadMoreHandler: { post in
                        guard let post = post else { return }
                        Task {
                            await viewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                        }
                    }
                ) { post in
                    userPostCell(for: post)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            } else {
                gridView(spacing: 8, horizontalPadding: 8)
            }
        } else {
            if #available(iOS 16.0, *) {
                LazyMasonryView(
                    items: viewModel.userPosts,
                    columns: 5,
                    spacing: 16,
                    hasMorePosts: viewModel.hasMorePosts,
                    isLoading: viewModel.isLoading,
                    loadMoreHandler: { post in
                        guard let post = post else { return }
                        Task {
                            await viewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                        }
                    }
                ) { post in
                    userPostCell(for: post)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            } else {
                gridView(spacing: 16, horizontalPadding: 16)
            }
        }
#else
        if #available(macOS 13.0, *) {
            LazyMasonryView(
                items: viewModel.userPosts,
                columns: 5,
                spacing: 16,
                hasMorePosts: viewModel.hasMorePosts,
                isLoading: viewModel.isLoading,
                loadMoreHandler: { post in
                    guard let post = post else { return }
                    Task {
                        await viewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                    }
                }
            ) { post in
                userPostCell(for: post)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        } else {
            gridView(spacing: 16, horizontalPadding: 16)
        }
#endif
    }
    
    private func gridView(spacing: CGFloat, horizontalPadding: CGFloat) -> some View {
        let columns = GridConfiguration.shared.columns
        
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(viewModel.userPosts) { post in
                userPostCell(for: post)
                    .task {
                        await viewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                    }
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    @ViewBuilder
    private func userPostCell(for post: DesignPost) -> some View {
        let status = post.status?.lowercased()
        let isPending = status == "pending"
        let isDenied = status == "denied" || status == "rejected"
        
        ZStack {
            CommunityCards(
                post: post,
                showDeleteButton: true,
                onDelete: {
                    postToDelete = post
                    showDeleteAlert = true
                }
            )
            
            // Status Badge - positioned at bottom left
            if isPending {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text("Pending")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            } else if isDenied {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                    Text("Denied")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.15))
                .cornerRadius(8)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
}

