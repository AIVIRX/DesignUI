//
//  ComponentLibraryView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
struct ComponentLibraryView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    @State private var searchText = ""
    
    private var filteredComponents: [ComponentType] {
        let components = ComponentType.allCases
            .filter { $0 != .statusBar } // Exclude status bar from component library
        
        if searchText.isEmpty {
            return components
        } else {
            return components.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search components...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(16)
                
                Divider()
                
                // Components grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 8)
                ], spacing: 8) {
                    ForEach(filteredComponents) { componentType in
                        ComponentLibraryItem(
                            componentType: componentType,
                            isFirstComponent: canvasManager.components.isEmpty,
                            onAdd: { component in
                                if let selected = selectedComponent {
                                    if canvasManager.canAcceptChildren(selected) {
                                        // Selected is a container - add as child
                                        canvasManager.registerUndoAction("Added \(component.type.rawValue) to \(selected.type.rawValue)")
                                        component.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: .zero)
                                        selected.addChild(component)
                                        canvasManager.selectedComponent = component
                                    } else if let parent = canvasManager.findParentComponent(of: selected.id) {
                                        // Selected is not a container but has a parent - add as sibling
                                        canvasManager.registerUndoAction("Added \(component.type.rawValue)")
                                        component.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: .zero)
                                        
                                        // Insert after the selected component
                                        if let index = parent.children.firstIndex(where: { $0.id == selected.id }) {
                                            parent.children.insert(component, at: index + 1)
                                        } else {
                                            parent.addChild(component)
                                        }
                                        canvasManager.selectedComponent = component
                                    } else {
                                        // Selected is at root level and can't accept children - add to root
                                        canvasManager.addComponent(component)
                                    }
                                } else {
                                    // No selection - add to root
                                    canvasManager.addComponent(component)
                                }
                            }
                        )
                    }
                }
                .padding(12)
            }
        }
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }
}

struct ComponentLibraryItem: View {
    let componentType: ComponentType
    let isFirstComponent: Bool
    let onAdd: (UIComponent) -> Void
    
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Icon
            Image(systemName: componentType.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
            
            // Title
            Text(componentType.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPressed ? Color.accentColor.opacity(0.25) : (isHovering ? Color.secondary.opacity(0.1).opacity(0.9) : Color.secondary.opacity(0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.7)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { isHovering = $0 }
        .onTapGesture {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            #endif
            // Create and add component to canvas. First component centers (0,0 relies on renderer fallback), subsequent at a small offset.
            let defaultOrigin = isFirstComponent ? CGPoint(x: 0, y: 0) : CGPoint(x: 100, y: 100)
            let component = UIComponent(
                type: componentType,
                properties: UIComponent.defaultProperties(for: componentType),
                frame: CGRect(origin: defaultOrigin, size: .zero)
            )
            onAdd(component)
        }
    }
}
