//
//  PropertiesPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
struct PropertiesPanelView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Properties")
                    .font(.headline)
                
                Spacer()
                
                if selectedComponent != nil {
                    Button(action: { selectedComponent = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                    }
                    .help("Deselect")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Properties content
            if let component = selectedComponent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Component info
                        ComponentInfoSection(component: component)
                        
                        // Properties
                        PropertiesSection(component: component)
                        
                        // Style properties
                        StyleSection(component: component)
                        
                        // Modifiers
                        ModifierPanelView(component: component)
                    }
                    .padding(16)
                }
            } else {
                // No selection state
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No Selection")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Select a component to edit its properties")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            }
        }
    }
}

struct ComponentInfoSection: View {
    @ObservedObject var component: UIComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Component Info")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Type:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(component.type.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Position:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("(\(Int(component.frame.origin.x)), \(Int(component.frame.origin.y)))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Size:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(component.frame.width)) × \(Int(component.frame.height))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
}

struct PropertiesSection: View {
    @ObservedObject var component: UIComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Properties")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(component.properties) { property in
                    PropertyEditor(property: property, component: component)
                }
            }
        }
    }
}

struct StyleSection: View {
    @ObservedObject var component: UIComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                // Visibility
                HStack {
                    Toggle("Visible", isOn: Binding(
                        get: { component.isVisible },
                        set: { component.isVisible = $0 }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }
                
                // Z-Index
                HStack {
                    Text("Z-Index:")
                        .font(.caption)
                    
                    Slider(value: Binding(
                        get: { Double(component.zIndex) },
                        set: { component.zIndex = Int($0) }
                    ), in: 0...100)
                    
                    Text("\(component.zIndex)")
                        .font(.caption)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
}

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(property.key.capitalized)
                .font(.caption)
                .fontWeight(.medium)
            
            switch property.type {
            case .string:
                TextField(property.key, text: Binding(
                    get: { property.value as? String ?? "" },
                    set: { component.setProperty(key: property.key, value: $0) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            case .number:
                TextField(property.key, value: Binding(
                    get: { property.value as? Double ?? 0.0 },
                    set: { component.setProperty(key: property.key, value: $0) }
                ), format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            case .boolean:
                Toggle(property.key, isOn: Binding(
                    get: { property.value as? Bool ?? false },
                    set: { component.setProperty(key: property.key, value: $0) }
                ))
                .toggleStyle(SwitchToggleStyle())
                
            case .color:
                ColorPicker(property.key, selection: Binding(
                    get: { property.value as? Color ?? Color.primary },
                    set: { component.setProperty(key: property.key, value: $0) }
                ))
                
            case .font:
                Picker(property.key, selection: Binding(
                    get: { property.value as? String ?? "regular" },
                    set: { component.setProperty(key: property.key, value: $0) }
                )) {
                    ForEach(property.options as? [String] ?? [], id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
            case .alignment:
                Picker(property.key, selection: Binding(
                    get: { property.value as? String ?? "center" },
                    set: { component.setProperty(key: property.key, value: $0) }
                )) {
                    ForEach(property.options as? [String] ?? [], id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
            default:
                Text("Unsupported property type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
#endif
