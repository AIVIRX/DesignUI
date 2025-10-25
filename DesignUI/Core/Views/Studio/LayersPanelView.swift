//
//  LayersPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct LayersPanelView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    @State private var showComponentLibrary = false
    @State private var expanded: Set<UUID> = []
    @State private var dragOverTarget: UUID?
    @State private var dragOverPosition: DropPosition = .none
    @State private var draggingId: UUID?
    @State private var cleanupTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toolbar
            VStack(spacing: 0) {
                HStack {
                    Text("Layers")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Toolbar
                    Button(action: { showComponentLibrary = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .help("Add Component")
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
                        
            // Layers outline
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(canvasManager.components) { component in
                        OutlineRow(
                            component: component,
                            level: 0,
                            expanded: $expanded,
                            selectedComponent: $selectedComponent,
                            dragOverTarget: $dragOverTarget,
                            dragOverPosition: $dragOverPosition,
                            draggingId: $draggingId,
                            onDelete: { 
                                canvasManager.removeComponent(component)
                                if selectedComponent?.id == component.id {
                                    selectedComponent = nil
                                }
                            },
                            onMove: { sourceId, parentId, index in
                                canvasManager.moveComponentInHierarchy(componentId: sourceId, newParentId: parentId, toIndex: index)
                            },
                            getParentOf: { id in
                                findParentId(of: id, in: canvasManager.components)
                            },
                            getIndexInParent: { id in
                                indexInParent(of: id, in: canvasManager.components)
                            }
                        )
                    }
                    if canvasManager.components.isEmpty {
                        EmptyLayersState()
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .background(Color.clear)
            // Ensure drop preview clears if a drag operation ends anywhere
            .onChange(of: draggingId) { _, newValue in
                if newValue == nil {
                    // Cancel any existing timer
                    cleanupTimer?.invalidate()
                    
                    // Set a timer to ensure cleanup happens
                    cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOverTarget = nil
                            dragOverPosition = .none
                        }
                    }
                }
            }
        }
        .onAppear {
            // Auto-expand all parent components
            expandAllParents()
        }
        .onChange(of: canvasManager.components) { _, _ in
            // Re-expand when components change
            expandAllParents()
        }
        .popover(isPresented: $showComponentLibrary) {
            ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager)
                .frame(width: 500, height: 400)
        }
    }
    
    private func expandAllParents() {
        var allParentIds: Set<UUID> = []
        
        func collectParentIds(from components: [UIComponent]) {
            for component in components {
                if !component.children.isEmpty {
                    allParentIds.insert(component.id)
                    collectParentIds(from: component.children)
                }
            }
        }
        
        collectParentIds(from: canvasManager.components)
        expanded = allParentIds
    }
    
}

// MARK: - Helper Functions
private func componentDisplayName(_ component: UIComponent) -> String {
    switch component.type {
    case .text:
        let text = component.getProperty(key: "text") as? String ?? "Text"
        return text.isEmpty ? "Text" : (text.count > 20 ? String(text.prefix(20)) + "..." : text)
    case .button:
        let title = component.getProperty(key: "title") as? String ?? "Button"
        return title.isEmpty ? "Button" : (title.count > 20 ? String(title.prefix(20)) + "..." : title)
    case .image:
        let imageName = component.getProperty(key: "imageName") as? String ?? "Image"
        return imageName.isEmpty ? "Image" : (imageName.count > 20 ? String(imageName.prefix(20)) + "..." : imageName)
    default:
        return component.type.rawValue
    }
}

// MARK: - Hierarchy helpers
private func findParentId(of targetId: UUID, in roots: [UIComponent]) -> UUID? {
    for root in roots {
        if root.children.contains(where: { $0.id == targetId }) {
            return root.id
        }
        if let id = findParentId(of: targetId, in: root.children) {
            return id
        }
    }
    return nil
}

private func indexInParent(of targetId: UUID, in roots: [UIComponent]) -> Int {
    if let index = roots.firstIndex(where: { $0.id == targetId }) {
        return index
    }
    for root in roots {
        if let idx = root.children.firstIndex(where: { $0.id == targetId }) {
            return idx
        }
        let idx = indexInParent(of: targetId, in: root.children)
        if idx != -1 {
            return idx
        }
    }
    return -1
}

