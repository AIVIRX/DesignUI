//
//  DesignBrowserView.swift
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
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
    @State private var showingAIDrafts = false
    
    // Free tier limit
    private let freeDesignLimit = 3
    
    private var canCreateDesign: Bool {
        subscriptionManager.isSubscribed || designManager.designFiles.count < freeDesignLimit
    }

    var body: some View {
        // Show browser content (editor opens in new window on macOS)
        NavigationStack {
            browserContent
        }
    }
    
    private var browserContent: some View {
        browserScrollContent
            .modifier(
                DesignBrowserChromeModifier(
                    newDesignName: $newDesignName,
                    showingNewDesignSheet: $showingNewDesignSheet,
                    showingDeleteAlert: $showingDeleteAlert,
                    showingRenameSheet: $showingRenameSheet,
                    renameText: $renameText,
                    showingPaywall: $showingPaywall,
                    showingLimitAlert: $showingLimitAlert,
                    showingSettings: $showingSettings,
                    subscriptionManager: subscriptionManager,
                    freeDesignLimit: freeDesignLimit,
                    onCreateNewTapped: handleCreateNewTapped,
                    onCreateDesign: createDesign,
                    onCancelNewDesign: resetNewDesignSheet,
                    onDeleteConfirmed: deletePendingDesign,
                    onRenameDesign: renamePendingDesign,
                    onCancelRename: resetRenameSheet,
                    onAppear: designManager.refreshDesignFiles
                )
            )
    }

    private var browserScrollContent: some View {
        GeometryReader { proxy in
            let isCompact = horizontalSizeClass == .compact

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        featuredHero(topInset: proxy.safeAreaInsets.top)
                        refreshStatusBanner
                        recentDesignsSection
                        exploreSection
                    }
                    .padding(.bottom, 16)
                }
                .if(isCompact) { view in
                    view.ignoresSafeArea(.container, edges: .top)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await refreshHomeContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            if communityViewModel.posts.isEmpty {
                await communityViewModel.fetchPostsByType(postType: nil, isAllPosts: true)
            }
        }
        .sheet(isPresented: $showingAIDrafts) {
            DesignDraftsSheet { draft in
                let design = designManager.createDesignFromTemplate(template: draft.designJSON, name: draft.title)
                openDesign(design)
            }
        }
    }
    
    private func featuredHero(topInset: CGFloat) -> some View {
        HeroHeaderView(onCreateNew: handleCreateNewTapped, topInset: topInset)
    }

    @ViewBuilder
    private var refreshStatusBanner: some View {
        if communityViewModel.isRefreshing {
            HStack(spacing: 10) {
                ProgressView()
                Text("Refreshing...")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
    
    private var recentDesignsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            recentDesignsHeader
            
            if designManager.designFiles.isEmpty {
                emptyDesignsState
            } else {
                recentDesignsCarousel
            }
        }
    }
    
    private var recentDesignsHeader: some View {
        HStack {
            Text("My Designs")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Spacer()

            if DockUIDesignPublisher.shared.canPublish {
                Button { showingAIDrafts = true } label: {
                    Label("AI Drafts", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Open AI drafts")
            }
            
            if !subscriptionManager.isSubscribed {
                premiumButton
            }
        }
        .padding(.horizontal)
    }
    
    private var premiumButton: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.clear)
                    .overlay(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11, weight: .semibold))
                        )
                    )
                Text("Get Premium")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RainbowGlowCapsuleBackground(cornerRadius: 18)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Get Premium")
    }
    
    private var emptyDesignsState: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("No designs yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Create your first design to start building and saving work here.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .padding(.horizontal)
    }
    
    private var recentDesignsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(designManager.designFiles) { designFile in
                    ContinuePlayingCardView(
                        designFile: designFile,
                        onOpen: {
                            openDesign(designFile)
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
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .scale(scale: 0.94))
                    ))
                }
            }
            .padding(.horizontal)
            .animation(.spring(response: 0.3, dampingFraction: 0.86), value: designManager.designFiles.map(\.id))
        }
        .scrollClipDisabled()
    }
    
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Templates")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.horizontal)
            
            TemplatesGridView(
                onSelectTemplate: { template in
                    guard canCreateDesign else {
                        showingLimitAlert = true
                        return
                    }
                    
                    let newDesign = designManager.createDesignFromTemplate(template: template, name: template.name)
                    openDesign(newDesign)
                }
            )
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Community Picks")
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
                                    handleOpenCommunityPost(postToOpen)
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
    }
    
    private func handleCreateNewTapped() {
        guard canCreateDesign else {
            showingLimitAlert = true
            return
        }
        showingNewDesignSheet = true
    }

    private func createDesign(named name: String) {
        let newDesign = designManager.createNewDesign(name: name)
        openDesign(newDesign)
        resetNewDesignSheet()
    }

    private func resetNewDesignSheet() {
        showingNewDesignSheet = false
        newDesignName = ""
    }

    private func deletePendingDesign() {
        if let design = designToDelete {
            designManager.deleteDesign(design)
        }
    }

    private func renamePendingDesign(to newName: String) {
        if let design = designToRename, !newName.isEmpty {
            designManager.renameDesign(design, to: newName)
        }
        resetRenameSheet()
    }

    private func resetRenameSheet() {
        showingRenameSheet = false
        designToRename = nil
        renameText = ""
    }
    
    private func openDesign(_ design: DesignFile) {
        #if os(macOS)
        openWindow(value: design.id)
        #else
        designManager.openDesign(design)
        #endif
    }
    
    private func handleOpenCommunityPost(_ postToOpen: DesignPost) {
        if postToOpen.isPremium && !subscriptionManager.isSubscribed {
            toastManager.showToast(ToastData(title: "Premium Required", icon: "lock.fill"))
            showingPaywall = true
            return
        }
        
        guard canCreateDesign else {
            showingLimitAlert = true
            return
        }
        
        toastManager.showToast(ToastData(title: "Loading Design...", icon: "clock.fill", duration: 5.0))
        
        Task {
            do {
                let fullPost = try await PostFetcher.fetchPostDetails(id: postToOpen.id)
                
                if let newDesign = await designManager.createDesignFromPost(post: fullPost, name: fullPost.title) {
                    await MainActor.run {
                        toastManager.dismissToast()
                        openDesign(newDesign)
                    }
                } else {
                    debugLog("Error: No design JSON found in post")
                    await MainActor.run {
                        toastManager.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                    }
                }
            } catch {
                debugLog("Error opening post: \(error)")
                await MainActor.run {
                    toastManager.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                }
            }
        }
    }
    
    @MainActor
    private func refreshHomeContent() async {
#if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
#endif
        designManager.refreshDesignFiles()
        await communityViewModel.refreshPosts(filterType: nil, isAllPosts: true)
    }
    
}

