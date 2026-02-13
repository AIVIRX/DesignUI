//
//  ComponentActionsSectionView.swift
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
}
