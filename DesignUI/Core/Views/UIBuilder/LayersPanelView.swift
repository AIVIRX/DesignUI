//
//  LayersPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct LayersPanelView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Layers")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                }
                .help("Add Layer")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Layers list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(canvasManager.components) { component in
                        LayerItem(
                            component: component,
                            isSelected: selectedComponent?.id == component.id,
                            onSelect: { selectedComponent = component },
                            onToggleVisibility: { component.isVisible.toggle() },
                            onDelete: { canvasManager.removeComponent(component) }
                        )
                    }
                    
                    if canvasManager.components.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "square.stack")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            
                            Text("No layers yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Drag components from the library to start building")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
    }
}

struct LayerItem: View {
    @ObservedObject var component: UIComponent
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Visibility toggle
            Button(action: onToggleVisibility) {
                Image(systemName: component.isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 12))
                    .foregroundColor(component.isVisible ? .primary : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help(component.isVisible ? "Hide" : "Show")
            
            // Component icon
            Image(systemName: component.type.icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
                .frame(width: 16)
            
            // Component name
            Text(component.type.rawValue)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .lineLimit(1)
            
            Spacer()
            
            // Z-index indicator
            Text("\(component.zIndex)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            
            // Delete button
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    let canvasManager = CanvasManager()
    
    return LayersPanelView(
        canvasManager: canvasManager,
        selectedComponent: .constant(nil)
    )
    .frame(height: 200)
}
