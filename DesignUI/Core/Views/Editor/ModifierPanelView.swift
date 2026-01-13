//
//  ModifierPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ModifierPanelView: View {
    @ObservedObject var component: UIComponent
    @State private var showingAddModifier = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Text("Modifiers")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showingAddModifier = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                        
                        Text("Add")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.12))
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Applied Modifiers
            if component.modifiers.isEmpty {
                Text("No modifiers applied")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100, alignment: .center)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
            } else {
                ModifierReorderableList(component: component)
            }
        }
#if os(iOS)
        .navigationDestination(isPresented: $showingAddModifier) {
            AddModifierView(component: component)
                .navigationTitle("Add Modifier")
                .navigationBarTitleDisplayMode(.inline)
        }
#else
        .sheet(isPresented: $showingAddModifier) {
            AddModifierView(component: component)
        }
#endif
    }
}

struct ModifierReorderableList: View {
    @ObservedObject var component: UIComponent
    @State private var dragOverTarget: UUID? 
    @State private var dragOverPosition: ModifierDropPosition = .none
    @State private var draggingId: UUID?
    
    enum ModifierDropPosition { case none, above, below }
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(component.modifiers.enumerated()), id: \.element.id) { index, modifier in
                ModifierItemView(
                    component: component,
                    modifier: modifier,
                    index: index,
                    dragOverTarget: $dragOverTarget,
                    dragOverPosition: $dragOverPosition,
                    draggingId: $draggingId,
                    onMove: { sourceIndex, targetIndex in
                        component.moveModifier(from: IndexSet(integer: sourceIndex), to: targetIndex)
                    }
                )
            }
        }
        .onChange(of: draggingId) { _, newValue in
            // When drag ends (draggingId becomes nil), immediately clear drop indicators
            if newValue == nil {
                withAnimation(.easeOut(duration: 0.15)) {
                    dragOverTarget = nil
                    dragOverPosition = .none
                }
            }
        }
    }
}