private struct DesignBrowserChromeModifier: ViewModifier {
    @Binding var newDesignName: String
    @Binding var showingNewDesignSheet: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingRenameSheet: Bool
    @Binding var renameText: String
    @Binding var showingPaywall: Bool
    @Binding var showingLimitAlert: Bool
    @Binding var showingSettings: Bool
    @ObservedObject var subscriptionManager: SubscriptionManager

    let freeDesignLimit: Int
    let onCreateNewTapped: () -> Void
    let onCreateDesign: (String) -> Void
    let onCancelNewDesign: () -> Void
    let onDeleteConfirmed: () -> Void
    let onRenameDesign: (String) -> Void
    let onCancelRename: () -> Void
    let onAppear: () -> Void

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .toolbar { toolbarContent }
            #else
            .toolbarBackground(.hidden, for: .windowToolbar)
            .toolbar { toolbarContent }
            #endif
            .sheet(isPresented: $showingNewDesignSheet) { newDesignSheet }
            .alert("Delete Design", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive, action: onDeleteConfirmed)
            } message: {
                Text("Are you sure you want to delete this design? This action cannot be undone.")
            }
            .sheet(isPresented: $showingRenameSheet) { renameDesignSheet }
            .onAppear(perform: onAppear)
            .sheet(isPresented: $showingPaywall) { paywallSheet }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onCreateNewTapped) {
                Label("New Design", systemImage: "plus")
            }
        }
        #else
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }

            Button(action: onCreateNewTapped) {
                Label("New Design", systemImage: "plus")
            }
        }
        #endif
    }

    private var newDesignSheet: some View {
        NewDesignSheet(
            designName: $newDesignName,
            onCreate: onCreateDesign,
            onCancel: onCancelNewDesign
        )
        #if os(iOS)
        .presentationDetents([.height(250)])
        #endif
    }

    private var renameDesignSheet: some View {
        RenameDesignSheet(
            designName: $renameText,
            onRename: onRenameDesign,
            onCancel: onCancelRename
        )
        #if os(iOS)
        .presentationDetents([.height(250)])
        #endif
    }

    private var paywallSheet: some View {
        CustomPaywallView()
            .environmentObject(PaywallManager.shared)
            .environmentObject(subscriptionManager)
    }
}

