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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Properties content
            if let component = selectedComponent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Properties
                        PropertiesSection(component: component)
                                                
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

struct PropertiesSection: View {
    @ObservedObject var component: UIComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(component.type.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(component.properties) { property in
                    PropertyEditor(property: property, component: component)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
            )
            
        }
    }
}

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch property.type {
            case .string:
                TextField("Hello World", text: Binding(
                    get: { property.value as? String ?? "" },
                    set: { component.setProperty(key: property.key, value: $0) }
                ))
                .font(.headline).fontWeight(.regular)
                .padding(4)
                .textFieldStyle(.plain)
                
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
                
            case .segmentedControl:
                Picker(property.key, selection: Binding(
                    get: { property.value as? String ?? "center" },
                    set: { component.setProperty(key: property.key, value: $0) }
                )) {
                    ForEach(property.options as? [String] ?? [], id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
            case .dropdown:
                HStack {
                    Text(property.key.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(property.value as? String ?? "Default")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    // TODO: Show dropdown menu
                }
                
            case .spacing:
                HStack {
                    Text(property.key.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(property.value as? String ?? "Default")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    // TODO: Show spacing picker
                }
                
            default:
                Text("Unsupported property type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
#endif
