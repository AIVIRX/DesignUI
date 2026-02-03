//
//  DesignBrowserView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import FluidGradient
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct DesignBrowserView: View {
    @EnvironmentObject private var designManager: DesignManager
    
    var body: some View {
        NavigationStack {
            DesignBrowserContent()
        }
    }
}

struct DesignBrowserContent: View {
    @EnvironmentObject private var designManager: DesignManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var communityViewModel = LatestPostsViewModel()
    @Environment(\.openWindow) private var openWindow
    
    @State private var showingNewDesignSheet = false
    @State private var newDesignName = ""
    @State private var showingDeleteAlert = false
    @State private var designToDelete: DesignFile?
    @State private var showingRenameSheet = false
    @State private var designToRename: DesignFile?
    @State private var renameText = ""
    @State private var showingPaywall = false
    @State private var showingLimitAlert = false
    @State private var showingSettings = false
    
    // Free tier limit
    private let freeDesignLimit = 3
    
    var body: some View {
        // Show browser content (editor opens in new window on macOS)
        browserContent
    }
    
    private var browserContent: some View {
        VStack(spacing: 0) {
            // Main Content
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Header
                    HeroHeaderView(userName: "Designer", onCreateNew: {
                        if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                            showingLimitAlert = true
                        } else {
                            showingNewDesignSheet = true
                        }
                    })
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // User's Designs Section
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Recent Designs")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal)
                        
                        if designManager.designFiles.isEmpty {
                            // Empty state
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                Text("No Designs Yet")
                                    .font(.title3.weight(.medium))
                                    .fontDesign(.rounded)
                                
                                Text("Create your first design to get started")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.secondary.opacity(0.05)))
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 24) {
                                    ForEach(designManager.designFiles) { designFile in
                                        DesignCardView(
                                            designFile: designFile,
                                            onOpen: {
                                                #if os(macOS)
                                                openWindow(value: designFile.id)
                                                #else
                                                designManager.openDesign(designFile)
                                                #endif
                                            },
                                            onDelete: {
                                                designToDelete = designFile
                                                showingDeleteAlert = true
                                            },
                                            onRename: {
                                                designToRename = designFile
                                                renameText = designFile.name
                                                showingRenameSheet = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .scrollClipDisabled()
                        }
                    }
                    
                    // Templates Section
                    VStack(alignment: .leading) {
                        Text("Start from Template")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                        
                        TemplatesGridView(
                            onSelectTemplate: { template in
                                if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                                    showingLimitAlert = true
                                } else {
                                    let name = template.name
                                    let newDesign = designManager.createDesignFromTemplate(template: template, name: name)
                                    #if os(macOS)
                                    openWindow(value: newDesign.id)
                                    #else
                                    designManager.openDesign(newDesign)
                                    #endif
                                }
                            }
                        )
                    }
                    
                    // Community Section
                    VStack(alignment: .leading) {
                        Text("Explore Community")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                        
                        if communityViewModel.isLoading && communityViewModel.posts.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if communityViewModel.posts.isEmpty {
                            Text("No community posts yet.")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: GridConfiguration.shared.columns, spacing: 24) {
                                ForEach(communityViewModel.posts) { post in
                                    CommunityCards(
                                        post: post,
                                            onOpen: { postToOpen in
                                                // Check subscription limits first
                                                if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                                                    showingLimitAlert = true
                                                    return
                                                }
                                                
                                                // Show loading toast
                                                ToastManager.shared.showToast(ToastData(title: "Loading Design...", icon: "clock.fill", duration: 5.0))
                                                
                                                Task {
                                                // TODO: Show global loading indicator if possible
                                                do {
                                                    // 1. Fetch full details (including design_json)
                                                    let fullPost = try await PostFetcher.fetchPostDetails(id: postToOpen.id)
                                                    
                                                    // 2. Create DesignFile from post
                                                    if let newDesign = designManager.createDesignFromPost(post: fullPost, name: fullPost.title) {
                                                        // 3. Open it
                                                                await MainActor.run {
                                                        ToastManager.shared.dismissToast()
                                                        #if os(macOS)
                                                        openWindow(value: newDesign.id)
                                                        #else
                                                        designManager.openDesign(newDesign)
                                                        #endif
                                                    }
                                                    } else {
                                                        print("Error: No design JSON found in post")
                                                        await MainActor.run {
                                                            ToastManager.shared.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                                                        }
                                                    }
                                                } catch {
                                                    print("Error opening post: \(error)")
                                                    await MainActor.run {
                                                        ToastManager.shared.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                                                    }
                                                }
                                            }
                                        }
                                    )
                                        .task {
                                            await communityViewModel.loadMorePostsIfNeeded(currentItem: post)
                                        }
                                }
                            }
                            .frame(maxWidth: 1800)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .task {
            if communityViewModel.posts.isEmpty {
                await communityViewModel.fetchPostsByType(postType: nil, isAllPosts: true)
            }
        }
        .navigationTitle("Design Browser")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingSettings = true
                }) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Check if user can create more designs
                    if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                        showingLimitAlert = true
                    } else {
                        showingNewDesignSheet = true
                    }
                }) {
                    Label("New Design", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewDesignSheet) {
            NewDesignSheet(
                designName: $newDesignName,
                onCreate: { name in
                    let newDesign = designManager.createNewDesign(name: name)
                    #if os(macOS)
                    openWindow(value: newDesign.id)
                    #else
                    designManager.openDesign(newDesign)
                    #endif
                    showingNewDesignSheet = false
                    newDesignName = ""
                },
                onCancel: {
                    showingNewDesignSheet = false
                    newDesignName = ""
                }
            )
            #if os(iOS)
            .presentationDetents([.height(250)])
            #endif
        }
        .alert("Delete Design", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let design = designToDelete {
                    designManager.deleteDesign(design)
                }
            }
        } message: {
            Text("Are you sure you want to delete this design? This action cannot be undone.")
        }
        .sheet(isPresented: $showingRenameSheet) {
            RenameDesignSheet(
                designName: $renameText,
                onRename: { newName in
                    if let design = designToRename, !newName.isEmpty {
                        designManager.renameDesign(design, to: newName)
                    }
                    showingRenameSheet = false
                    designToRename = nil
                    renameText = ""
                },
                onCancel: {
                    showingRenameSheet = false
                    designToRename = nil
                    renameText = ""
                }
            )
            #if os(iOS)
            .presentationDetents([.height(250)])
            #endif
        }
        #if os(iOS)
        .fullScreenCover(isPresented: Binding(
            get: { designManager.currentDesign != nil },
            set: { if !$0 { designManager.closeCurrentDesign() } }
        )) {
            if let currentDesign = designManager.currentDesign {
                EditorLoadingView(designFile: currentDesign)
                    .environmentObject(designManager)
            }
        }
        #endif
        .onAppear {
            // Refresh design files when view appears (triggers iCloud check on iOS)
            designManager.refreshDesignFiles()
        }
        .sheet(isPresented: $showingPaywall) {
            CustomPaywallView()
                .environmentObject(PaywallManager.shared)
                .environmentObject(subscriptionManager)
        }
        .alert("Free Limit Reached", isPresented: $showingLimitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Subscribe") {
                showingPaywall = true
            }
        } message: {
            Text("Free users are limited to \(freeDesignLimit) designs. Subscribe to create unlimited designs.")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct HeroHeaderView: View {
    let userName: String
    let onCreateNew: () -> Void
    
    
    
    var body: some View {
        ZStack {
            // Fancy Background
            // Fancy Background
            FluidGradient(blobs: [.purple, .blue, .cyan],
                          speed: 0.4,
                          blur: 0.75)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            
            // Content
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("Let's Create\nSomething Amazing")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onCreateNew) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Create")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
        }
        .frame(height: 220)
    }
}

