//
//  DesignBrowserView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
    @State private var showingLimitAlert = false
    
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
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                }
                                .scrollClipDisabled()
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
                                        showingLimitAlert = true
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
                        showingLimitAlert = true
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
        .alert("Free Limit Reached", isPresented: $showingLimitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Subscribe") {
                showingPaywall = true
            }
        } message: {
            Text("Free users are limited to \(freeDesignLimit) designs. Subscribe to create unlimited designs.")
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
                .frame(width: 250, height: 200)
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
                        .frame(width: 30, height: 30)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
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
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 250, height: 200)
                .overlay(
                    renderThumbnail()
                )
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
                .scaleEffect(isHovered ? 1.02 : 1.0)
            
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
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Group {
                    if let thumbnailData = designFile.thumbnail,
                       let image = createImage(from: thumbnailData) {
#if os(macOS)
                        Image(nsImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
#else
                        Image(uiImage: image)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
#endif
                    } else if designFile.components.isEmpty {
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
                            
                            Text("\(designFile.components.count) components")
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
