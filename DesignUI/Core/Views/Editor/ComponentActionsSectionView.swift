//
//  ComponentActionsSectionView.swift
//  DesignUI
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

struct ComponentActionsSection: View {
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Duplicate Button
            Button(action: duplicateComponent) {
                HStack {
                    Text("Duplicate")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete Button
            Button(action: deleteComponent) {
                HStack {
                    Text("Delete Component")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.red)
                    
                    Spacer()
                    
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
#if os(macOS)
            .keyboardShortcut(.delete, modifiers: [])
#endif
        }
    }
    
    private func deleteComponent() {
        // Use selectedComponent binding to ensure we delete the CURRENTLY selected component
        guard let componentToDelete = selectedComponent else { return }
        
        // Remove the component from the canvas
        canvasManager.removeComponent(componentToDelete)
        
        // Clear the selection
        selectedComponent = nil
    }
    
    private func duplicateComponent() {
        // Use CanvasManager's duplicateComponent which has proper undo registration
        canvasManager.duplicateComponent(component)
    }
    
    private func findParentComponent(of targetComponent: UIComponent, in components: [UIComponent]) -> UIComponent? {
        for component in components {
            if component.children.contains(where: { $0.id == targetComponent.id }) {
                return component
            }
            if let found = findParentComponent(of: targetComponent, in: component.children) {
                return found
            }
        }
        return nil
    }
    
    private func createDeepCopy(of component: UIComponent) -> UIComponent {
        // Create a new component with the same type
        let newComponent = UIComponent(type: component.type)
        
        // Copy all properties
        newComponent.properties = component.properties.map { property in
            ComponentProperty(
                key: property.key,
                displayName: property.displayName,
                type: property.type,
                value: property.value,
                defaultValue: property.defaultValue,
                options: property.options,
            )
        }
        
        // Copy all modifiers with their properties
        newComponent.modifiers = component.modifiers.map { modifier in
            ComponentModifier(
                type: modifier.type,
                properties: modifier.properties
            )
        }
        
        // Copy frame with a slight offset so it's visible
        newComponent.frame = CGRect(
            x: component.frame.origin.x + 20,
            y: component.frame.origin.y + 20,
            width: component.frame.width,
            height: component.frame.height
        )
        
        // Recursively copy children
        newComponent.children = component.children.map { child in
            createDeepCopy(of: child)
        }
        
        return newComponent
    }
}

// MARK: - SF Symbol Picker View