struct DesignCardView: View {
    @ObservedObject var designFile: DesignFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Canvas Preview with rounded corners
            CanvasPreviewView(designFile: designFile)
                .frame(width: 280, height: 220)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(
                    color: .black.opacity(isHovered ? 0.2 : 0.1),
                    radius: isHovered ? 16 : 8,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)
            
            // Name and menu row
            HStack {
                Text(designFile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Menu {
                    Button {
                        onOpen()
                    } label: {
                        Label("Open", systemImage: "pencil")
                    }
                    
                    Button {
                        onRename()
                    } label: {
                        Label("Rename", systemImage: "character.cursor.ibeam")
                    }
                    
#if os(macOS)
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([designFile.fileURL])
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
#endif
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Text("\(Image(systemName: "trash")) Delete Design")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 25, height: 25)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
#if os(macOS)
                .pointerStyle(.link)
#endif
            }
        }
        .zIndex(isHovered ? 1 : 0)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
            #if os(macOS)
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
            #endif
        }
        .onTapGesture {
            onOpen()
        }
    }
}

struct NewDesignSheet: View {
    @Binding var designName: String
    let onCreate: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create New Design")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Design Name", text: $designName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        if !designName.isEmpty {
                            onCreate(designName)
                        }
                    }
            }
            .padding()
            .frame(width: 400)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(designName.isEmpty ? "Untitled" : designName)
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

