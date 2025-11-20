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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Modifiers")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Add Modifier")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingAddModifier = true
                }
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
        .sheet(isPresented: $showingAddModifier) {
            AddModifierView(component: component)
        }
    }
}

struct ModifierReorderableList: View {
    @ObservedObject var component: UIComponent
    @State private var dragOverTarget: UUID?
    @State private var dragOverPosition: ModifierDropPosition = .none
    @State private var draggingId: UUID?
    @State private var cleanupTimer: Timer?
    
    enum ModifierDropPosition { case none, above, below }
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(component.modifiers.enumerated()), id: \.element.id) { index, modifier in
                ModifierItemView(
                    component: component,
                    modifier: modifier,
                    index: index,
                    onDelete: {
                        component.removeModifier(modifier)
                    },
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
            if newValue == nil {
                cleanupTimer?.invalidate()
                withAnimation(.easeOut(duration: 0.2)) {
                    dragOverTarget = nil
                    dragOverPosition = .none
                }
            } else {
                // Start cleanup timer when dragging starts
                cleanupTimer?.invalidate()
                cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOverTarget = nil
                        dragOverPosition = .none
                    }
                }
            }
        }
        .onDisappear {
            cleanupTimer?.invalidate()
        }
    }
}

struct ModifierItemView: View {
    @ObservedObject var component: UIComponent
    let modifier: ComponentModifier
    let index: Int
    let onDelete: () -> Void
    @Binding var dragOverTarget: UUID?
    @Binding var dragOverPosition: ModifierReorderableList.ModifierDropPosition
    @Binding var draggingId: UUID?
    let onMove: (Int, Int) -> Void
    @State private var showingEditor = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .onDrag {
                        draggingId = modifier.id
                        return NSItemProvider(object: modifier.id.uuidString as NSString)
                    }
                
                // Modifier icon and name
                HStack(spacing: 8) {
                    Image(systemName: modifier.type.icon)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(width: 16, height: 16)
                    
                    Text(modifierDisplayName(modifier, index: index))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Delete button
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                VStack(spacing: 0) {
                    if dragOverTarget == modifier.id && dragOverPosition == .above {
                        Divider().overlay(Color.accentColor).frame(height: 2)
                    }
                    Spacer(minLength: 0)
                    if dragOverTarget == modifier.id && dragOverPosition == .below {
                        Divider().overlay(Color.accentColor).frame(height: 2)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
            .onTapGesture {
                showingEditor = true
            }
            .onHover { isHovered = $0 }
            .onDrop(of: [UTType.plainText], delegate: ModifierDropDelegate(
                target: modifier,
                targetIndex: index,
                component: component,
                draggingId: $draggingId,
                dragOverTarget: $dragOverTarget,
                dragOverPosition: $dragOverPosition,
                onMove: onMove
            ))
            .popover(isPresented: $showingEditor) {
                ModifierEditorView(component: component, modifier: Binding(
                    get: { modifier },
                    set: { newModifier in
                        component.updateModifier(newModifier)
                    }
                ))
            }
        }
    }
    
    /// Generates a descriptive display name for a modifier, including distinguishing information
    /// when there are multiple modifiers of the same type
    private func modifierDisplayName(_ modifier: ComponentModifier, index: Int) -> String {
        let baseName = modifier.type.rawValue
        
        // Count how many modifiers of this type exist before this one
        let sameTypeCount = component.modifiers.prefix(index).filter { $0.type == modifier.type }.count
        let totalSameType = component.modifiers.filter { $0.type == modifier.type }.count
        
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
            let widthType = modifier.properties["widthType"] as? String ?? "Default"
            let heightType = modifier.properties["heightType"] as? String ?? "Default"
            var parts: [String] = []
            if widthType == "Custom" {
                parts.append("W")
            }
            if heightType == "Custom" {
                parts.append("H")
            }
            if parts.isEmpty {
                return "\(baseName) (\(sameTypeCount + 1))"
            }
            return "\(baseName) (\(parts.joined(separator: "×")))"
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
        case .background:
            if modifier.properties["color"] is Color {
                // Try to get a color name (simplified)
                return "\(baseName) (Color)"
            }
            return baseName
        case .foregroundColor:
            if modifier.properties["color"] is Color {
                return "\(baseName) (Color)"
            }
            return baseName
        default:
            // For other types, just add a number if there are multiple
            if totalSameType <= 1 {
                return baseName
            }
            if sameTypeCount > 0 {
                return "\(baseName) (\(sameTypeCount + 1))"
            }
            return baseName
        }
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
        dragOverTarget = target.id
        updatePosition(info: info)
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
        
        // Find source index
        guard let sourceIndex = findModifierIndex(id: sourceId) else {
            cleanup()
            return false
        }
        
        var targetIndex = self.targetIndex
        switch dragOverPosition {
        case .above:
            break
        case .below:
            targetIndex += 1
        case .none:
            cleanup()
            return false
        }
        
        onMove(sourceIndex, targetIndex)
        cleanup()
        return true
    }
    
    func dropExited(info: DropInfo) {
        if dragOverTarget == target.id {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    dragOverTarget = nil
                    dragOverPosition = .none
                }
            }
        }
    }
    
    func dropEnded(info: DropInfo) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                dragOverTarget = nil
                dragOverPosition = .none
                draggingId = nil
            }
        }
    }
    
    private func updatePosition(info: DropInfo) {
        let y = info.location.y
        let height = 32.0 // Approximate row height
        
        if y < height * 0.5 {
            dragOverPosition = .above
        } else {
            dragOverPosition = .below
        }
    }
    
    private func cleanup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                draggingId = nil
                dragOverTarget = nil
                dragOverPosition = .none
            }
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
    
    private var filteredModifiers: [ModifierType] {
        // Allow all modifier types - users can add multiple modifiers of the same type
        if searchText.isEmpty {
            return ModifierType.allCases
        } else {
            return ModifierType.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
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
                    LazyVStack(spacing: 8) {
                        ForEach(filteredModifiers) { modifierType in
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
                    .padding(16)
                }
            }
            .navigationTitle("Add Modifier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

struct ModifierTypeItemView: View {
    let modifierType: ModifierType
    let onAdd: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            // Modifier icon
            Image(systemName: modifierType.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            // Modifier info
            VStack(alignment: .leading, spacing: 4) {
                Text(modifierType.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(modifierType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onAdd()
        }
    }
}
