//
//  DesignBrowserView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct DesignBrowserView: View {
    @StateObject private var designManager = DesignManager()
    @State private var showingNewDesignSheet = false
    @State private var newDesignName = ""
    @State private var showingDeleteAlert = false
    @State private var designToDelete: DesignFile?
    
    var body: some View {
        NavigationStack {
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
        .background(
            NavigationLink(
                destination: designManager.currentDesign != nil ? 
                    AnyView(UIBuilderView(designFile: designManager.currentDesign!, designManager: designManager)) : 
                    AnyView(EmptyView()),
                isActive: Binding(
                    get: { designManager.currentDesign != nil },
                    set: { if !$0 { designManager.closeCurrentDesign() } }
                )
            ) {
                EmptyView()
            }
        )
    }
}

struct DesignCardView: View {
    @ObservedObject var designFile: DesignFile
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
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
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .opacity(isHovered ? 1.0 : 0.0)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
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
            .navigationTitle("New Design")
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

#Preview {
    DesignBrowserView()
}
