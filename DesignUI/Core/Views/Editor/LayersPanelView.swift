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
    var onLayerTapped: ((UIComponent) -> Void)? = nil // Callback for iOS navigation
    @State private var showComponentLibrary = false
    @State private var expanded: Set<UUID> = []
    @State private var expandedOverlayFolders: Set<UUID> = [] // Track overlay folder expansion separately
    @State private var dragOverTarget: UUID?
    @State private var dragOverPosition: DropPosition = .none
    @State private var draggingId: UUID?
    @State private var isDragOverBottom = false
    @State private var isUserInitiatedSelection = false
    @Environment(\.horizontalSizeClass) var hSizeClass

    var body: some View {
        if hSizeClass == .regular {
            regularSizeView
        } else {
            regularSizeView
                .navigationTitle("Layers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem {
                        Button(action: { showComponentLibrary = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                        }
                        .help("Add Component")
                    }
                }
        }
    }
    
    @ViewBuilder
    private var regularSizeView: some View {
        if hSizeClass == .regular {
            VStack(alignment: .leading, spacing: 0) {
                // Header with toolbar
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "square.3.layers.3d.top.filled")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            Text("Layers")
                                .font(.headline).fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        // Toolbar
                        HStack(spacing: 8) {
                            Button(action: { showComponentLibrary = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12))
                            }
                            .help("Add Component")
                            .buttonStyle(.bordered)
                            .frame(width: 28, height: 28)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.clear)
            }
        }
                // Layers outline with scroll-to-selection
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Status Bar (always shown so it can be toggled even when hidden)
                            if let statusBar = canvasManager.statusBarComponent {
                                StatusBarRowView(
                                    statusBar: statusBar,
                                    isSelected: selectedComponent?.id == statusBar.id,
                                    onSelect: {
                                        isUserInitiatedSelection = true
                                        selectedComponent = statusBar
                                        onLayerTapped?(statusBar)
                                    }
                                )
                                .id(statusBar.id)
                            }
                            
                            ForEach(canvasManager.components) { component in
                                // Render overlay folder above component if it has overlay children
                                if !component.getOverlayChildren().isEmpty {
                                    OverlayFolderRow(
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
                                        },
                                        onAddOverlay: {
                                            canvasManager.createOverlayFolder(for: component)
                                        },
                                        expandedOverlayFolders: $expandedOverlayFolders,
                                        onSelect: {
                                            isUserInitiatedSelection = true
                                            selectedComponent = $0
                                            onLayerTapped?($0)
                                        },
                                        onWrap: { component, type in
                                            canvasManager.wrapComponent(component, in: type)
                                        }
                                    )
                                }
                                
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
                                    onDuplicate: {
                                        canvasManager.duplicateComponent(component)
                                    },
                                    onMove: { sourceId, parentId, index in
                                        canvasManager.moveComponentInHierarchy(componentId: sourceId, newParentId: parentId, toIndex: index)
                                    },
                                    getParentOf: { id in
                                        findParentId(of: id, in: canvasManager.components)
                                    },
                                    getIndexInParent: { id in
                                        indexInParent(of: id, in: canvasManager.components)
                                    },
                                    onSelect: {
                                        isUserInitiatedSelection = true
                                        selectedComponent = $0
                                        onLayerTapped?($0)
                                    },
                                    onWrap: { component, type in
                                        canvasManager.wrapComponent(component, in: type)
                                    }
                                )
                                .id(component.id)
                            }
                            if canvasManager.components.isEmpty && canvasManager.statusBarComponent == nil {
                                EmptyLayersState()
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        
                        // Drop zone for moving to end of list (root level)
                        if !canvasManager.components.isEmpty {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 40)
                                .overlay(
                                    VStack {
                                        if isDragOverBottom {
                                            Capsule()
                                                .fill(Color.accentColor)
                                                .frame(height: 4)
                                                .padding(.horizontal, 8)
                                        }
                                        Spacer()
                                    }
                                )
                                .contentShape(Rectangle())
                                .onDrop(of: [UTType.plainText], delegate: BottomDropDelegate(
                                    canvasManager: canvasManager,
                                    draggingId: $draggingId,
                                    isDragOverBottom: $isDragOverBottom
                                ))
                        }
                    }
                    // Auto-scroll to selected component when selection changes
                    .onChange(of: selectedComponent?.id) { _, newId in
                        if let id = newId {
                            // Small delay to allow view hierarchy to settle, then smooth spring animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                if !isUserInitiatedSelection {
                                    // Auto-expand parents so selected component is visible
                                    expandParentsOf(id)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        scrollProxy.scrollTo(id, anchor: .center)
                                    }
                                }
                                isUserInitiatedSelection = false
                            }
                        }
                    }
                }
                // When drag ends (draggingId becomes nil), immediately clear drop indicators
                .onChange(of: draggingId) { _, newValue in
                    if newValue == nil {
                        withAnimation(.easeOut(duration: 0.15)) {
                            dragOverTarget = nil
                            dragOverPosition = .none
                        }
                    }
                }
                .onAppear {
                    // Auto-expand all parent components only on first appear
                    expandAllParents()
                }
                .onChange(of: canvasManager.components) { _, _ in
                    // Don't auto-expand everything - preserve user's collapse state
                    // Only ensure parents of selected component are expanded
                    if let selected = selectedComponent {
                        expandParentsOf(selected.id)
                    }
                    // Auto-expand overlay folders for components that have overlay children
                    for component in canvasManager.components {
                        if !component.getOverlayChildren().isEmpty {
                            expandedOverlayFolders.insert(component.id)
                        }
                    }
                }
        #if os(iOS)
                .navigationDestination(isPresented: $showComponentLibrary) {
                    ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager)
                        .navigationTitle("Components")
                        .navigationBarTitleDisplayMode(.inline)
                }
        #else
                .popover(isPresented: $showComponentLibrary) {
                    ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager)
                        .frame(width: 500, height: 400)
                }
        #endif
            }
    
    private var PhoneSizeView: some View {
                // Layers outline with scroll-to-selection
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Status Bar (always shown so it can be toggled even when hidden)
                            if let statusBar = canvasManager.statusBarComponent {
                                StatusBarRowView(
                                    statusBar: statusBar,
                                    isSelected: selectedComponent?.id == statusBar.id,
                                    onSelect: {
                                        isUserInitiatedSelection = true
                                        selectedComponent = statusBar
                                        onLayerTapped?(statusBar)
                                    }
                                )
                                .id(statusBar.id)
                            }
                            
                            ForEach(canvasManager.components) { component in
                                // Render overlay folder above component if it has overlay children
                                if !component.getOverlayChildren().isEmpty {
                                    OverlayFolderRow(
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
                                        },
                                        onAddOverlay: {
                                            canvasManager.createOverlayFolder(for: component)
                                        },
                                        expandedOverlayFolders: $expandedOverlayFolders,
                                        onSelect: {
                                            isUserInitiatedSelection = true
                                            selectedComponent = $0
                                            onLayerTapped?($0)
                                        },
                                        onWrap: { component, type in
                                            canvasManager.wrapComponent(component, in: type)
                                        }
                                    )
                                }
                                
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
                                    onDuplicate: {
                                        canvasManager.duplicateComponent(component)
                                    },
                                    onMove: { sourceId, parentId, index in
                                        canvasManager.moveComponentInHierarchy(componentId: sourceId, newParentId: parentId, toIndex: index)
                                    },
                                    getParentOf: { id in
                                        findParentId(of: id, in: canvasManager.components)
                                    },
                                    getIndexInParent: { id in
                                        indexInParent(of: id, in: canvasManager.components)
                                    },
                                    onSelect: {
                                        isUserInitiatedSelection = true
                                        selectedComponent = $0
                                        onLayerTapped?($0)
                                    },
                                    onWrap: { component, type in
                                        canvasManager.wrapComponent(component, in: type)
                                    }
                                )
                                .id(component.id)
                            }
                            if canvasManager.components.isEmpty && canvasManager.statusBarComponent == nil {
                                EmptyLayersState()
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        
                        // Drop zone for moving to end of list (root level)
                        if !canvasManager.components.isEmpty {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 40)
                                .overlay(
                                    VStack {
                                        if isDragOverBottom {
                                            Capsule()
                                                .fill(Color.accentColor)
                                                .frame(height: 4)
                                                .padding(.horizontal, 8)
                                        }
                                        Spacer()
                                    }
                                )
                                .contentShape(Rectangle())
                                .onDrop(of: [UTType.plainText], delegate: BottomDropDelegate(
                                    canvasManager: canvasManager,
                                    draggingId: $draggingId,
                                    isDragOverBottom: $isDragOverBottom
                                ))
                        }
                    }
                    // Auto-scroll to selected component when selection changes
                    .onChange(of: selectedComponent?.id) { _, newId in
                        if let id = newId {
                            // Small delay to allow view hierarchy to settle, then smooth spring animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                if !isUserInitiatedSelection {
                                    // Auto-expand parents so selected component is visible
                                    expandParentsOf(id)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        scrollProxy.scrollTo(id, anchor: .center)
                                    }
                                }
                                isUserInitiatedSelection = false
                            }
                        }
                    }
                }
                .navigationTitle("Layers")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.clear)
                // When drag ends (draggingId becomes nil), immediately clear drop indicators
                .onChange(of: draggingId) { _, newValue in
                    if newValue == nil {
                        withAnimation(.easeOut(duration: 0.15)) {
                            dragOverTarget = nil
                            dragOverPosition = .none
                        }
                    }
                }
                .onAppear {
                    // Auto-expand all parent components only on first appear
                    expandAllParents()
                }
                .onChange(of: canvasManager.components) { _, _ in
                    // Don't auto-expand everything - preserve user's collapse state
                    // Only ensure parents of selected component are expanded
                    if let selected = selectedComponent {
                        expandParentsOf(selected.id)
                    }
                    // Auto-expand overlay folders for components that have overlay children
                    for component in canvasManager.components {
                        if !component.getOverlayChildren().isEmpty {
                            expandedOverlayFolders.insert(component.id)
                        }
                    }
                }
        #if os(iOS)
                .navigationDestination(isPresented: $showComponentLibrary) {
                    ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager)
                        .navigationTitle("Components")
                        .navigationBarTitleDisplayMode(.inline)
                }
        #else
                .popover(isPresented: $showComponentLibrary) {
                    ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager)
                        .frame(width: 500, height: 400)
                }
        #endif
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
    
    private func expandParentsOf(_ componentId: UUID) {
        // Only expand the direct parent chain to the selected component
        // This ensures the selected component is visible without expanding everything
        func findAndExpandParents(of targetId: UUID, in components: [UIComponent]) -> Bool {
            for component in components {
                if component.id == targetId {
                    return true
                }
                if findAndExpandParents(of: targetId, in: component.children) {
                    if !component.children.isEmpty {
                        expanded.insert(component.id)
                    }
                    return true
                }
            }
            return false
        }
        
        _ = findAndExpandParents(of: componentId, in: canvasManager.components)
    }
}

