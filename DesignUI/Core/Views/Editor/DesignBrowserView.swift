//
//  DesignBrowserView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct DesignBrowserView: View {
    @EnvironmentObject private var designManager: DesignManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingNewDesignSheet = false
    @State private var newDesignName = ""
    @State private var showingDeleteAlert = false
    @State private var designToDelete: DesignFile?
    @State private var showingRenameSheet = false
    @State private var designToRename: DesignFile?
    @State private var renameText = ""
    @State private var showingPaywall = false
    
    // Free tier limit
    private let freeDesignLimit = 3
    
    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // User's Designs Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Designs")
                                .font(.title2)
                                .fontWeight(.bold)
                .padding(.horizontal)
                
                if designManager.designFiles.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Designs Yet")
                                        .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Create your first design to get started")
                            .foregroundColor(.secondary)
                        
                        Button("Create New Design") {
                            showingNewDesignSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                            ForEach(designManager.designFiles) { designFile in
                                DesignCardView(
                                    designFile: designFile,
                                    onOpen: { designManager.openDesign(designFile) },
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
                                            .frame(width: 280)
                            }
                        }
                                    .padding(.horizontal)
                    }
                }
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Templates Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Templates")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            TemplatesGridView(
                                onSelectTemplate: { template in
                                    // Check if user can create more designs
                                    if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                                        showingPaywall = true
                                    } else {
                                        let name = template.name
                                        let newDesign = designManager.createDesignFromTemplate(template: template, name: name)
                                        designManager.openDesign(newDesign)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical)
                }
            }
        .navigationTitle("Design Browser")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Check if user can create more designs
                    if !subscriptionManager.isSubscribed && designManager.designFiles.count >= freeDesignLimit {
                        showingPaywall = true
                    } else {
                        showingNewDesignSheet = true
                    }
                }) {
                    Label("New Design", systemImage: "plus")
                }
            }
        }
            }
        .sheet(isPresented: $showingNewDesignSheet) {
            NewDesignSheet(
                designName: $newDesignName,
                onCreate: { name in
                    let newDesign = designManager.createNewDesign(name: name)
                    designManager.openDesign(newDesign)
                    showingNewDesignSheet = false
                    newDesignName = ""
                },
                onCancel: {
                    showingNewDesignSheet = false
                    newDesignName = ""
                }
            )
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
        #else
        .navigationDestination(isPresented: Binding(
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
                .frame(height: 200)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
                .scaleEffect(isHovered ? 1.02 : 1.0)
            
            // Name and menu row
            HStack {
                Text(designFile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Menu {
                    Button("Rename") {
                        onRename()
                    }
                    
                    #if os(macOS)
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([designFile.fileURL])
                    }
                    #endif
                    
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .pointerStyle(.link)
                #endif
            }
        }
        .padding(.vertical, 8) // Prevent clipping during scale animation
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create New Design")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Design Name", text: $designName)
                    .textFieldStyle(.roundedBorder)
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
        }
    }
}

struct RenameDesignSheet: View {
    @Binding var designName: String
    let onRename: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Rename Design")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Design Name", text: $designName)
                    .textFieldStyle(.roundedBorder)
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
        }
    }
}

struct TemplatesGridView: View {
    let onSelectTemplate: (DesignTemplate) -> Void
    
    private let templateManager = DesignTemplateManager.shared
    
    var body: some View {
        // Templates Grid
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
                    .frame(width: 200)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TemplateCardView: View {
    let template: DesignTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: template.thumbnail)
                .font(.system(size: 50))
                .foregroundColor(.primary)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Use Template") {
                onSelect()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Canvas Preview
struct CanvasPreviewView: View {
    @ObservedObject var designFile: DesignFile
    
    var body: some View {
        ZStack {
            // Background
            Color.gray.opacity(0.1)
            
            if let thumbnailData = designFile.thumbnail,
               let image = createImage(from: thumbnailData) {
                // Get device type and aspect ratio from stored device preset

                let aspectRatio = getAspectRatio(for: designFile.devicePreset)
                
                // Use aspectRatio modifier to fit within the area without stretching
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .allowsHitTesting(false)
                #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .allowsHitTesting(false)
                #endif
            } else if designFile.components.isEmpty {
                // Empty state
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("Empty Design")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Fallback: show component count if no thumbnail yet
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("\(designFile.components.count) components")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("Tap to open")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Device Type Detection
    private enum DeviceType {
        case iPhone
        case iPad
        case mac
        
        var cornerRadius: CGFloat {
            switch self {
            case .iPhone: return 8 // Smaller rounded corners for preview
            case .iPad: return 6 // Slightly rounded for iPad preview
            case .mac: return 4 // Minimal rounding for Mac preview
            }
        }
    }
    
    private func getDeviceType(from devicePreset: String?, aspectRatio: CGFloat, size: CGSize) -> DeviceType {
        // Use stored device preset
        if let preset = devicePreset {
            if preset.lowercased().contains("iphone") {
                return .iPhone
            } else if preset.lowercased().contains("ipad") {
                return .iPad
            } else if preset.lowercased().contains("mac") {
                return .mac
            }
        }
        
        // Fallback: default to iPhone if no preset
        return .iPhone
    }
    
    private func getAspectRatio(for devicePreset: String?) -> CGFloat {
        // Get aspect ratio based on device preset
        guard let preset = devicePreset else {
            // Default to iPhone aspect ratio
            return 9.0 / 19.5
        }
        
        let presetLower = preset.lowercased()
        
        if presetLower.contains("iphone") {
            // iPhone: 19.5:9 ratio in portrait = 9/19.5
            return 9.0 / 19.5
        } else if presetLower.contains("ipad") {
            // iPad: typically 4:3 in portrait = 3/4, but we use width/height so 4/3 for landscape
            // For portrait iPad, it's 834:1194 ≈ 0.699, but let's use 3/4 = 0.75
            return 3.0 / 4.0
        } else if presetLower.contains("mac") {
            // Mac: 16:10 = 1.6
            return 16.0 / 10.0
        }
        
        // Default to iPhone
        return 9.0 / 19.5
    }
    
    #if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
    
    private func getImageSize(_ image: NSImage) -> CGSize {
        return image.size
    }
    #else
    private func createImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    private func getImageSize(_ image: UIImage) -> CGSize {
        return image.size
    }
    #endif
}

// MARK: - Component Preview Renderer
struct ComponentPreviewRenderer: View {
    let component: UIComponent
    let scale: CGFloat
    let containerSize: CGSize
    
    var body: some View {
        ComponentRenderer(
            component: component,
            deviceSize: CGSize(width: 375, height: 667),
            colorScheme: .light,
            onTap: nil,
            onSelectChild: nil,
            selectedComponentIds: []
        )
        .frame(width: component.frame.width, height: component.frame.height)
        .position(
            x: component.frame.midX,
            y: component.frame.midY
        )
    }
}
