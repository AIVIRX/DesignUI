//
//  LayersPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
struct LayersPanelView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    @State private var showComponentLibrary = false
    @State private var expanded: Set<UUID> = []
    @State private var dragOverTarget: UUID?
    @State private var dragOverPosition: DropPosition = .none
    @State private var draggingId: UUID?
    
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
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
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
                            onDelete: { canvasManager.removeComponent(component) },
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
            // Ensure drop preview clears if a drag operation ends anywhere
            .onChange(of: draggingId) { _, newValue in
                if newValue == nil {
                    dragOverTarget = nil
                    dragOverPosition = .none
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
    case .scrollView, .vstack, .hstack, .zstack, .list, .navigationView, .tabView, .form, .section:
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
                        onDelete: { component.removeChild(child) },
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
            HStack(spacing: 8) {
                // Expand/Collapse
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
                
                // Icon
                Image(systemName: component.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 16)
                
                // Name
                Text(component.type.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor((selectedComponent?.id == component.id) ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        (selectedComponent?.id == component.id)
                        ? Color.accentColor.opacity(0.12)
                        : (isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.6))
                    )
            )
            .overlay(
                VStack(spacing: 0) {
                    if dragOverTarget == component.id && dragOverPosition == .above {
                        Divider().overlay(Color.accentColor).frame(height: 2)
                    }
                    Spacer(minLength: 0)
                    if dragOverTarget == component.id && dragOverPosition == .below {
                        Divider().overlay(Color.accentColor).frame(height: 2)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        (selectedComponent?.id == component.id) ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture { selectedComponent = component }
            .onHover { isHovered = $0 }
            .onDrag {
                draggingId = component.id
                return NSItemProvider(object: component.id.uuidString as NSString)
            }
            .onDrop(of: [UTType.plainText], delegate: RowDropDelegate(
                target: component,
                draggingId: $draggingId,
                dragOverTarget: $dragOverTarget,
                dragOverPosition: $dragOverPosition,
                expanded: $expanded,
                getParentOf: getParentOf,
                getIndexInParent: getIndexInParent,
                onMove: onMove
            ))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
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
        guard let sourceId = draggingId else { return false }
        let parentId = getParentOf(target.id)
        var insertIndex = getIndexInParent(target.id)
        switch dragOverPosition {
        case .above:
            break
        case .below:
            insertIndex += 1
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
            cleanup()
            return true
        case .none:
            cleanup()
            return false
        }
        onMove(sourceId, parentId, max(insertIndex, 0))
        cleanup()
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
        dragOverTarget = nil
        dragOverPosition = .none
    }
    
    private func updatePosition(info: DropInfo) {
        let y = info.location.y
        if y < 10 {
            dragOverPosition = .above
        } else if y > 26 {
            dragOverPosition = .below
        } else {
            dragOverPosition = .inside
        }
    }
    
    private func cleanup() {
        draggingId = nil
        dragOverTarget = nil
        dragOverPosition = .none
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
#endif