struct HeroHeaderView: View {
    let onCreateNew: () -> Void
    let topInset: CGFloat
    @EnvironmentObject private var designManager: DesignManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let slide = HeroSlide(
        title: "Design your next idea",
        subtitle: "Open a recent design, keep iterating, or spin up something new in seconds.",
        accent: Color(red: 0.22, green: 0.52, blue: 1.00),
        accent2: Color(red: 0.31, green: 0.32, blue: 0.94),
        accent3: Color(red: 0.06, green: 0.11, blue: 0.34),
        cardSymbol: "rectangle.on.rectangle",
        previewImageName: nil
    )

    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        let heroHeight: CGFloat = isCompact ? 340 : 250

        ZStack {
            heroBackdrop(slide, isCompact: isCompact)
                .stretchyBackground()
                .frame(height: heroHeight + topInset)
                .offset(y: -topInset)

            heroSlide(slide, isCompact: isCompact, topInset: topInset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
    }

    private func heroSlide(_ slide: HeroSlide, isCompact: Bool, topInset: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 18) {
            VStack(alignment: .center, spacing: 8) {
                Text(slide.title)
                    .font(.system(size: isCompact ? 30 : 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)

                Text(slide.subtitle)
                    .font(.system(size: isCompact ? 15 : 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: isCompact ? .infinity : 620, alignment: .center)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateNew) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Design")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.20, blue: 0.34))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, isCompact ? 22 : 50)
        .padding(.top, isCompact ? topInset + 54 : topInset)
    }

    private func heroBackdrop(_ slide: HeroSlide, isCompact: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    slide.accent.opacity(0.92),
                    slide.accent2.opacity(0.82),
                    slide.accent3.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            FluidGradient(
                blobs: [slide.accent2, slide.accent, slide.accent3],
                speed: 0.35,
                blur: 0.7
            )
            .blendMode(.screen)
            .opacity(0.9)
        }
        .ignoresSafeArea()
    }

    private func assetImageExists(named name: String) -> Bool {
        bundledPlatformImage(named: name) != nil
    }

}

private struct HeroSlide {
    let title: String
    let subtitle: String
    let accent: Color
    let accent2: Color
    let accent3: Color
    let cardSymbol: String
    let previewImageName: String?
}

struct DesignCardView: View {
    @ObservedObject var designFile: DesignFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    
    @State private var isHovered = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Canvas Preview with rounded corners
            CanvasPreviewView(designFile: designFile)
                .frame(width: 240, height: 200)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow( color: .black.opacity(isHovered ? 0.2 : 0.1),radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)
            
            // Name and menu row
            HStack(spacing: 8) {
                Text(designFile.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(0)
                
                Spacer(minLength: 0)
                
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
                        Label("Delete Design", systemImage: "trash")
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
                .buttonStyle(PlainButtonStyle())
                .fixedSize()
                .layoutPriority(1)
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

struct ContinuePlayingCardView: View {
    @ObservedObject var designFile: DesignFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CanvasPreviewView(designFile: designFile)
                .frame(width: 240, height: 200)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.22 : 0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isHovered ? 0.18 : 0.08), radius: isHovered ? 14 : 8, x: 0, y: 6)
                .scaleEffect(isHovered ? 1.03 : 1.0)
            
            HStack(spacing: 8) {
                Text(designFile.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 240)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen()
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func stretchyBackground() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self
                .visualEffect { effect, geometry in
                    let scrollOffset = geometry.frame(in: .scrollView).minY
                    let positiveOffset = max(0, scrollOffset)
                    let currentHeight = max(geometry.size.height, 1)
                    let newHeight = currentHeight + positiveOffset
                    let scaleFactor = newHeight / currentHeight

                    return effect.scaleEffect(
                        x: scaleFactor,
                        y: scaleFactor,
                        anchor: .bottom
                    )
                }
        } else {
            self
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct NewDesignSheet: View {
    @Binding var designName: String
    let onCreate: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        DesignNameSheet(
            title: "Create New Design",
            actionTitle: "Create",
            designName: $designName,
            allowsEmptyName: true,
            onConfirm: { onCreate($0.isEmpty ? "Untitled" : $0) },
            onCancel: onCancel
        )
    }
}

struct RenameDesignSheet: View {
    @Binding var designName: String
    let onRename: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        DesignNameSheet(
            title: "Rename Design",
            actionTitle: "Rename",
            designName: $designName,
            onConfirm: onRename,
            onCancel: onCancel
        )
    }
}

private struct DesignNameSheet: View {
    let title: String
    let actionTitle: String
    @Binding var designName: String
    let allowsEmptyName: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool

    private let maxNameLength = 50

    init(
        title: String,
        actionTitle: String,
        designName: Binding<String>,
        allowsEmptyName: Bool = false,
        onConfirm: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self._designName = designName
        self.allowsEmptyName = allowsEmptyName
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                nameField
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .padding()
            .frame(width: 400)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle, action: confirm)
                        .disabled(!allowsEmptyName && designName.isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        #if os(macOS)
        .frame(width: 300)
        #endif
    }

    private var nameField: some View {
        TextField("Design Name", text: $designName)
            .autocorrectionDisabled()
            .focused($isFocused)
            .onSubmit(confirm)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(fieldBackgroundColor)
            .cornerRadius(12)
            .overlay(nameFieldBorder)
            .shadow(
                color: isFocused ? Color.black.opacity(0.1) : .clear,
                radius: 4,
                x: 0,
                y: 2
            )
            .onChange(of: designName) { _, newValue in
                if newValue.count > maxNameLength {
                    designName = String(newValue.prefix(maxNameLength))
                }
            }
    }

    private var nameFieldBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isFocused ? Color.accentColor : Color.gray.opacity(0.3),
                lineWidth: isFocused ? 2 : 1
            )
    }

    private var fieldBackgroundColor: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }

    private func confirm() {
        guard allowsEmptyName || !designName.isEmpty else { return }
        onConfirm(designName)
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
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Template Preview
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 240, height: 200)
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
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
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
        bundledPlatformImage(named: name) != nil
    }
}

struct CanvasPreviewView: View {
    @ObservedObject var designFile: DesignFile
    
    /// Use first page's thumbnail for project preview (page 1 is the "home page")
    private var previewThumbnail: Data? {
        // Prefer first page's thumbnail, fallback to legacy designFile.thumbnail
        if let firstPageThumbnail = designFile.pages.first?.thumbnail {
            return firstPageThumbnail
        }
        return designFile.thumbnail
    }
    
    var body: some View {
        // Background rectangle (same as DetailView pattern)
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.secondary.opacity(0.05))
            .overlay(
                Group {
                    if let thumbnailData = previewThumbnail,
                       let image = swiftUIImage(from: thumbnailData) {
                        image
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
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
}
