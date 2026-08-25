//
//  LayersPanelView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct LayersPanelView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    var onLayerTapped: ((UIComponent) -> Void)? = nil // Callback for iOS navigation
    @Binding var showComponentLibrary: Bool
    @Binding var componentLibraryMode: ComponentLibraryMode
    var onReplaceRequested: ((UIComponent) -> Void)? = nil
    @State private var expanded: Set<UUID> = []
    @State private var expandedOverlayFolders: Set<UUID> = [] // Track overlay folder expansion separately
    @State private var dragOverTarget: UUID?
    @State private var dragOverPosition: DropPosition = .none
    @State private var draggingId: UUID?
    @State private var isDragOverBottom = false
    @State private var isUserInitiatedSelection = false
    @State private var selectionScrollTask: Task<Void, Never>?
    @Environment(\.horizontalSizeClass) var hSizeClass
    
    private var isRegularSizeClass: Bool {
        hSizeClass == .regular
    }

    var body: some View {
        if isRegularSizeClass {
            regularSizeView
        } else {
            phoneSizeView
        }
    }
    
    private var regularSizeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            layersOutlineView
        }
    }

    @ViewBuilder
    private var layersOutlineView: some View {
        let base = layersBaseView

#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            base
                .navigationDestination(isPresented: $showComponentLibrary) {
                    phoneComponentLibraryView
                }
                .onReceive(dismissChildNavigationPublisher) { _ in showComponentLibrary = false }
        } else {
            base
                .popover(isPresented: $showComponentLibrary) {
                    componentLibraryPopoverView(width: 320, height: 480)
                }
                .onReceive(dismissChildNavigationPublisher) { _ in showComponentLibrary = false }
        }
#else
        base
            .popover(isPresented: $showComponentLibrary) {
                componentLibraryPopoverView(width: 500, height: 400)
            }
