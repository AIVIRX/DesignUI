//
//  CanvasManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

class CanvasManager: ObservableObject {
    @Published var components: [UIComponent] = []
    @Published var selectedComponent: UIComponent?
    @Published var zoomLevel: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    
    // Undo/Redo
    private var undoStack: [CanvasState] = []
    private var redoStack: [CanvasState] = []
    private let maxUndoSteps = 50
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    init() {
        saveState()
    }
    
    // MARK: - Component Management
    func addComponent(_ component: UIComponent) {
        components.append(component)
        selectedComponent = component
        saveState()
    }
    
    func removeComponent(_ component: UIComponent) {
        components.removeAll { $0.id == component.id }
        if selectedComponent?.id == component.id {
            selectedComponent = nil
        }
        saveState()
    }
    
    func selectComponent(_ component: UIComponent) {
        selectedComponent = component
    }
    
    func deselectAll() {
        selectedComponent = nil
    }
    
    // MARK: - Component Manipulation
    func moveComponent(_ component: UIComponent, by offset: CGSize) {
        if let index = components.firstIndex(where: { $0.id == component.id }) {
            components[index].frame.origin.x += offset.width
            components[index].frame.origin.y += offset.height
        }
    }
    
    func resizeComponent(_ component: UIComponent, to newFrame: CGRect) {
        if let index = components.firstIndex(where: { $0.id == component.id }) {
            components[index].frame = newFrame
        }
    }
    
    func duplicateComponent(_ component: UIComponent) {
        let duplicatedComponent = UIComponent(
            type: component.type,
            properties: component.properties,
            children: component.children,
            frame: CGRect(
                x: component.frame.origin.x + 20,
                y: component.frame.origin.y + 20,
                width: component.frame.width,
                height: component.frame.height
            )
        )
        addComponent(duplicatedComponent)
    }
    
    // MARK: - Canvas Controls
    func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 5.0)
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.1)
    }
    
    func resetZoom() {
        zoomLevel = 1.0
        canvasOffset = .zero
    }
    
    func resetZoomAndCenter() {
        // Reset to 1.0 zoom and center
        zoomLevel = 1.0
        canvasOffset = .zero
    }
    
    func resetZoomToFit() {
        // Reset zoom but ensure content fits
        zoomLevel = 1.0
        canvasOffset = .zero
        // Force a zoom to fit to ensure everything is visible
        zoomToFit()
    }
    
    func centerView() {
        canvasOffset = .zero
    }
    
    func setZoomLevel(_ level: CGFloat) {
        zoomLevel = min(max(level, 0.1), 3.0)
    }
    
    func zoomToFit() {
        // If there are components, fit to components
        if !components.isEmpty {
            let minX = components.map { $0.frame.minX }.min() ?? 0
            let minY = components.map { $0.frame.minY }.min() ?? 0
            let maxX = components.map { $0.frame.maxX }.max() ?? 0
            let maxY = components.map { $0.frame.maxY }.max() ?? 0
            
            let contentWidth = maxX - minX
            let contentHeight = maxY - minY
            
            // Add some padding
            let padding: CGFloat = 50
            let targetWidth = contentWidth + padding * 2
            let targetHeight = contentHeight + padding * 2
            
            // Calculate zoom level to fit content
            let zoomX = 1.0 / (targetWidth / 800) // Assuming 800pt canvas width
            let zoomY = 1.0 / (targetHeight / 600) // Assuming 600pt canvas height
            zoomLevel = min(zoomX, zoomY, 1.0)
            
            // Center the content
            canvasOffset = CGSize(
                width: -minX + padding,
                height: -minY + padding
            )
        } else {
            // If no components, just center and reset zoom
            zoomLevel = 1.0
            canvasOffset = .zero
        }
    }
    
    func zoomToFitDevice(_ deviceSize: CGSize, canvasSize: CGSize) {
        // Calculate zoom to fit device within canvas
        let padding: CGFloat = 50
        let availableWidth = canvasSize.width - padding * 2
        let availableHeight = canvasSize.height - padding * 2
        
        let zoomX = availableWidth / deviceSize.width
        let zoomY = availableHeight / deviceSize.height
        
        // Use the smaller zoom to ensure device fits
        zoomLevel = min(zoomX, zoomY, 1.0)
        canvasOffset = .zero
    }
    
    // MARK: - Undo/Redo
    private func saveState() {
        let state = CanvasState(
            components: components.map { $0 },
            selectedComponentId: selectedComponent?.id,
            zoomLevel: zoomLevel,
            canvasOffset: canvasOffset
        )
        
        undoStack.append(state)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        // Clear redo stack when new action is performed
        redoStack.removeAll()
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        let currentState = CanvasState(
            components: components.map { $0 },
            selectedComponentId: selectedComponent?.id,
            zoomLevel: zoomLevel,
            canvasOffset: canvasOffset
        )
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        restoreState(previousState)
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let currentState = CanvasState(
            components: components.map { $0 },
            selectedComponentId: selectedComponent?.id,
            zoomLevel: zoomLevel,
            canvasOffset: canvasOffset
        )
        undoStack.append(currentState)
        
        let nextState = redoStack.removeLast()
        restoreState(nextState)
    }
    
    private func restoreState(_ state: CanvasState) {
        components = state.components
        selectedComponent = components.first { $0.id == state.selectedComponentId }
        zoomLevel = state.zoomLevel
        canvasOffset = state.canvasOffset
    }
    
    // MARK: - Export
    func exportCode() -> String {
        var code = """
        import SwiftUI

        struct GeneratedView: View {
            var body: some View {
        """
        
        if components.isEmpty {
            code += "\n        Text(\"No components added yet\")"
        } else {
            // Create a ZStack to hold all components
            code += "\n        ZStack {"
            
            for component in components {
                let componentCode = CodeGenerator.generateCode(for: component, indentLevel: 3)
                code += "\n" + componentCode
            }
            
            code += "\n        }"
        }
        
        code += "\n    }\n}"
        
        return code
    }
    
    func exportCodeToFile() {
        let code = exportCode()
        
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.swiftSource]
        savePanel.nameFieldStringValue = "GeneratedView.swift"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                try? code.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            }
        }
        #endif
    }
}

// MARK: - Canvas State
struct CanvasState {
    let components: [UIComponent]
    let selectedComponentId: UUID?
    let zoomLevel: CGFloat
    let canvasOffset: CGSize
}
