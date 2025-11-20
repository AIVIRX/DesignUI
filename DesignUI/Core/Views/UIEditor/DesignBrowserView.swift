//
//  DesignBrowserView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct DesignBrowserView: View {
    @EnvironmentObject private var designManager: DesignManager
    @State private var showingNewDesignSheet = false
    @State private var newDesignName = ""
    @State private var showingDeleteAlert = false
    @State private var designToDelete: DesignFile?
    
    var body: some View {
        VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Design Browser")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingNewDesignSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Design")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Divider()
                
                // Storage Status
                HStack {
//                    Image(systemName: designManager.storageStatus.contains("iCloud") ? "icloud.fill" : "folder.fill")
//                        .foregroundColor(.secondary)
//                    Text(designManager.storageStatus)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    #if os(macOS)
                    Button("Show in Finder") {
                        designManager.showInFinder()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    #endif
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1).opacity(0.5))
                
                Divider()
                
                // Design Grid
                if designManager.designFiles.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Designs Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first design to get started")
                            .foregroundColor(.secondary)
                        
                        Button("Create New Design") {
                            showingNewDesignSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)
                        ], spacing: 20) {
                            ForEach(designManager.designFiles) { designFile in
                                DesignCardView(
                                    designFile: designFile,
                                    onOpen: { designManager.openDesign(designFile) },
                                    onDelete: { 
                                        designToDelete = designFile
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
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
        #if os(iOS)
        .fullScreenCover(isPresented: Binding(
            get: { designManager.currentDesign != nil },
            set: { if !$0 { designManager.closeCurrentDesign() } }
        )) {
            if let currentDesign = designManager.currentDesign {
                UIBuilderView(designFile: currentDesign)
                    .environmentObject(designManager)
            }
        }
        #else
        .navigationDestination(isPresented: Binding(
            get: { designManager.currentDesign != nil },
            set: { if !$0 { designManager.closeCurrentDesign() } }
        )) {
            if let currentDesign = designManager.currentDesign {
                UIBuilderView(designFile: currentDesign)
                    .environmentObject(designManager)
            }
        }
        #endif
    }
}

struct DesignCardView: View {
    @ObservedObject var designFile: DesignFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showingMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Canvas Preview
            CanvasPreviewView(designFile: designFile)
                .frame(height: 120)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(designFile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Modified \(designFile.lastModified, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(designFile.components.count) components")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button("Open") {
                    onOpen()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Menu {
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
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1.0 : 0.0)
            }
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
                
                Text("This will create a new design file that you can start building with.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .frame(width: 400, height: 200)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(designName)
                    }
                    .disabled(designName.isEmpty)
                }
            }
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
            
            if designFile.components.isEmpty {
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
                // Simple preview - just show component count and basic info
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
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
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
            onTap: {},
            onSelectChild: nil,
            selectedComponent: nil
        )
        .frame(width: component.frame.width, height: component.frame.height)
        .position(
            x: component.frame.midX,
            y: component.frame.midY
        )
    }
}