#endif
    }
    
    private var layersBaseView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                layersListView
            }
            .onChange(of: selectedComponent?.id) { _, newId in
                handleSelectionChange(newId, scrollProxy: scrollProxy)
            }
        }
        .onChange(of: draggingId) { _, newValue in
            if newValue == nil {
                withAnimation(.easeOut(duration: 0.15)) {
                    dragOverTarget = nil
                    dragOverPosition = .none
                }
            }
        }
        .onAppear {
            expandAllParents()
        }
        .onChange(of: canvasManager.components) { _, _ in
            handleComponentsChanged()
        }
    }
    
    private var phoneComponentLibraryView: some View {
        ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager, mode: componentLibraryMode)
            .navigationTitle("Components")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func componentLibraryPopoverView(width: CGFloat, height: CGFloat) -> some View {
        ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager, mode: componentLibraryMode)
            .frame(width: width, height: height)
    }
    
    private var dismissChildNavigationPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .dismissChildNavigation)
    }

    private var layersListView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                statusBarRowView
                ForEach(canvasManager.components) { component in
                    componentGroup(for: component)
                }
                if canvasManager.components.isEmpty {
                    EmptyLayersState()
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            dropZoneView
        }
    }

    @ViewBuilder
    private var statusBarRowView: some View {
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
    }

    @ViewBuilder
    private func componentGroup(for component: UIComponent) -> some View {
        if !component.getOverlayChildren().isEmpty {
            overlayFolderRow(for: component)
        }
        outlineRow(for: component)
    }
    
    private func overlayFolderRow(for component: UIComponent) -> some View {
        OverlayFolderRow(
            component: component,
            level: 0,
            expanded: $expanded,
            selectedComponent: $selectedComponent,
            dragOverTarget: $dragOverTarget,
            dragOverPosition: $dragOverPosition,
            draggingId: $draggingId,
            onMove: moveComponentInHierarchy,
            getParentOf: parentIdForComponent,
            getIndexInParent: indexInParentForComponent,
            onAddOverlay: {
                canvasManager.createOverlayFolder(for: component)
            },
            expandedOverlayFolders: $expandedOverlayFolders,
            onSelect: handleLayerSelection,
            onWrap: wrapComponent,
            onReplace: { component in
                onReplaceRequested?(component)
            },
            canvasManager: canvasManager
        )
    }
    
    private func outlineRow(for component: UIComponent) -> some View {
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
            onMove: moveComponentInHierarchy,
            getParentOf: parentIdForComponent,
            getIndexInParent: indexInParentForComponent,
            onSelect: handleLayerSelection,
            onWrap: wrapComponent,
            onReplace: { component in
                onReplaceRequested?(component)
            },
            canvasManager: canvasManager
        )
        .id(component.id)
    }

    @ViewBuilder
    private var dropZoneView: some View {
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

    private func handleSelectionChange(_ newId: UUID?, scrollProxy: ScrollViewProxy) {
        selectionScrollTask?.cancel()
        guard let id = newId else { return }

        let shouldScroll = !isUserInitiatedSelection
        isUserInitiatedSelection = false
        guard shouldScroll else { return }

        // Materialize an expanded parent chain before scrolling. Starting a spring
        // scroll during that same layout update made canvas selections visibly hitch.
        expandParentsOf(id)
        selectionScrollTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, selectedComponent?.id == id else { return }

            var transaction = Transaction()
            transaction.animation = .easeOut(duration: 0.18)
            withTransaction(transaction) {
                scrollProxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private var phoneSizeView: some View {
        layersOutlineView
            .navigationTitle("Layers")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .background(Color.clear)
    }
    
    private func handleComponentsChanged() {
        if let selected = selectedComponent {
            expandParentsOf(selected.id)
        }
        
        for component in canvasManager.components where !component.getOverlayChildren().isEmpty {
            expandedOverlayFolders.insert(component.id)
        }
    }
    
    private func handleLayerSelection(_ component: UIComponent) {
        isUserInitiatedSelection = true
        selectedComponent = component
        onLayerTapped?(component)
    }
    
    private func moveComponentInHierarchy(_ sourceId: UUID, _ parentId: UUID?, _ index: Int) {
        canvasManager.moveComponentInHierarchy(componentId: sourceId, newParentId: parentId, toIndex: index)
    }
    
    private func parentIdForComponent(_ id: UUID) -> UUID? {
        findParentId(of: id, in: canvasManager.components)
    }
    
    private func indexInParentForComponent(_ id: UUID) -> Int {
        indexInParent(of: id, in: canvasManager.components)
    }
    
    private func wrapComponent(_ component: UIComponent, _ type: ComponentType) {
        canvasManager.wrapComponent(component, in: type)
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
    case .scrollView, .stack, .vstack, .hstack, .zstack, .button:
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
            // Spacer().frame(width: 24) // Removed to flush left
            
            // Status bar icon
            Image(systemName: "iphone")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 20)
            
            // Label
            Text("Canvas Settings")
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
        .onTapGesture {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            #endif
            onSelect()
        }
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
    let onReplace: (UIComponent) -> Void
    let canvasManager: CanvasManager
    @State private var isHovered = false
    
    init(component: UIComponent, level: Int, expanded: Binding<Set<UUID>>, selectedComponent: Binding<UIComponent?>, dragOverTarget: Binding<UUID?>, dragOverPosition: Binding<DropPosition>, draggingId: Binding<UUID?>, onDelete: @escaping () -> Void, onDuplicate: @escaping () -> Void, onMove: @escaping (_ sourceId: UUID, _ newParentId: UUID?, _ index: Int) -> Void, getParentOf: @escaping (UUID) -> UUID?, getIndexInParent: @escaping (UUID) -> Int, onSelect: @escaping (UIComponent) -> Void, onWrap: @escaping (UIComponent, ComponentType) -> Void, onReplace: @escaping (UIComponent) -> Void, canvasManager: CanvasManager) {
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
        self.onReplace = onReplace
        self.canvasManager = canvasManager
    }
    
    var body: some View {
        VStack(spacing: 0) {
            row
            if expanded.contains(component.id) {
                // Render all children (regular + modifier parents)
                ForEach(component.children.filter { !$0.isOverlay }) { child in
                    childOutlineRow(child)
                }
            }
        }
    }
    
    private func childOutlineRow(_ child: UIComponent) -> some View {
        OutlineRow(
            component: child,
            level: level + 1,
            expanded: $expanded,
            selectedComponent: $selectedComponent,
            dragOverTarget: $dragOverTarget,
            dragOverPosition: $dragOverPosition,
            draggingId: $draggingId,
            onDelete: {
                canvasManager.removeComponent(child)
                if selectedComponent?.id == child.id {
                    selectedComponent = nil
                }
            },
            onDuplicate: {
                canvasManager.duplicateComponent(child)
            },
            onMove: onMove,
            getParentOf: getParentOf,
            getIndexInParent: getIndexInParent,
            onSelect: onSelect,
            onWrap: onWrap,
            onReplace: onReplace,
            canvasManager: canvasManager
        )
        .transition(.opacity)
    }
    
    private var row: some View {
        rowSurface
            .onTapGesture {
#if os(iOS)
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
#endif
                onSelect(component)
            }
            .onHover { isHovered = $0 }
            .onDrag { dragAction }
            .onDrop(of: [UTType.plainText], delegate: dropDelegate)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
    }
    
    private var rowSurface: some View {
        HStack(spacing: 0) {
            indentationSpacers
            rowContent
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundFillColor, in: RoundedRectangle(cornerRadius: 8))
        }
        .overlay(dragOverlay)
        .overlay(dropZoneOverlay)
        .contentShape(Rectangle())
        .contextMenu {
            rowContextMenu
        }
    }
    
    @ViewBuilder
    private var rowContextMenu: some View {
        Button(action: {
            onDuplicate()
        }) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Button(action: {
            onReplace(component)
        }) {
            Label("Replace…", systemImage: "arrow.triangle.2.circlepath")
        }

        if canAddLayerModifiers {
            Divider()

            Button {
                addLayerModifier(.background)
            } label: {
                Label("Add Background", systemImage: ModifierType.background.icon)
            }

            Button {
                addLayerModifier(.overlay)
            } label: {
                Label("Add Overlay", systemImage: ModifierType.overlay.icon)
            }

            Button {
                addLayerModifier(.mask)
            } label: {
                Label("Add Mask", systemImage: ModifierType.mask.icon)
            }
        }
        
        if canWrapInContainer {
            wrapInMenu
        }
        
        if canConvertContainer {
            convertContainerMenu
        }
        
        if canConvertShape {
            convertShapeMenu
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            onDelete()
        }) {
            Label("Delete", systemImage: "trash")
        }
    }

    private var canAddLayerModifiers: Bool {
        component.modifierType == nil
    }

    private func addLayerModifier(_ type: ModifierType) {
        let modifier = ComponentModifier.createWithDefaults(type: type)
        canvasManager.addModifier(to: component, modifier: modifier)
    }
    
    private var canWrapInContainer: Bool {
        component.modifierType == nil && !component.isOverlay
    }
    
    private var canConvertContainer: Bool {
        isContainerType(component.type) && canWrapInContainer
    }

    private func isContainerType(_ type: ComponentType) -> Bool {
        switch type {
        case .stack, .vstack, .hstack, .zstack, .scrollView:
            return true
        default:
            return false
        }
    }
    
    private var canConvertShape: Bool {
        isShapeType(component.type) && canWrapInContainer
    }
    
    private func isShapeType(_ type: ComponentType) -> Bool {
        switch type {
        case .rectangle, .circle, .roundedRectangle, .capsule, .ellipse:
            return true
        default:
            return false
        }
    }
    
    private var wrapInMenu: some View {
        Menu {
            Button("Stack") { onWrap(component, .stack) }
            Button("ScrollView") { onWrap(component, .scrollView) }
        } label: {
            Label("Wrap in...", systemImage: "square.dashed")
        }
    }
    
    private var convertContainerMenu: some View {
        Menu {
            if component.type != .stack {
                Button(action: { convertComponent(to: .stack) }) {
                    Label("Stack", systemImage: "square.stack.3d.up")
                }
            }
            if component.type != .scrollView {
                Button(action: { convertComponent(to: .scrollView) }) {
                    Label("ScrollView", systemImage: "scroll")
                }
            }
        } label: {
            Label("Convert to", systemImage: "arrow.triangle.2.circlepath")
        }
    }
    
    private var convertShapeMenu: some View {
        Menu {
            if component.type != .rectangle {
                Button(action: { convertComponent(to: .rectangle) }) {
                    Label("Rectangle", systemImage: "rectangle")
                }
            }
            if component.type != .circle {
                Button(action: { convertComponent(to: .circle) }) {
                    Label("Circle", systemImage: "circle")
                }
            }
            if component.type != .roundedRectangle {
                Button(action: { convertComponent(to: .roundedRectangle) }) {
                    Label("Rounded Rectangle", systemImage: "rectangle.ratio.4.to.3.fill")
                }
            }
            if component.type != .capsule {
                Button(action: { convertComponent(to: .capsule) }) {
                    Label("Capsule", systemImage: "capsule")
                }
            }
            if component.type != .ellipse {
                Button(action: { convertComponent(to: .ellipse) }) {
                    Label("Ellipse", systemImage: "oval")
                }
            }
        } label: {
            Label("Convert to", systemImage: "arrow.triangle.2.circlepath")
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 8) {
            componentIcon
            componentName
            Spacer()
            expandCollapseButton
        }
    }
    
    private var indentationSpacers: some View {
        Color.clear
            .frame(width: CGFloat(level) * 16)
    }
    
    private var expandCollapseButton: some View {
        Group {
            if !component.children.isEmpty {
                Button(action: { toggleExpand() }) {
                    Image(systemName: expanded.contains(component.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14).bold())
                        .foregroundColor(selectedComponent?.id == component.id ? .white : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
            } else {
                Spacer()
            }
        }
    }
    
    private var componentIcon: some View {
        Image(systemName: component.modifierType?.icon ?? component.type.icon)
            .font(.system(size: 14))
            .foregroundColor(componentIconColor)
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
    
    private var backgroundFillColor: Color {
        let componentColor = Color.blue
        if selectedComponent?.id == component.id {
            return componentColor
        }
        if isHovered {
            return componentColor.opacity(0.08)
        }
        return Color.clear
    }
    
    private var dragOverlay: some View {
        Group {
            if shouldShowDragOverlay {
                dragOverlayContent
            }
        }
    }
    
    private var shouldShowDragOverlay: Bool {
        draggingId != nil && dragOverTarget == component.id && dragOverPosition != .none
    }
    
    private var dragOverlayContent: some View {
        VStack(spacing: 0) {
            if dragOverPosition == .above {
                overlayCapsule
            }
            Spacer()
            if dragOverPosition == .below {
                overlayCapsule
            }
        }
    }
    
    private var overlayCapsule: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(height: 4)
            .padding(.horizontal, 4)
    }
    
    private var dropZoneOverlay: some View {
        Group {
            if shouldShowDropZoneOverlay {
                dropZoneStroke
            }
        }
    }
    
    private var shouldShowDropZoneOverlay: Bool {
        draggingId != nil &&
        dragOverTarget == component.id &&
        dragOverPosition == .inside &&
        canAcceptChildren(component)
    }
    
    private var dropZoneStroke: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            .padding(2)
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
            dragOverTarget = nil
            dragOverPosition = .none
        }
    }

    // (Removed unused dropEnded)
    
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
    
    private func clearDropIndicators() {
        dragOverTarget = nil
        dragOverPosition = .none
    }
}

