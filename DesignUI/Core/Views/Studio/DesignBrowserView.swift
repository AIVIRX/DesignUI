//
//  DesignBrowserView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

#if os(macOS)
struct DesignBrowserView: View {
    @EnvironmentObject private var designManager: DesignManager
    @State private var showingNewDesignSheet = false
    @State private var newDesignName = ""
    @State private var showingDeleteAlert = false
    @State private var designToDelete: DesignFile?
    @State private var showingSettingsMenu = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Simplified Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Designs")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Create and manage your UI designs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Menu {
                            Button("Choose Folder") {
                                designManager.selectDesignsDirectory()
                            }
                            
                            if designManager.isUsingiCloud {
                                Button("Switch to Local Storage") {
                                    designManager.switchToLocal()
                                }
                            } else {
                                Button("Switch to iCloud") {
                                    designManager.switchToiCloud()
                                }
                            }
                            
                            Button("Reset to Default") {
                                designManager.resetToDefaultDirectory()
                            }
                            
                            Divider()
                            
                            Button("Refresh") {
                                designManager.refreshiCloudStatus()
                            }
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingNewDesignSheet = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("New Design")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
                Divider()
                
                // Design Grid
                if designManager.designFiles.isEmpty {
                    // Welcome empty state
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "paintbrush.pointed.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.accentColor)
                            
                            Text("Welcome to DesignUI!")
                                .font(.title)
                                .fontWeight(.semibold)
                            
                            Text("Start creating beautiful UI designs with our intuitive drag-and-drop builder")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Button(action: { showingNewDesignSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Your First Design")
                            }
                            .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
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
        .fileImporter(
            isPresented: $designManager.showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    designManager.setDesignsDirectory(url)
                }
            case .failure(let error):
                print("❌ Failed to select directory: \(error)")
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { designManager.currentDesign != nil },
            set: { if !$0 { designManager.closeCurrentDesign() } }
        )) {
            if let currentDesign = designManager.currentDesign {
                UIBuilderView(designFile: currentDesign)
            } else {
                EmptyView()
            }
        }
    }
}

struct DesignCardView: View {
    @ObservedObject var designFile: DesignFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Design preview
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.accentColor.opacity(0.1), .accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "paintbrush.pointed.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                        Text("Design Preview")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    }
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(designFile.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(designFile.lastModified, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if designFile.components.count > 0 {
                        Text("\(designFile.components.count) components")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Open Design") {
                    onOpen()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .transition(.opacity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct NewDesignSheet: View {
    @Binding var designName: String
    let onCreate: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Create New Design")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Give your design a name to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Design Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter design name", text: $designName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !designName.isEmpty {
                                onCreate(designName)
                            }
                        }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Create Design") {
                        onCreate(designName)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(designName.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 420, height: 280)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}
#endif
