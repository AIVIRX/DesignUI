//
//  OverlayModifierEditor.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Overlay Modifier Editor
struct OverlayModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var overlayType: String = "color"
    @State private var showComponentLibrary = false
    @FocusState private var isOverlayTextFocused: Bool
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { modifier.properties["color"] = $0 }
        )
    }
    
    private var overlayText: Binding<String> {
        Binding(
            get: { modifier.properties["text"] as? String ?? "Overlay" },
            set: { modifier.properties["text"] = $0 }
        )
    }
    
    private var overlayPosition: Binding<String> {
        Binding(
            get: { modifier.properties["position"] as? String ?? "topTrailing" },
            set: { modifier.properties["position"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Overlay type picker
            Picker("Type", selection: $overlayType) {
                Text("Color").tag("color")
                Text("Text Badge").tag("text")
            }
            .pickerStyle(.segmented)
            .onChange(of: overlayType) { _, newValue in
                modifier.properties["overlayType"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
            
            if overlayType == "color" {
                // Color overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay Color")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ColorPicker("Color", selection: color)
                        .labelsHidden()
                }
            } else {
                // Text overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay Text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Overlay", text: overlayText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isOverlayTextFocused)
                        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                            isOverlayTextFocused = false
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                            isOverlayTextFocused = false
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Position", selection: overlayPosition) {
                        Text("Top Leading").tag("topLeading")
                        Text("Top Trailing").tag("topTrailing")
                        Text("Bottom Leading").tag("bottomLeading")
                        Text("Bottom Trailing").tag("bottomTrailing")
                        Text("Center").tag("center")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .onAppear {
            overlayType = modifier.properties["overlayType"] as? String ?? "color"
        }
        
        Divider()
            .padding(.vertical, 8)
        
        // Component overlay section
        VStack(alignment: .leading, spacing: 8) {
            Text("Component Overlay")
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
                // Show existing child
                ForEach(modifierChildren) { child in
                    HStack {
                        Image(systemName: child.type.icon)
                            .font(.caption)
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
                }
                
                Button(action: { showComponentLibrary = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Replace")
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
                    // Remove existing children first (overlay only supports one)
                    let existingChildren = component.getChildrenForModifier(modifier.id)
                    for child in existingChildren {
                        component.removeChild(child)
                    }
                    component.addModifierChild(newComponent, modifierId: modifier.id)
                    showComponentLibrary = false
                }
            )
        }
    }
}
