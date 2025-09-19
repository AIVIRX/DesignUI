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
                .background(Color(NSColor.controlBackgroundColor))
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
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Components list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredComponents) { componentType in
                        ComponentLibraryItem(
                            componentType: componentType,
                            onAdd: { component in
                                canvasManager.addComponent(component)
                                selectedComponent = component
                            }
                        )
                    }
                }
                .padding(16)
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
                        .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComponentLibraryItem: View {
    let componentType: ComponentType
    let onAdd: (UIComponent) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: componentType.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            // Title and description
            VStack(alignment: .leading, spacing: 2) {
                Text(componentType.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(componentType.category.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Drag indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isPressed ? Color(NSColor.selectedControlColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            // Create and add component to canvas
            let component = UIComponent(
                type: componentType,
                properties: UIComponent.defaultProperties(for: componentType),
                frame: CGRect(x: 100, y: 100, width: 200, height: 50)
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
                    // Create and add component to canvas
                    let component = UIComponent(
                        type: componentType,
                        properties: UIComponent.defaultProperties(for: componentType),
                        frame: CGRect(x: 100, y: 100, width: 200, height: 50)
                    )
                    onAdd(component)
                }
        )
    }
}


#Preview {
    ComponentLibraryView(selectedComponent: .constant(nil), canvasManager: CanvasManager())
        .frame(width: 280, height: 600)
}
