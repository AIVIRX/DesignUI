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
        HStack(spacing: 10) {
            Spacer()

            Button(action: duplicateComponent) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                    )
            }
            .buttonStyle(PlainButtonStyle())
#if os(macOS)
            .keyboardShortcut("d", modifiers: .command)
#endif

            Button(action: deleteComponent) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.12))
                    )
            }
            .buttonStyle(PlainButtonStyle())
#if os(macOS)
            .keyboardShortcut(.delete, modifiers: .command)
#endif
        }
    }
    
    private func deleteComponent() {
        guard let componentToDelete = selectedComponent else { return }
        canvasManager.removeComponent(componentToDelete)
        selectedComponent = nil
    }
    
    private func duplicateComponent() {
        canvasManager.duplicateComponent(component)
    }
}