private func componentDisplayName(_ component: UIComponent) -> String {
    // If this is a modifier parent component, show the modifier type name
    if let modifierType = component.modifierType {
        return modifierType.rawValue
    }
    
    switch component.type {
    case .text:
        let text = component.getProperty(key: "text") as? String ?? "Text"
        return text.isEmpty ? "Text" : text
    case .image:
        return "Image"
    default:
        return component.type.rawValue
    }
}

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
    // Check if component type can accept children
    switch component.type {
    case .scrollView, .vstack, .hstack, .zstack:
        return true
    default:
        break
    }
    
    // Check if component has modifiers that create parent components (folders)
    // Overlay, mask, and background modifiers create parent components
    let hasFolderModifier = component.modifiers.contains { modifier in
        modifier.type == .overlay || modifier.type == .mask || modifier.type == .background
    }
    
    return hasFolderModifier
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
            Text("Add components from the library to start!")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }
}

private struct StatusBarRowView: View {
    @ObservedObject var statusBar: UIComponent
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Empty space for alignment with other rows
            Spacer().frame(width: 24)
            
            // Status bar icon
            Image(systemName: "battery.100.bolt")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .green)
                .frame(width: 20)
            
            // Label
            Text("Status Bar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundFillColor)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    private var backgroundFillColor: Color {
        if isSelected {
            return .blue
        } else if isHovered {
            return Color.primary.opacity(0.08)
        } else {
            return Color.clear
        }
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
    let onDuplicate: () -> Void
    let onMove: (_ sourceId: UUID, _ newParentId: UUID?, _ index: Int) -> Void
    let getParentOf: (UUID) -> UUID?
    let getIndexInParent: (UUID) -> Int
    let onSelect: (UIComponent) -> Void
    let onWrap: (UIComponent, ComponentType) -> Void
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    init(component: UIComponent, level: Int, expanded: Binding<Set<UUID>>, selectedComponent: Binding<UIComponent?>, dragOverTarget: Binding<UUID?>, dragOverPosition: Binding<DropPosition>, draggingId: Binding<UUID?>, onDelete: @escaping () -> Void, onDuplicate: @escaping () -> Void, onMove: @escaping (_ sourceId: UUID, _ newParentId: UUID?, _ index: Int) -> Void, getParentOf: @escaping (UUID) -> UUID?, getIndexInParent: @escaping (UUID) -> Int, onSelect: @escaping (UIComponent) -> Void, onWrap: @escaping (UIComponent, ComponentType) -> Void) {
        self.component = component
        self.level = level
        self._expanded = expanded
        self._selectedComponent = selectedComponent
        self._dragOverTarget = dragOverTarget
        self._dragOverPosition = dragOverPosition
        self._draggingId = draggingId
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
        self.onMove = onMove
        self.getParentOf = getParentOf
        self.getIndexInParent = getIndexInParent
        self.onSelect = onSelect
        self.onWrap = onWrap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            row
            if expanded.contains(component.id) {
                // Render all children (regular + modifier parents)
                ForEach(component.children.filter { !$0.isOverlay }) { child in
                    OutlineRow(
                        component: child,
                        level: level + 1,
                        expanded: $expanded,
                        selectedComponent: $selectedComponent,
                        dragOverTarget: $dragOverTarget,
                        dragOverPosition: $dragOverPosition,
                        draggingId: $draggingId,
                        onDelete: { 
                            // If it's a modifier parent, also remove the modifier
                            if let modifierId = child.modifierId,
                               let modifier = component.modifiers.first(where: { $0.id == modifierId }) {
                                component.removeModifier(modifier)
                            } else {
                                component.removeChild(child)
                            }
                            if selectedComponent?.id == child.id {
                                selectedComponent = nil
                            }
                        },
                        onDuplicate: {
                            // Copy modifiers with their properties and order
                            let duplicatedModifiers = child.modifiers.map { modifier in
                                ComponentModifier(
                                    type: modifier.type,
                                    properties: modifier.properties
                                )
                            }
                            
                            let duplicatedChild = UIComponent(
                                type: child.type,
                                properties: child.properties,
                                children: child.children,
                                frame: CGRect(
                                    x: child.frame.origin.x + 20,
                                    y: child.frame.origin.y + 20,
                                    width: child.frame.width,
                                    height: child.frame.height
                                ),
                                modifiers: duplicatedModifiers,
                                modifierId: child.modifierId,
                                modifierType: child.modifierType
                            )
                            if let childIndex = component.children.firstIndex(where: { $0.id == child.id }) {
                                component.children.insert(duplicatedChild, at: childIndex + 1)
                            } else {
                                if let modifierId = child.modifierId {
                                    component.addModifierChild(duplicatedChild, modifierId: modifierId)
                                } else {
                                    component.addChild(duplicatedChild)
                                }
                            }
                            selectedComponent = duplicatedChild
                        },
                        onMove: onMove,
                        getParentOf: getParentOf,
                        getIndexInParent: getIndexInParent,
                        onSelect: onSelect,
                        onWrap: onWrap
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
            HStack(spacing: 0) {
                // Indentation spacers (inside background)
                indentationSpacers
                
                // Content (indented, with full-width background)
                rowContent
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(backgroundFill)
            .overlay(dragOverlay)
            .overlay(dropZoneOverlay)
            .contentShape(Rectangle())
            .contextMenu {
                Button(action: {
                    onDuplicate()
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                // Wrap in...
                if component.modifierType == nil && !component.isOverlay {
                    Menu {
                        Button("VStack") { onWrap(component, .vstack) }
                        Button("HStack") { onWrap(component, .hstack) }
                        Button("ZStack") { onWrap(component, .zstack) }
                        Button("ScrollView") { onWrap(component, .scrollView) }
                    } label: {
                        Label("Wrap in...", systemImage: "square.dashed")
                    }
                }
                
                // Convert to submenu for containers
                if (component.type == .vstack || component.type == .hstack || component.type == .zstack || component.type == .scrollView) && component.modifierType == nil && !component.isOverlay {
                    Menu {
                        if component.type != .vstack {
                            Button(action: {
                                convertComponent(to: .vstack)
                            }) {
                                Label("VStack", systemImage: "square.split.1x2.fill")
                            }
                        }
                        if component.type != .hstack {
                            Button(action: {
                                convertComponent(to: .hstack)
                            }) {
                                Label("HStack", systemImage: "square.split.2x1.fill")
                            }
                        }
                        if component.type != .zstack {
                            Button(action: {
                                convertComponent(to: .zstack)
                            }) {
                                Label("ZStack", systemImage: "square.2.layers.3d.top.filled")
                            }
                        }
                        if component.type != .scrollView {
                            Button(action: {
                                convertComponent(to: .scrollView)
                            }) {
                                Label("ScrollView", systemImage: "scroll")
                            }
                        }
                    } label: {
                        Label("Convert to", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                // Convert to submenu for shapes
                if (component.type == .rectangle || component.type == .circle || component.type == .roundedRectangle || component.type == .capsule || component.type == .ellipse) && component.modifierType == nil && !component.isOverlay {
                    Menu {
                        if component.type != .rectangle {
                            Button(action: {
                                convertComponent(to: .rectangle)
                            }) {
                                Label("Rectangle", systemImage: "rectangle")
                            }
                        }
                        if component.type != .circle {
                            Button(action: {
                                convertComponent(to: .circle)
                            }) {
                                Label("Circle", systemImage: "circle")
                            }
                        }
                        if component.type != .roundedRectangle {
                            Button(action: {
                                convertComponent(to: .roundedRectangle)
                            }) {
                                Label("Rounded Rectangle", systemImage: "rectangle.ratio.4.to.3.fill")
                            }
                        }
                        if component.type != .capsule {
                            Button(action: {
                                convertComponent(to: .capsule)
                            }) {
                                Label("Capsule", systemImage: "capsule")
                            }
                        }
                        if component.type != .ellipse {
                            Button(action: {
                                convertComponent(to: .ellipse)
                            }) {
                                Label("Ellipse", systemImage: "oval")
                            }
                        }
                    } label: {
                        Label("Convert to", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    onDelete()
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .onTapGesture {
                // Select component
                    onSelect(component)
            }
            .onHover { isHovered = $0 }
            .onDrag { dragAction }
            .onDrop(of: [UTType.plainText], delegate: dropDelegate)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 8) {
            expandCollapseButton
            componentIcon
            componentName
        }
    }
    
    private var indentationSpacers: some View {
        HStack(spacing: 0) {
            ForEach(0..<level, id: \.self) { _ in
                Spacer().frame(width: 24)
            }
        }
    }
    
    private var expandCollapseButton: some View {
        Group {
            if !component.children.isEmpty {
                Button(action: { toggleExpand() }) {
                    Image(systemName: expanded.contains(component.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(selectedComponent?.id == component.id ? .white : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
            } else {
                Spacer().frame(width: 24, height: 24)
            }
        }
    }
    
    private var componentIcon: some View {
        HStack(spacing: 2) {
            // If this is a modifier parent, show the modifier icon instead
            if let modifierType = component.modifierType {
                Image(systemName: modifierType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(componentIconColor)
            } else {
                Image(systemName: component.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(componentIconColor)
            }
        }
        .frame(width: 20)
    }
    
    private var componentIconColor: Color {
        if selectedComponent?.id == component.id {
            // Use white when selected regardless of theme
            return .white
        }
        // Use blue for all components
        return .blue
    }
    
    private var componentName: some View {
        Text(componentDisplayName(component))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(componentNameColor)
            .lineLimit(1)
    }
    
    private var componentNameColor: Color {
        if selectedComponent?.id == component.id {
            // Use white when selected regardless of theme
            return .white
        }
        // Use primary for all components
        return .primary
    }
    
    private var backgroundFill: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundFillColor)
    }
    
    private var backgroundFillColor: Color {
        let componentColor = Color.blue // Use primary for all components
        
        // Check if this is a modifier container
        let isModifierContainer = component.modifierType == .mask ||
                                  component.modifierType == .overlay ||
                                  component.modifierType == .background
        
        if selectedComponent?.id == component.id {
            return componentColor
        } else if isHovered {
            return componentColor.opacity(0.08)
        } else if isModifierContainer {
            return Color.gray.opacity(0.15)
        } else {
            return Color.clear
        }
    }
    
    private var dragOverlay: some View {
        // Only show drop line when actively dragging and hovering over this item
        Group {
            if draggingId != nil && dragOverTarget == component.id && dragOverPosition != .none {
                VStack(spacing: 0) {
                    if dragOverPosition == .above {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(height: 4)
                            .padding(.horizontal, 4)
                    }
                    Spacer()
                    if dragOverPosition == .below {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(height: 4)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private var dropZoneOverlay: some View {
        // Only show drop zone when actively dragging and hovering over this item
        Group {
            if draggingId != nil && dragOverTarget == component.id && dragOverPosition == .inside && canAcceptChildren(component) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .padding(2)
            }
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
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
    
    private func convertComponent(to newType: ComponentType) {
        // Create a new component with the new type but preserve children, modifiers, frame, etc.
        // We need to use a method on UIComponent to change its type
        component.convertType(to: newType)
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
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
        // Only show drop line if we're actually dragging something
        guard draggingId != nil else { return }
        dragOverTarget = target.id
        updatePosition(info: info)
        // Don't auto-expand collapsed hierarchies when dragging over them
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Only update if we're actually dragging something
        guard draggingId != nil else { return nil }
        dragOverTarget = target.id
        updatePosition(info: info)
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let sourceId = draggingId else { 
            clearDropIndicators()
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
                // Don't auto-expand - user can manually expand to see the dropped component
                // Add to the end of the children array by passing a large number that will be clamped
                onMove(sourceId, target.id, Int.max)
            } else {
                // treat as below when not a container
                insertIndex += 1
                onMove(sourceId, parentId, max(insertIndex, 0))
            }
        case .none:
            clearDropIndicators()
            return false
        }
        
        // Clear indicators immediately before performing move
        clearDropIndicators()
        
        // Clear draggingId to signal drag is complete
        DispatchQueue.main.async {
            draggingId = nil
        }
        
        return true
    }
    
    func dropExited(info: DropInfo) {
        // Only clear if this was the target we were hovering over
        if dragOverTarget == target.id {
            withAnimation(.easeOut(duration: 0.15)) {
                dragOverTarget = nil
                dragOverPosition = .none
            }
        }
    }

    func dropEnded(info: DropInfo) {
        // Clear everything immediately when drag ends
        clearDropIndicators()
        DispatchQueue.main.async {
            draggingId = nil
        }
    }
    
    private func updatePosition(info: DropInfo) {
        let y = info.location.y
        let height = 36.0 // Approximate row height
        
        withAnimation(.easeOut(duration: 0.1)) {
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
    }
    
    private func clearDropIndicators() {
        withAnimation(.easeOut(duration: 0.15)) {
            dragOverTarget = nil
            dragOverPosition = .none
        }
    }
}

// MARK: - Overlay Folder Row
private struct OverlayFolderRow: View {
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
    let onAddOverlay: () -> Void
    @Binding var expandedOverlayFolders: Set<UUID>
    let onSelect: (UIComponent) -> Void
    let onWrap: (UIComponent, ComponentType) -> Void
    
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Overlay folder header
            HStack(spacing: 8) {
                // Indentation
                HStack(spacing: 0) {
                    ForEach(0..<level, id: \.self) { _ in
                        Spacer().frame(width: 24)
                    }
                }
                
                // Expand/collapse button
                Button(action: { toggleExpand() }) {
                    Image(systemName: expandedOverlayFolders.contains(component.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(selectedComponent?.id == component.id ? .white : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                
                // Folder icon
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 14))
                    .foregroundColor(selectedComponent?.id == component.id ? .white : .orange)
                    .frame(width: 20)
                
                // "Overlay" label
                Text("Overlay")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(selectedComponent?.id == component.id ? .white : .orange)
                
                Spacer()
                
                // Add overlay button
                if isHovered {
                    Button(action: onAddOverlay) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                            .foregroundColor(selectedComponent?.id == component.id ? .white : .orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add Overlay Component")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .onHover { isHovered = $0 }
            
            // Overlay children
            if expandedOverlayFolders.contains(component.id) {
                ForEach(component.getOverlayChildren()) { child in
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
                        onDuplicate: {
                            // Copy modifiers with their properties and order
                            let duplicatedModifiers = child.modifiers.map { modifier in
                                ComponentModifier(
                                    type: modifier.type,
                                    properties: modifier.properties
                                )
                            }
                            
                            let duplicatedChild = UIComponent(
                                type: child.type,
                                properties: child.properties,
                                children: child.children,
                                frame: CGRect(
                                    x: child.frame.origin.x + 20,
                                    y: child.frame.origin.y + 20,
                                    width: child.frame.width,
                                    height: child.frame.height
                                ),
                                modifiers: duplicatedModifiers,
                                isOverlay: true
                            )
                            // Find the index of the original child in the children array
                            if let childIndex = component.children.firstIndex(where: { $0.id == child.id }) {
                                component.children.insert(duplicatedChild, at: childIndex + 1)
                            } else {
                                component.addOverlayChild(duplicatedChild)
                            }
                            selectedComponent = duplicatedChild
                        },
                        onMove: onMove,
                        getParentOf: getParentOf,
                        getIndexInParent: getIndexInParent,
                        onSelect: onSelect,
                        onWrap: onWrap
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
    }
    
    private func toggleExpand() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedOverlayFolders.contains(component.id) {
                expandedOverlayFolders.remove(component.id)
            } else {
                expandedOverlayFolders.insert(component.id)
            }
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

private struct BottomDropDelegate: DropDelegate {
    let canvasManager: CanvasManager
    @Binding var draggingId: UUID?
    @Binding var isDragOverBottom: Bool
    
    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText])
    }
    
    func dropEntered(info: DropInfo) {
        guard draggingId != nil else { return }
        withAnimation {
            isDragOverBottom = true
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard draggingId != nil else { return nil }
        return DropProposal(operation: .move)
    }
    
    func dropExited(info: DropInfo) {
        withAnimation {
            isDragOverBottom = false
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let sourceId = draggingId else { return false }
        
        print("📥 Dropping to bottom (root append)")
        // Move to the end of the root list
        canvasManager.moveComponentInHierarchy(
            componentId: sourceId,
            newParentId: nil,
            toIndex: canvasManager.components.count
        )
        
        withAnimation {
            isDragOverBottom = false
        }
        
        DispatchQueue.main.async {
            draggingId = nil
        }
        
        return true
    }
}
