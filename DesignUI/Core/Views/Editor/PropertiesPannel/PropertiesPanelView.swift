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
    @State private var activeModifierSheet: ModifierSheet?

    private var componentForModifierSheet: UIComponent? {
        selectedComponent ?? canvasManager.statusBarComponent
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            content
                .navigationDestination(isPresented: $showImageGallery) {
                    ImageGalleryView(selectedImageName: $galleryImageName)
                }
                .navigationDestination(item: $activeModifierSheet) { sheet in
                    if let componentForModifierSheet {
                        switch sheet {
                        case .add:
                            AddModifierView(component: componentForModifierSheet, canvasManager: canvasManager)
                        case .edit(let modifier):
                            ModifierEditorView(component: componentForModifierSheet, modifier: Binding(
                                get: {
                                    componentForModifierSheet.modifiers.first(where: { $0.id == modifier.id }) ?? modifier
                                },
                                set: { newModifier in
                                    DispatchQueue.main.async {
                                        canvasManager.updateModifier(for: componentForModifierSheet, modifier: newModifier)
                                    }
                                }
                            ))
                            .navigationTitle(modifier.type.rawValue)
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    } else {
                        EmptyView()
                    }
                }
        }
        #else
        content
            .sheet(isPresented: $showImageGallery, onDismiss: {
                if !galleryImageName.isEmpty {
                    updateImageProperty(with: galleryImageName)
                }
            }) {
                ImageGalleryView(selectedImageName: $galleryImageName)
            }
        #endif
    }
    
    private var content: some View {
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
                            ModifierPanelView(component: component, canvasManager: canvasManager, activeSheet: $activeModifierSheet)
                                // Force view recreation when component INSTANCE or modifiers change
                                // Using ObjectIdentifier ensures view recreates after undo (new instance, same ID)
                                .id("\(ObjectIdentifier(component))-\(component.modifiers.count)")
                            
                            // Component Actions
                            ComponentActionsSection(component: component, canvasManager: canvasManager, selectedComponent: $selectedComponent)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // Force entire view to update when component INSTANCE changes (not just ID)
                .id(ObjectIdentifier(component))
                .onChange(of: galleryImageName) { _, newName in
                    if !newName.isEmpty {
                        updateImageProperty(with: newName)
                    }
                }
#if os(iOS)
#endif
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