private struct OverlayFolderRow: View {
    @ObservedObject var component: UIComponent
    let level: Int
    @Binding var expanded: Set<UUID>
    @Binding var selectedComponent: UIComponent?
    @Binding var dragOverTarget: UUID?
    @Binding var dragOverPosition: DropPosition
    @Binding var draggingId: UUID?
    let onMove: (_ sourceId: UUID, _ newParentId: UUID?, _ index: Int) -> Void
    let getParentOf: (UUID) -> UUID?
    let getIndexInParent: (UUID) -> Int
    let onAddOverlay: () -> Void
    @Binding var expandedOverlayFolders: Set<UUID>
    let onSelect: (UIComponent) -> Void
    let onWrap: (UIComponent, ComponentType) -> Void
    let onReplace: (UIComponent) -> Void
    let canvasManager: CanvasManager
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            folderHeader
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .onHover { isHovered = $0 }
            
            // Overlay children
            if isExpanded {
                ForEach(overlayChildren) { child in
                    overlayChildRow(child)
                }
            }
        }
    }
    
    private var isSelected: Bool {
        selectedComponent?.id == component.id
    }
    
    private var isExpanded: Bool {
        expandedOverlayFolders.contains(component.id)
    }
    
    private var overlayChildren: [UIComponent] {
        component.getOverlayChildren()
    }
    
    private var folderAccentColor: Color {
        isSelected ? .white : .orange
    }
    
    private var folderChevronColor: Color {
        isSelected ? .white : .secondary
    }
    
    private var folderHeader: some View {
        HStack(spacing: 0) {
            indentation
            folderHeaderContent
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
        }
    }
    
    private var indentation: some View {
        HStack(spacing: 0) {
            ForEach(0..<level, id: \.self) { _ in
                Spacer().frame(width: 16)
            }
        }
    }
    
    private var folderHeaderContent: some View {
        HStack(spacing: 8) {
            folderIcon
            folderTitle
            Spacer()
            addOverlayButton
            expandCollapseButton
        }
    }
    
    private var folderIcon: some View {
        Image(systemName: "square.stack.3d.up")
            .font(.system(size: 14))
            .foregroundColor(folderAccentColor)
            .frame(width: 20)
    }
    
    private var folderTitle: some View {
        Text("Overlay")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(folderAccentColor)
    }
    
    @ViewBuilder
    private var addOverlayButton: some View {
        if isHovered {
            Button(action: onAddOverlay) {
                Image(systemName: "plus")
                    .font(.system(size: 10))
                    .foregroundColor(folderAccentColor)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Add Overlay Component")
        }
    }
    
    private var expandCollapseButton: some View {
        Button(action: { toggleExpand() }) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(folderChevronColor)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 40, height: 24)
        .contentShape(Rectangle())
    }
    
    private func overlayChildRow(_ child: UIComponent) -> some View {
        OutlineRow(
            component: child,
            level: level + 1,
            expanded: $expanded,
            selectedComponent: $selectedComponent,
            dragOverTarget: $dragOverTarget,
            dragOverPosition: $dragOverPosition,
            draggingId: $draggingId,
            onDelete: {
                deleteOverlayChild(child)
            },
            onDuplicate: {
                duplicateOverlayChild(child)
            },
            onMove: onMove,
            getParentOf: getParentOf,
            getIndexInParent: getIndexInParent,
            onSelect: onSelect,
            onWrap: onWrap,
            onReplace: onReplace,
            canvasManager: canvasManager
        )
        .transition(.opacity)
    }
    
    private func deleteOverlayChild(_ child: UIComponent) {
        canvasManager.removeComponent(child)
        if selectedComponent?.id == child.id {
            selectedComponent = nil
        }
    }
    
    private func duplicateOverlayChild(_ child: UIComponent) {
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

        if let childIndex = component.children.firstIndex(where: { $0.id == child.id }) {
            component.children.insert(duplicatedChild, at: childIndex + 1)
        } else {
            component.addOverlayChild(duplicatedChild)
        }
        selectedComponent = duplicatedChild
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
        
        debugLog("📥 Dropping to bottom (root append)")
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
