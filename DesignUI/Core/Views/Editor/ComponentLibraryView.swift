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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Define the custom sort order for prioritization
    private let componentOrder: [ComponentType] = [
        .text, .image, .sfSymbol, // Core Content
        .vstack, .hstack, .zstack, .scrollView, .spacer, .divider, // Layout
        .shape, // Shapes
        .linearGradient, // Styles
        .button, .textField, .toggle, .slider, .gauge // Controls
    ]
    
    private var filteredComponents: [ComponentType] {
        // First filter by availability (excluding internal types like statusBar) and search text
        let filtered = ComponentType.allCases.filter { type in
            guard type != .statusBar else { return false }
            // Filter out legacy individual shape types
            if type == .rectangle || type == .circle || type == .roundedRectangle || type == .capsule || type == .ellipse {
                return false
            }
            if searchText.isEmpty { return true }
            return type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
        
        // Then sort based on the defined order
        return filtered.sorted { (lhs, rhs) -> Bool in
            let lhsIndex = componentOrder.firstIndex(of: lhs) ?? Int.max
            let rhsIndex = componentOrder.firstIndex(of: rhs) ?? Int.max
            
            if lhsIndex != rhsIndex {
                return lhsIndex < rhsIndex
            } else {
                // If neither is in the explicit list (or both same unexpected index), sort alphabetically
                return lhs.rawValue < rhs.rawValue
            }
        }
    }
    
    var body: some View {
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
            
            // Components Grid
            ScrollView {
                let columns = horizontalSizeClass == .compact
                    ? [GridItem(.flexible(), spacing: 12)]
                    : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredComponents) { componentType in
                        ComponentLibraryItem(
                            componentType: componentType,
                            isFirstComponent: canvasManager.components.isEmpty,
                            onAdd: { component in
                                addComponent(component)
                            }
                        )
                    }
                }
                .padding(12)
            }
        }
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        .environment(\.layoutDirection, .leftToRight)
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }
    
    private func addComponent(_ component: UIComponent) {
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
}

struct ComponentLibraryItem: View {
    let componentType: ComponentType
    let isFirstComponent: Bool
    let onAdd: (UIComponent) -> Void
    
    @State private var isPressed = false
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon/Thumbnail Container
            ZStack {
                // Background for the thumbnail area
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                // Try to load the asset image
                Group {
                    #if os(iOS)
                    if let uiImage = UIImage(named: componentType.assetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    } else {
                        // Fallback to SF Symbol
                        Image(systemName: componentType.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor((componentType == .vstack || componentType == .hstack || componentType == .zstack || componentType == .scrollView || componentType == .spacer || componentType == .divider || componentType == .rectangle || componentType == .circle || componentType == .roundedRectangle || componentType == .capsule || componentType == .ellipse) ? .secondary : (componentType == .text ? .primary : .accentColor))
                    }
                    #else
                    if let nsImage = NSImage(named: componentType.assetName) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    } else {
                        // Fallback to SF Symbol
                        Image(systemName: componentType.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor((componentType == .vstack || componentType == .hstack || componentType == .zstack || componentType == .scrollView || componentType == .spacer || componentType == .divider || componentType == .rectangle || componentType == .circle || componentType == .roundedRectangle || componentType == .capsule || componentType == .ellipse) ? .secondary : (componentType == .text ? .primary : .accentColor))
                    }
                    #endif
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Title
            Text(componentType.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Add Button (Visual Indicator)
             Image(systemName: "plus.circle.fill")
                .foregroundColor(isHovering ? .accentColor : .clear)
                .scaleEffect(isHovering ? 1.0 : 0.5)
                .opacity(isHovering ? 1.0 : 0.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)

        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPressed ? Color.accentColor.opacity(0.15) : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
        )
        .contentShape(Rectangle()) // Ensure entire row is tappable
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { isHovering = $0 }
        .onTapGesture {
            isPressed = true
            
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
            
            // Special case: Add default Text child to Button
            if componentType == .button {
                let textChild = UIComponent(
                    type: .text,
                    properties: [
                        ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Continue", defaultValue: "Continue")
                    ],
                    frame: .zero
                )
                component.addChild(textChild)
            }
            
            onAdd(component)
            
            // Reset press state after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}
