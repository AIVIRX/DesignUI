//
//  ModifierPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct ModifierPanelView: View {
    @ObservedObject var component: UIComponent
    @State private var showingAddModifier = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("MODIFIERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingAddModifier = true }) {
                    HStack(spacing: 4) {
                        Text("Add Modifier")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Applied Modifiers
            if component.modifiers.isEmpty {
                Text("No modifiers applied")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(component.modifiers.enumerated()), id: \.element.id) { index, modifier in
                        ModifierItemView(
                            component: component,
                            modifier: modifier,
                            onDelete: {
                                component.removeModifier(modifier)
                            },
                            onMoveUp: index > 0 ? {
                                component.moveModifier(from: IndexSet(integer: index), to: index - 1)
                            } : nil,
                            onMoveDown: index < component.modifiers.count - 1 ? {
                                component.moveModifier(from: IndexSet(integer: index), to: index + 1)
                            } : nil
                        )
                    }
                }
            }
            
            // Suggested Modifiers
            SuggestedModifiersView(component: component)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingAddModifier) {
            AddModifierView(component: component)
        }
    }
}

struct ModifierItemView: View {
    @ObservedObject var component: UIComponent
    let modifier: ComponentModifier
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var showingEditor = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Reorder handle
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Modifier icon and name
            HStack(spacing: 8) {
                Image(systemName: modifier.type.icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 16, height: 16)
                
                Text(modifier.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Move buttons
            HStack(spacing: 4) {
                if let moveUp = onMoveUp {
                    Button(action: moveUp) {
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let moveDown = onMoveDown {
                    Button(action: moveDown) {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .onTapGesture {
            showingEditor = true
        }
        .sheet(isPresented: $showingEditor) {
            ModifierEditorView(component: component, modifier: .constant(modifier))
        }
    }
}

struct SuggestedModifiersView: View {
    @ObservedObject var component: UIComponent
    
    private var suggestedModifiers: [ModifierType] {
        let appliedTypes = Set(component.modifiers.map { $0.type })
        return ModifierType.allCases.filter { !appliedTypes.contains($0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUGGESTED MODIFIERS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(suggestedModifiers.prefix(5)) { modifierType in
                    SuggestedModifierItemView(
                        modifierType: modifierType,
                        onAdd: {
                            let modifier = ComponentModifier(type: modifierType)
                            component.addModifier(modifier)
                        }
                    )
                }
            }
        }
    }
}

struct SuggestedModifierItemView: View {
    let modifierType: ModifierType
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Modifier icon
            Image(systemName: modifierType.icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16, height: 16)
            
            // Modifier info
            VStack(alignment: .leading, spacing: 2) {
                Text(modifierType.rawValue)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(modifierType.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
}

struct AddModifierView: View {
    @ObservedObject var component: UIComponent
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredModifiers: [ModifierType] {
        let appliedTypes = Set(component.modifiers.map { $0.type })
        let available = ModifierType.allCases.filter { !appliedTypes.contains($0) }
        
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
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
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Modifiers list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredModifiers) { modifierType in
                            ModifierTypeItemView(
                                modifierType: modifierType,
                                onAdd: {
                                    let modifier = ComponentModifier(type: modifierType)
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
            
            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
}

#Preview {
    let component = UIComponent(
        type: .text,
        properties: [
            ComponentProperty(key: "text", type: .string, value: "Hello World", defaultValue: "Hello World")
        ],
        modifiers: [
            ComponentModifier(type: .frame, properties: ["width": 200, "height": 50]),
            ComponentModifier(type: .padding, properties: ["top": 16, "leading": 16, "bottom": 16, "trailing": 16])
        ]
    )
    
    return ModifierPanelView(component: component)
        .frame(width: 280, height: 400)
}