private func canAcceptChildren(_ component: UIComponent) -> Bool {
    switch component.type {
    case .scrollView, .vstack, .hstack, .zstack, .list, .navigationView, .tabView, .form:
        return true
    default:
        return false
    }
}

private enum DropPosition { case none, above, inside, below }

private struct EmptyLayersState: View {
    var body: some View {
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

private struct OutlineRow: View {
    @ObservedObject var component: UIComponent
    let level: Int
    @Binding var expanded: Set<UUID>
    @Binding var selectedComponent: UIComponent?
    @Binding var dragOverTarget: UUID?
    @Binding var dragOverPosition: DropPosition
    @Binding var draggingId: UUID?
    let onDelete: () -> Void
    let onMove: (_ sourceId: UUID, _ newParentId: UUID?, _ index: Int) -> Void
    let getParentOf: (UUID) -> UUID?
    let getIndexInParent: (UUID) -> Int
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            row
            if expanded.contains(component.id) {
                ForEach(component.children) { child in
                    OutlineRow(
                        component: child,
                        level: level + 1,
                        expanded: $expanded,
                        selectedComponent: $selectedComponent,
                        dragOverTarget: $dragOverTarget,
                        dragOverPosition: $dragOverPosition,
                        draggingId: $draggingId,
                        onDelete: { 
                            component.removeChild(child)
                            if selectedComponent?.id == child.id {
                                selectedComponent = nil
                            }
                        },
                        onMove: onMove,
                        getParentOf: getParentOf,
                        getIndexInParent: getIndexInParent
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
    }
    
    private var row: some View {
        VStack(spacing: 0) {
            rowContent
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(backgroundShape)
                .overlay(dragOverlay)
                .overlay(dropZoneOverlay)
                .overlay(borderOverlay)
                .contentShape(Rectangle())
                .onTapGesture { selectedComponent = component }
                .onHover { isHovered = $0 }
                .onDrag { dragAction }
                .onDrop(of: [UTType.plainText], delegate: dropDelegate)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 8) {
            indentationSpacers
            expandCollapseButton
            componentIcon
            componentName
            Spacer()
            deleteButton
        }
    }
    
    private var indentationSpacers: some View {
        HStack(spacing: 0) {
            ForEach(0..<level, id: \.self) { _ in
                Spacer().frame(width: 16)
            }
        }
    }
    
    private var expandCollapseButton: some View {
        Group {
            if !component.children.isEmpty {
                Button(action: { toggleExpand() }) {
                    Image(systemName: expanded.contains(component.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Spacer().frame(width: 12)
            }
        }
    }
    
    private var componentIcon: some View {
        HStack(spacing: 2) {
            Image(systemName: component.type.icon)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(width: 20)
    }
    
    private var componentName: some View {
        Text(componentDisplayName(component))
            .font(.system(size: 13, weight: level == 0 ? .semibold : .medium))
            .foregroundColor((selectedComponent?.id == component.id) ? .primary : .secondary)
            .lineLimit(1)
    }
    
    private var deleteButton: some View {
        Group {
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
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundFill)
    }
    
    private var backgroundFill: Color {
        if selectedComponent?.id == component.id {
            return Color.accentColor.opacity(0.12)
        } else if isHovered {
            return Color.secondary.opacity(0.1)
        } else {
            return Color.secondary.opacity(0.1).opacity(0.6)
        }
    }
    
    private var dragOverlay: some View {
        VStack(spacing: 0) {
            if dragOverTarget == component.id && dragOverPosition == .above {
                Divider().overlay(Color.accentColor).frame(height: 2)
            }
            Spacer(minLength: 0)
            if dragOverTarget == component.id && dragOverPosition == .below {
                Divider().overlay(Color.accentColor).frame(height: 2)
            }
        }
    }
    
    private var dropZoneOverlay: some View {
        Group {
            if dragOverTarget == component.id && dragOverPosition == .inside && canAcceptChildren(component) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .padding(2)
            }
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: 1)
    }
    
    private var borderColor: Color {
        if selectedComponent?.id == component.id {
            return Color.accentColor.opacity(0.6)
        } else {
            return Color.white.opacity(0.06)
        }
    }
    
    private var dragAction: NSItemProvider {
        draggingId = component.id
        return NSItemProvider(object: component.id.uuidString as NSString)
    }
    
    private var dropDelegate: RowDropDelegate {
        RowDropDelegate(
            target: component,
            draggingId: $draggingId,
            dragOverTarget: $dragOverTarget,
            dragOverPosition: $dragOverPosition,
            expanded: $expanded,
            getParentOf: getParentOf,
            getIndexInParent: getIndexInParent,
            onMove: onMove
        )
    }
    
    private func toggleExpand() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expanded.contains(component.id) {
                expanded.remove(component.id)
            } else {
                expanded.insert(component.id)
            }
        }
    }
}

private struct RowDropDelegate: DropDelegate {
    let target: UIComponent
    @Binding var draggingId: UUID?
    @Binding var dragOverTarget: UUID?
    @Binding var dragOverPosition: DropPosition
    @Binding var expanded: Set<UUID>
    let getParentOf: (UUID) -> UUID?
    let getIndexInParent: (UUID) -> Int
    let onMove: (_ sourceId: UUID, _ newParentId: UUID?, _ index: Int) -> Void
    
    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText])
    }
    
    func dropEntered(info: DropInfo) {
        dragOverTarget = target.id
        updatePosition(info: info)
        // Auto-expand when hovering a container
        if canAcceptChildren(target) {
            _ = withAnimation(.easeInOut(duration: 0.15)) {
                expanded.insert(target.id)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        dragOverTarget = target.id
        updatePosition(info: info)
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let sourceId = draggingId else { 
            cleanup()
            return false 
        }
        
        let parentId = getParentOf(target.id)
        var insertIndex = getIndexInParent(target.id)
        
        switch dragOverPosition {
        case .above:
            onMove(sourceId, parentId, max(insertIndex, 0))
        case .below:
            insertIndex += 1
            onMove(sourceId, parentId, max(insertIndex, 0))
        case .inside:
            // Only allow inside drop if target can accept children
            if canAcceptChildren(target) {
                _ = withAnimation(.easeInOut(duration: 0.15)) {
                    expanded.insert(target.id)
                }
                onMove(sourceId, target.id, 0)
            } else {
                // treat as below when not a container
                insertIndex += 1
                onMove(sourceId, parentId, max(insertIndex, 0))
            }
        case .none:
            cleanup()
            return false
        }
        
        // Always cleanup after successful drop
        DispatchQueue.main.async {
            cleanup()
        }
        return true
    }
    
    func dropExited(info: DropInfo) {
        if dragOverTarget == target.id {
            dragOverTarget = nil
            dragOverPosition = .none
        }
    }

    func dropEnded(info: DropInfo) {
        // Defensive clear to ensure preview lines are removed
        DispatchQueue.main.async {
            dragOverTarget = nil
            dragOverPosition = .none
            draggingId = nil
        }
    }
    
    private func updatePosition(info: DropInfo) {
        let y = info.location.y
        let height = 36.0 // Approximate row height
        
        if y < height * 0.25 {
            dragOverPosition = .above
        } else if y > height * 0.75 {
            dragOverPosition = .below
        } else {
            // Inside drop zone - only allow for containers
            if canAcceptChildren(target) {
                dragOverPosition = .inside
            } else {
                // For non-containers, default to below
                dragOverPosition = .below
            }
        }
    }
    
    private func cleanup() {
        DispatchQueue.main.async {
            draggingId = nil
            dragOverTarget = nil
            dragOverPosition = .none
        }
    }
}

struct LayerItem: View {
    @ObservedObject var component: UIComponent
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Component icon
            Image(systemName: component.type.icon)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 16)
            
            // Component name
            Text(component.type.rawValue)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            Spacer()
            
            
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
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
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