struct RenameDesignSheet: View {
    @Binding var designName: String
    let onRename: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Rename Design")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Design Name", text: $designName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        if !designName.isEmpty {
                            onRename(designName)
                        }
                    }
                
                Text("Enter a new name for this design.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(width: 400)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rename") {
                        if !designName.isEmpty {
                            onRename(designName)
                        }
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

struct TemplatesGridView: View {
    let onSelectTemplate: (DesignTemplate) -> Void
    
    private let templateManager = DesignTemplateManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(templateManager.templates) { template in
                    TemplateCardView(
                        template: template,
                        isSelected: false,
                        onSelect: {
                            onSelectTemplate(template)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }
}

struct TemplateCardView: View {
    let template: DesignTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Template Preview
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.05))
                .frame(width: 280, height: 220)
                .overlay(
                    renderThumbnail()
                )
                .shadow(
                    color: .black.opacity(isHovered ? 0.2 : 0.1),
                    radius: isHovered ? 16 : 8,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)

            
            // Name
            Text(template.name)
                .font(.headline)
                .lineLimit(1)
        }
        .zIndex(isHovered ? 1 : 0)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
            #if os(macOS)
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
            #endif
        }
        .onTapGesture {
            onSelect()
        }
    }
    
    @ViewBuilder
    private func renderThumbnail() -> some View {
        if assetImageExists(named: template.thumbnail) {
            Image(template.thumbnail)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .padding()
        } else {
            Image(systemName: template.thumbnail)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
        }
    }
    
    private func assetImageExists(named name: String) -> Bool {
        #if os(macOS)
        return NSImage(named: name) != nil
        #else
        return UIImage(named: name) != nil
        #endif
    }
}

struct CanvasPreviewView: View {
    @ObservedObject var designFile: DesignFile
    
    var body: some View {
        // Background rectangle (same as DetailView pattern)
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.secondary.opacity(0.05))
            .overlay(
                Group {
                    if let thumbnailData = designFile.thumbnail,
                       let image = createImage(from: thumbnailData) {
#if os(macOS)
                        Image(nsImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
#else
                        Image(uiImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
#endif
                    } else if designFile.totalComponentCount == 0 {
                        VStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            Text("Empty Design")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            Text("\(designFile.totalComponentCount) components")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text("Tap to open")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            )
    }
    
#if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
#else
    private func createImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
#endif
}
