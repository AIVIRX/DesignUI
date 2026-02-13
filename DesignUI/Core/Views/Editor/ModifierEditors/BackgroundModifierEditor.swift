//
//  BackgroundModifierEditor.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Component Library for Modifier
struct ComponentLibraryForModifierView: View {
    @ObservedObject var component: UIComponent
    let onAdd: (UIComponent) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredComponents: [ComponentType] {
        let components = ComponentType.allCases
            .filter { $0 != .statusBar }
        
        if searchText.isEmpty {
            return components
        } else {
            return components.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search components...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.1))
                
                Divider()
                
                // Components grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)
                    ], spacing: 8) {
                        ForEach(filteredComponents) { componentType in
                            Button(action: {
                                let newComponent = UIComponent(
                                    type: componentType,
                                    properties: UIComponent.defaultProperties(for: componentType),
                                    frame: CGRect(origin: .zero, size: .zero)
                                )
                                onAdd(newComponent)
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: componentType.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                    
                                    Text(componentType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(12)
                }
            }
            .navigationTitle("Add Component")
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

// MARK: - Background Element Modifier Editor (for component elements)
struct BackgroundElementModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var showComponentLibrary = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add components to use as background elements.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let modifierChildren = component.getChildrenForModifier(modifier.id)
            
            if modifierChildren.isEmpty {
                Button(action: { showComponentLibrary = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Component")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                // Show existing children
                ForEach(modifierChildren) { child in
                    HStack {
                        Image(systemName: child.type.icon)
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(child.type.rawValue)
                            .font(.caption)
                        Spacer()
                        Button(action: {
                            component.removeChild(child)
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                
                Button(action: { showComponentLibrary = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Another")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showComponentLibrary) {
            ComponentLibraryForModifierView(
                component: component,
                onAdd: { newComponent in
                    component.addModifierChild(newComponent, modifierId: modifier.id)
                    showComponentLibrary = false
                }
            )
        }
    }
}
