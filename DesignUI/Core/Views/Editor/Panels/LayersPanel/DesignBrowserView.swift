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
    @Environment(\.requestReview) private var requestReview
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var communityViewModel = LatestPostsViewModel()
    @Environment(\.openWindow) private var openWindow
    @State private var showingCreateProjectSheet = false
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
                    showingCreateProjectSheet: $showingCreateProjectSheet,
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
                    onCancelNewDesign: resetCreateProjectSheet,
                    onDeleteConfirmed: deletePendingDesign,
                    onRenameDesign: renamePendingDesign,
                    onCancelRename: resetRenameSheet,
                    onAppear: designManager.refreshDesignFiles
                )
            )
    }

    private var browserScrollContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    heroHeader
                    refreshStatusBanner
                    recentDesignsSection
                    templatesSection
                    communitySection
                }
                .padding(.vertical)
            }
            .refreshable {
                await refreshHomeContent()
            }
        }
        .task {
            if communityViewModel.posts.isEmpty {
                await communityViewModel.fetchPostsByType(postType: nil, isAllPosts: true)
            }
        }
        .task {
            await requestReviewAfterDelayIfNeeded()
        }
    }
    
    private var heroHeader: some View {
        HeroHeaderView(onCreateNew: handleCreateNewTapped)
            .padding(.horizontal)
            .padding(.top, 16)
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
        VStack(alignment: .leading) {
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
            Text("Recent Designs")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Spacer()
            
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
    }
    
    private var recentDesignsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(designManager.designFiles) { designFile in
                    DesignCardView(
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
    
    private var templatesSection: some View {
        VStack(alignment: .leading) {
            Text("Start from Template")
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
        }
    }
    
    private var communitySection: some View {
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
    
    private func handleCreateNewTapped() {
        guard canCreateDesign else {
            showingLimitAlert = true
            return
        }
        showingCreateProjectSheet = true
    }

    private func createDesign(mode: CreateProjectMode, named name: String) {
        let finalName = name.isEmpty ? mode.defaultProjectName : name
        let newDesign = designManager.createNewDesign(name: finalName)

        if mode == .screenshots {
            toastManager.showToast(ToastData(title: "Screenshots project created", icon: "photo"))
        }

        openDesign(newDesign)
        resetCreateProjectSheet()
    }

    private func resetCreateProjectSheet() {
        showingCreateProjectSheet = false
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
    
    @MainActor
    private func requestReviewAfterDelayIfNeeded() async {
        guard !SessionManager.shared.hasRequestedReview else { return }
        
        try? await Task.sleep(for: .seconds(30))
        
        guard !Task.isCancelled else { return }
        guard !SessionManager.shared.hasRequestedReview else { return }
        
        requestReview()
        SessionManager.shared.hasRequestedReview = true
    }
}

private struct DesignBrowserChromeModifier: ViewModifier {
    @Binding var newDesignName: String
    @Binding var showingCreateProjectSheet: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingRenameSheet: Bool
    @Binding var renameText: String
    @Binding var showingPaywall: Bool
    @Binding var showingLimitAlert: Bool
    @Binding var showingSettings: Bool
    @ObservedObject var subscriptionManager: SubscriptionManager

    let freeDesignLimit: Int
    let onCreateNewTapped: () -> Void
    let onCreateDesign: (CreateProjectMode, String) -> Void
    let onCancelNewDesign: () -> Void
    let onDeleteConfirmed: () -> Void
    let onRenameDesign: (String) -> Void
    let onCancelRename: () -> Void
    let onAppear: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle("Design Browser")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingCreateProjectSheet) { createProjectSheet }
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
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: onCreateNewTapped) {
                Label("New Design", systemImage: "plus")
            }
        }
    }

    private var createProjectSheet: some View {
        CreateProjectSheet(
            designName: $newDesignName,
            onCreate: onCreateDesign,
            onCancel: onCancelNewDesign
        )
        #if os(iOS)
        .presentationDetents([.medium, .large])
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        
        ZStack {
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
            Group {
                if isCompact {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("Let's Create\nSomething Amazing")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .primary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Button(action: onCreateNew) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Create")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
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
                }
            }
            .padding(isCompact ? 20 : 32)
        }
        .frame(height: isCompact ? 190 : 220)
    }
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

enum CreateProjectMode: String, Identifiable, CaseIterable {
    case uiDesign
    case screenshots

    var id: String { rawValue }

    var title: String {
        switch self {
        case .uiDesign:
            return "UI Design"
        case .screenshots:
            return "App Store Screenshots"
        }
    }

    var subtitle: String {
        switch self {
        case .uiDesign:
            return "Build an interface, prototype, or full app screen."
        case .screenshots:
            return "Create polished launch visuals for the App Store."
        }
    }

    var symbolName: String {
        switch self {
        case .uiDesign:
            return "square.grid.2x2"
        case .screenshots:
            return "photo.on.rectangle.angled"
        }
    }

    var accentColor: Color {
        switch self {
        case .uiDesign:
            return .blue
        case .screenshots:
            return .purple
        }
    }

    var defaultProjectName: String {
        switch self {
        case .uiDesign:
            return "Untitled"
        case .screenshots:
            return "App Store Screenshots"
        }
    }
}

struct CreateProjectSheet: View {
    @Binding var designName: String
    let onCreate: (CreateProjectMode, String) -> Void
    let onCancel: () -> Void

    @State private var selectedMode: CreateProjectMode?
    @FocusState private var isFocused: Bool
    private let maxNameLength = 50

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    if let selectedMode {
                        selectedModeSummary(selectedMode)
                        nameField
                    } else {
                        modeChoices
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if let selectedMode {
                        Button("Create") {
                            onCreate(selectedMode, designName.isEmpty ? selectedMode.defaultProjectName : designName)
                        }
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
            .onDisappear {
                selectedMode = nil
                designName = ""
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(selectedMode == nil ? "What are you creating?" : "Name your project")
                .font(.title2)
                .fontWeight(.semibold)

            Text(selectedMode == nil ? "Pick a starting point for this project." : "Give it a name and we’ll open it in the editor.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var modeChoices: some View {
        VStack(spacing: 14) {
            ForEach(CreateProjectMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedMode = mode
                    }
                } label: {
                    modeCard(mode)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func modeCard(_ mode: CreateProjectMode) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(mode.accentColor.opacity(0.16))
                    .frame(width: 52, height: 52)

                Image(systemName: mode.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(mode.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func selectedModeSummary(_ mode: CreateProjectMode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(mode.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title)
                    .font(.headline)
                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Change") {
                withAnimation(.easeInOut(duration: 0.18)) {
                    selectedMode = nil
                    designName = ""
                }
            }
            .font(.caption.weight(.semibold))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(modeBackgroundColor(for: mode).opacity(0.12))
        )
    }

    private func modeBackgroundColor(for mode: CreateProjectMode) -> Color {
        mode.accentColor
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Project Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(designName.count)/\(maxNameLength)")
                    .font(.caption)
                    .foregroundColor(designName.count > maxNameLength ? .red : .secondary)
            }

            TextField("Project Name", text: $designName)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onSubmit {
                    if let selectedMode {
                        onCreate(selectedMode, designName.isEmpty ? selectedMode.defaultProjectName : designName)
                    }
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(fieldBackgroundColor)
                .cornerRadius(12)
                .overlay(nameFieldBorder)
                .shadow(color: isFocused ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                .onChange(of: designName) { _, newValue in
                    if newValue.count > maxNameLength {
                        designName = String(newValue.prefix(maxNameLength))
                    }
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
}

struct NewDesignSheet: View {
    @Binding var designName: String
    let onCreate: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    private let maxNameLength = 50
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create New Design")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                nameField
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

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Design Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(designName.count)/\(maxNameLength)")
                    .font(.caption)
                    .foregroundColor(designName.count > maxNameLength ? .red : .secondary)
            }

            TextField("Design Name", text: $designName)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onSubmit {
                    if !designName.isEmpty {
                        onCreate(designName)
                    }
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(fieldBackgroundColor)
                .cornerRadius(12)
                .overlay(nameFieldBorder)
                .shadow(color: isFocused ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                .onChange(of: designName) { _, newValue in
                    if newValue.count > maxNameLength {
                        designName = String(newValue.prefix(maxNameLength))
                    }
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
        #if os(macOS)
        return NSImage(named: name) != nil
        #else
        return UIImage(named: name) != nil
        #endif
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
                       let image = createImage(from: thumbnailData) {
#if os(macOS)
                        Image(nsImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
#else
                        Image(uiImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
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