struct ModifierItemView: View {
    @ObservedObject var component: UIComponent
    let modifier: ComponentModifier
    let index: Int
    @Binding var dragOverTarget: UUID?
    @Binding var dragOverPosition: ModifierReorderableList.ModifierDropPosition
    @Binding var draggingId: UUID?
    let onMove: (Int, Int) -> Void
    @State private var showingEditor = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Modifier icon and name
                HStack(spacing: 8) {
                    Image(systemName: modifier.type.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 24)
                    
                    Text(modifierDisplayName(modifier, index: index))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                // Only show drop line when actively dragging and hovering over this item
                Group {
                    if draggingId != nil && dragOverTarget == modifier.id && dragOverPosition != .none {
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
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
            .onDrag {
                draggingId = modifier.id
                return NSItemProvider(object: modifier.id.uuidString as NSString)
            }
            .onTapGesture {
                // Only show editor for modifiers that don't rely on parent components
                // background, overlay, and mask all use component children instead of property editors
                if modifier.type != .overlay && modifier.type != .mask && modifier.type != .background {
                    showingEditor = true
                }
            }
            .contextMenu {
                Button(action: {
                    duplicateModifier()
                }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Button(role: .destructive, action: {
                    component.removeModifier(modifier)
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .onDrop(of: [UTType.plainText], delegate: ModifierDropDelegate(
                target: modifier,
                targetIndex: index,
                component: component,
                draggingId: $draggingId,
                dragOverTarget: $dragOverTarget,
                dragOverPosition: $dragOverPosition,
                onMove: onMove
            ))
#if os(iOS)
            .navigationDestination(isPresented: $showingEditor) {
                ModifierEditorView(component: component, modifier: Binding(
                    get: { modifier },
                    set: { newModifier in
                        DispatchQueue.main.async {
                            component.updateModifier(newModifier)
                        }
                    }
                ))
                .navigationTitle(modifier.type.rawValue)
                .navigationBarTitleDisplayMode(.inline)
            }
#else
            .popover(isPresented: $showingEditor) {
                ModifierEditorView(component: component, modifier: Binding(
                    get: { modifier },
                    set: { newModifier in
                        DispatchQueue.main.async {
                            component.updateModifier(newModifier)
                        }
                    }
                ))
            }
#endif
        }
    }
    
    /// Generates a descriptive display name for a modifier, including distinguishing information
    /// when there are multiple modifiers of the same type
    private func modifierDisplayName(_ modifier: ComponentModifier, index: Int) -> String {
        let baseName = modifier.type.rawValue
        
        // Count how many modifiers of this type exist before this one
        let sameTypeCount = component.modifiers.prefix(index).filter { $0.type == modifier.type }.count
        
        // Add distinguishing information based on modifier type
        switch modifier.type {
        case .textAlignment:
            let alignment = modifier.properties["alignment"] as? String ?? "leading"
            return "\(baseName) (\(alignment.capitalized))"
        case .padding:
            let location = modifier.properties["location"] as? String ?? "all"
            if location != "all" {
                return "\(baseName) (\(location.capitalized))"
            } else if sameTypeCount > 0 {
                return "\(baseName) (\(sameTypeCount + 1))"
            } else {
                return baseName
            }
        case .frame:
            let widthType = (modifier.properties["widthType"] as? String) ?? "Default"
            let heightType = (modifier.properties["heightType"] as? String) ?? "Default"
            
            // Only show preview if both dimensions are set (not Default)
            if widthType == "Default" || heightType == "Default" {
                return baseName
            }
            
            let width = modifier.getCGFloat(key: "width", defaultValue: 100)
            let height = modifier.getCGFloat(key: "height", defaultValue: 100)
            
            let wDisplay = widthType == "Custom" ? "\(Int(width))" : widthType
            let hDisplay = heightType == "Custom" ? "\(Int(height))" : heightType
            
            return "\(baseName) (\(wDisplay) × \(hDisplay))"
        case .offset:
            let x = modifier.getCGFloat(key: "x", defaultValue: 0)
            let y = modifier.getCGFloat(key: "y", defaultValue: 0)
            return "\(baseName) (\(Int(x)), \(Int(y)))"
        case .scale:
            let x = modifier.getDouble(key: "x", defaultValue: 1.0)
            let y = modifier.getDouble(key: "y", defaultValue: 1.0)
            return "\(baseName) (\(String(format: "%.1f", x))×\(String(format: "%.1f", y)))"
        case .rotation:
            let angle = modifier.getDouble(key: "angle", defaultValue: 0)
            return "\(baseName) (\(Int(angle))°)"
        case .shadow:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return "\(baseName) (\(Int(radius))px)"
        case .blur:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return "\(baseName) (\(Int(radius))px)"
        case .cornerRadius:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return "\(baseName) (\(Int(radius))px)"
        case .opacity:
            let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            return "\(baseName) (\(Int(opacity * 100))%)"
        case .fill, .foregroundColor, .backgroundColor:
            return baseName
        case .border:
            let width = modifier.getCGFloat(key: "width", defaultValue: 1)
            return "\(baseName) (\(Int(width))px)"
        case .clipShape:
            let shape = modifier.properties["shape"] as? String ?? "Rectangle"
            return "\(baseName) (\(shape))"
        case .aspectRatio:
            if let ratio = modifier.properties["ratio"] as? Double {
                if abs(ratio - 1.0) < 0.01 { return "\(baseName) (Square)" }
                if abs(ratio - 1.777) < 0.01 { return "\(baseName) (16:9)" }
                return "\(baseName) (\(String(format: "%.2f", ratio)))"
            }
            let contentMode = modifier.properties["aspectRatio"] as? String ?? "fit"
            return "\(baseName) (\(contentMode.capitalized))"
        case .zIndex:
            let index = modifier.getDouble(key: "index", defaultValue: 0)
            return "\(baseName) (\(Int(index)))"
        case .mask, .overlay, .background:
            return baseName
        case .font:
            let size = modifier.properties["fontSize"] as? String ?? "body"
            let weight = modifier.properties["fontWeight"] as? String ?? "regular"
            if weight == "regular" {
                return "\(baseName) (\(size.capitalized))"
            }
            return "\(baseName) (\(size.capitalized), \(weight.capitalized))"
        }
    }
    
    /// Duplicates the current modifier and inserts it right after the current one
    private func duplicateModifier() {
        // Create a new modifier with the same type and properties
        let duplicatedModifier = ComponentModifier(
            type: modifier.type,
            properties: modifier.properties
        )
        
        // Insert the duplicate right after the current modifier
        let insertIndex = index + 1
        component.modifiers.insert(duplicatedModifier, at: insertIndex)
        component.objectWillChange.send()
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
}

struct ModifierDropDelegate: DropDelegate {
    let target: ComponentModifier
    let targetIndex: Int
    let component: UIComponent
    @Binding var draggingId: UUID?
    @Binding var dragOverTarget: UUID?
    @Binding var dragOverPosition: ModifierReorderableList.ModifierDropPosition
    let onMove: (Int, Int) -> Void
    
    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText])
    }
    
    func dropEntered(info: DropInfo) {
        // Only show drop line if we're actually dragging something
        guard draggingId != nil else { return }
        dragOverTarget = target.id
        updatePosition(info: info)
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
        
        // Find source index
        guard let sourceIndex = findModifierIndex(id: sourceId) else {
            clearDropIndicators()
            return false
        }
        
        var targetIndex = self.targetIndex
        switch dragOverPosition {
        case .above:
            break
        case .below:
            targetIndex += 1
        case .none:
            clearDropIndicators()
            return false
        }
        
        // Clear indicators immediately before performing move
        clearDropIndicators()
        onMove(sourceIndex, targetIndex)
        
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
        let height = 32.0 // Approximate row height
        
        withAnimation(.easeOut(duration: 0.1)) {
            if y < height * 0.5 {
                dragOverPosition = .above
            } else {
                dragOverPosition = .below
            }
        }
    }
    
    private func clearDropIndicators() {
        withAnimation(.easeOut(duration: 0.15)) {
            dragOverTarget = nil
            dragOverPosition = .none
        }
    }
    
    private func findModifierIndex(id: UUID) -> Int? {
        return component.modifiers.firstIndex { $0.id == id }
    }
}

struct AddModifierView: View {
    @ObservedObject var component: UIComponent
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    // Define categories
    private struct ModifierCategory: Identifiable {
        let id = UUID()
        let name: String
        let modifiers: [ModifierType]
    }
    
    private var categories: [ModifierCategory] {
        [
            ModifierCategory(name: "Layout", modifiers: [
                .frame, .padding, .aspectRatio
            ]),
            ModifierCategory(name: "Style", modifiers: [
                .fill, .foregroundColor, .backgroundColor, .opacity, .shadow, .border, .blur
            ]),
            ModifierCategory(name: "Text", modifiers: [
                .font, .textAlignment
            ]),
            ModifierCategory(name: "Transform", modifiers: [
                .scale, .rotation, .offset
            ]),
            ModifierCategory(name: "Layers & Effects", modifiers: [
                .background, .overlay, .zIndex, .mask, .clipShape, .cornerRadius
            ])
        ]
    }
    
    private var filteredCategories: [ModifierCategory] {
        if searchText.isEmpty {
            return categories
        } else {
            let filtered = ModifierType.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
            return [ModifierCategory(name: "Search Results", modifiers: filtered)]
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search modifiers...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.1))
                
                Divider()
                
                // Modifiers list
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(filteredCategories) { category in
                            if !category.modifiers.isEmpty {
                                Section(header:
                                            HStack {
                                    Text(category.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                                    .background(.regularMaterial)
                                ) {
                                    ForEach(category.modifiers) { modifierType in
                                        ModifierTypeItemView(
                                            modifierType: modifierType,
                                            onAdd: {
                                                let modifier = ComponentModifier.createWithDefaults(type: modifierType)
                                                component.addModifier(modifier)
                                                dismiss()
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
#if os(macOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
#endif
#if os(iOS)
        .background(Color(uiColor: .systemBackground))
#endif
#if os(macOS)
        .frame(width: 400, height: 600)
#endif
    }
}

struct ModifierTypeItemView: View {
    let modifierType: ModifierType
    let onAdd: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                // Modifier icon
                Image(systemName: modifierType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                // Modifier info
                VStack(alignment: .leading, spacing: 2) {
                    Text(modifierType.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(modifierType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
