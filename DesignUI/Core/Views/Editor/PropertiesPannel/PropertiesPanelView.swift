//
//  PropertiesPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(iOS)
import PhotosUI
#endif
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct PropertiesPanelView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    
    // Gallery Sheet State
    @State private var showImageGallery = false
    @State private var galleryImageName = ""
    @State private var activeImagePropertyKey: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            // Properties content
            if let component = selectedComponent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Properties
                        PropertiesSection(
                            component: component,
                            canvasManager: canvasManager,
                            showGallery: $showImageGallery,
                            activePropertyKey: $activeImagePropertyKey
                        )
                                                
                        // Modifiers and Actions - hide for status bar
                        if component.type != .statusBar {
                            ModifierPanelView(component: component, canvasManager: canvasManager)
                                // Force view recreation when component INSTANCE or modifiers change
                                // Using ObjectIdentifier ensures view recreates after undo (new instance, same ID)
                                .id("\(ObjectIdentifier(component))-\(component.modifiers.count)")
                            
                            // Component Actions
                            ComponentActionsSection(component: component, canvasManager: canvasManager, selectedComponent: $selectedComponent)
                        }
                    }
                    .padding()
                }
                // Force entire view to update when component INSTANCE changes (not just ID)
                .id(ObjectIdentifier(component))
                .sheet(isPresented: $showImageGallery, onDismiss: {
                    // Update image property when gallery closes
                    if !galleryImageName.isEmpty {
                        updateImageProperty(with: galleryImageName)
                    }
                }) {
                    ImageGalleryView(selectedImageName: $galleryImageName)
                        .presentationDetents([.medium])
                }
                .onChange(of: galleryImageName) { _, newName in
                    if !newName.isEmpty {
                        updateImageProperty(with: newName)
                    }
                }
            } else if let statusBar = canvasManager.statusBarComponent {
                 // No selection: Show Canvas Settings
                 ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PropertiesSection(
                            component: statusBar,
                            canvasManager: canvasManager,
                            showGallery: $showImageGallery,
                            activePropertyKey: $activeImagePropertyKey
                        )
                    }
                    .padding()
                }
            } else {
                // Fallback No selection state
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No Selection")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Select a component to edit its properties")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateImageProperty(with name: String) {
        guard let component = selectedComponent else { return }
        
        // If we are updating an Image component, we must distinguish between:
        // 1. Files/Assets (names) -> "imageName"
        // 2. Raw Data (base64) -> "imageData" (handled by ImagePickerEditor usually)
        
        // Since this method is called by the Gallery (which returns filenames),
        // we should ALWAYS prefer "imageName" for Image components.
        
        if component.type == .image {
            // Set the name and clear any conflicting data
            canvasManager.updateComponentProperty(for: component, key: "imageName", value: name)
            canvasManager.updateComponentProperty(for: component, key: "imageData", value: "")
        } else {
            // For other components (e.g. background modifiers), use the active key
            if let key = activeImagePropertyKey {
                canvasManager.updateComponentProperty(for: component, key: key, value: name)
                
                // If the key happened to be "imageName", ensure imageData is cleared
                if key == "imageName" {
                    canvasManager.updateComponentProperty(for: component, key: "imageData", value: "")
                }
            } else {
                // Fallback
                canvasManager.updateComponentProperty(for: component, key: "imageName", value: name)
                canvasManager.updateComponentProperty(for: component, key: "imageData", value: "")
            }
        }
        
        component.objectWillChange.send()
    }
}
