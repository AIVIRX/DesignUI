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
    @State private var selectedCategory: ComponentCategory? = nil
    
    private var filteredComponents: [ComponentType] {
        let components = selectedCategory == nil ? ComponentType.allCases : ComponentType.allCases.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return components
        } else {
            return components.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Components")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(ComponentCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.1))
            
            Divider()
            
            // Components grid
            ScrollView {
                // Compact, adaptive grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 8)
                ], spacing: 8) {
                    ForEach(filteredComponents) { componentType in
                        ComponentLibraryItem(
                            componentType: componentType,
                            isFirstComponent: canvasManager.components.isEmpty,
                            onAdd: { component in
                                // Check if there's a selected container component
                                if let selected = selectedComponent, 
                                   canvasManager.canAcceptChildren(selected) {
                                    // Reset frame to be relative to container
                                    component.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: .zero)
                                    
                                    // Add directly to container - NEVER add to root level
                                    selected.addChild(component)
                                    selectedComponent = component
                                    canvasManager.saveState()
                                } else {
                                    // Add to main canvas
                                    canvasManager.addComponent(component)
                                }
                            }
                        )
                    }
                }
                .padding(12)
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
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
            
            // Category
            Text(componentType.category.rawValue)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
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
            // Create and add component to canvas. First component centers (0,0 relies on renderer fallback), subsequent at a small offset.
            let defaultOrigin = isFirstComponent ? CGPoint(x: 0, y: 0) : CGPoint(x: 100, y: 100)
            let component = UIComponent(
                type: componentType,
                properties: UIComponent.defaultProperties(for: componentType),
                frame: CGRect(origin: defaultOrigin, size: .zero)
            )
            onAdd(component)
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    // Note: Component creation is handled by onTapGesture to avoid duplicates
                }
        )
    }
}
