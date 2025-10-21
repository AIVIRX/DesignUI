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
                        
                        // Delete Component Button
                        DeleteComponentSection(component: component, canvasManager: canvasManager, selectedComponent: $selectedComponent)
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
                ForEach(Array(component.properties.enumerated()), id: \.element.id) { index, property in
                    PropertyEditor(property: property, component: component)
                    
                    if index < component.properties.count - 1 {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.1))
            )
        }
    }
}

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    @State private var textValue: String = ""
    @State private var numberValue: Double = 0.0
    
    private let fontStyles = [
        "largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"
    ]
    
    private var displayName: String {
        switch property.key {
        case "fontWeight": return "Font Weight"
        case "fontSize": return "Font Size"
        case "foregroundColor": return "Foreground Color"
        case "backgroundColor": return "Background"
        case "cornerRadius": return "Corner Radius"
        case "imageName": return "Image"
        case "title": return "Title"
        case "text": return "Text"
        case "alignment": return "Alignment"
        case "spacing": return "Spacing"
        case "padding": return "Padding"
        case "opacity": return "Opacity"
        case "rotation": return "Rotation"
        case "shadow": return "Shadow"
        case "border": return "Border"
        case "gradient": return "Gradient"
        case "resizable": return "Resizable"
        case "aspectRatio": return "Aspect Ratio"
        default: return property.key.capitalized
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch property.type {
            case .string:
                TextField("Hello World", text: $textValue)
                    .font(.system(size: 13, weight: .medium))
                    .textFieldStyle(.plain)
                    .onAppear {
                        textValue = property.value as? String ?? ""
                    }
                    .onReceive(component.objectWillChange) { _ in
                        if let stringValue = component.getProperty(key: property.key) as? String {
                            textValue = stringValue
                        }
                    }
                    .onChange(of: textValue) { _, newValue in
                        component.setProperty(key: property.key, value: newValue)
                    }
                    .onSubmit {
                        // Commit the final value when Enter is pressed
                        component.setProperty(key: property.key, value: textValue)
                    }
                
            case .number:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    TextField("", value: $numberValue, format: .number)
                    .font(.system(size: 13, weight: .medium))
                    .textFieldStyle(.plain)
                    .onAppear {
                        numberValue = property.value as? Double ?? 0.0
                    }
                    .onReceive(component.objectWillChange) { _ in
                        if let doubleValue = component.getProperty(key: property.key) as? Double {
                            numberValue = doubleValue
                        }
                    }
                    .onChange(of: numberValue) { _, newValue in
                        component.setProperty(key: property.key, value: newValue)
                    }
                    .onSubmit {
                        // Commit the final value when Enter is pressed
                        component.setProperty(key: property.key, value: numberValue)
                    }
                }
            case .boolean:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { component.getProperty(key: property.key) as? Bool ?? false },
                        set: { newValue in
                            DispatchQueue.main.async {
                                component.setProperty(key: property.key, value: newValue)
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                }
                
            case .color:
                ColorPopover(property: property, component: component)
                
            case .font:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { component.getProperty(key: property.key) as? String ?? (property.key == "fontSize" ? "body" : "regular") },
                        set: { newValue in
                            DispatchQueue.main.async {
                                component.setProperty(key: property.key, value: newValue)
                            }
                        }
                    )) {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
            case .alignment:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { component.getProperty(key: property.key) as? String ?? "center" },
                        set: { newValue in
                            DispatchQueue.main.async {
                                component.setProperty(key: property.key, value: newValue)
                            }
                        }
                    )) {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
            case .segmentedControl:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { component.getProperty(key: property.key) as? String ?? "center" },
                        set: { newValue in
                            DispatchQueue.main.async {
                                component.setProperty(key: property.key, value: newValue)
                            }
                        }
                    )) {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
            case .dropdown:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(component.getProperty(key: property.key) as? String ?? "Default")
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
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(component.getProperty(key: property.key) as? String ?? "Default")
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
                
            case .cornerRadius:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    TextField("", value: $numberValue, format: .number)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .onAppear {
                            numberValue = property.value as? Double ?? 0.0
                        }
                        .onReceive(component.objectWillChange) { _ in
                            if let doubleValue = component.getProperty(key: property.key) as? Double {
                                numberValue = doubleValue
                            }
                        }
                        .onChange(of: numberValue) { _, newValue in
                            DispatchQueue.main.async {
                                component.setProperty(key: property.key, value: newValue)
                            }
                        }
                        .onSubmit {
                            DispatchQueue.main.async {
                                component.setProperty(key: property.key, value: numberValue)
                            }
                        }
                }
                
            default:
                Text("Unsupported property type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}


// MARK: - Color Popover
struct ColorPopover: View {
    let property: ComponentProperty
    @ObservedObject var component: UIComponent
    @State private var isPresented = false
    
    private var displayName: String {
        switch property.key {
        case "fontWeight": return "Weight"
        case "fontSize": return "Size"
        case "foregroundColor": return "Color"
        case "backgroundColor": return "Background"
        case "cornerRadius": return "Corner Radius"
        case "imageName": return "Image"
        case "title": return "Title"
        case "text": return "Text"
        case "alignment": return "Alignment"
        case "spacing": return "Spacing"
        case "padding": return "Padding"
        case "opacity": return "Opacity"
        case "rotation": return "Rotation"
        case "scale": return "Scale"
        case "offset": return "Offset"
        case "shadow": return "Shadow"
        case "border": return "Border"
        case "gradient": return "Gradient"
        case "animation": return "Animation"
        case "resizable": return "Resizable"
        case "aspectRatio": return "Aspect Ratio"
        default: return property.key.capitalized
        }
    }
    
    private let swiftUIColors: [(String, Color)] = [
        ("Primary", .primary),
        ("Second", .secondary),
        ("Black", .black),
        ("White", .white),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Mint", .mint),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Blue", .blue),
        ("Indigo", .indigo),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Brown", .brown),
        ("Gray", .gray),
        ("Clear", .clear)
    ]
    
    var body: some View {
        HStack {
            Text(displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { isPresented = true }) {
                HStack(spacing: 6) {
                    // Color preview circle
                    Circle()
                        .fill(component.getProperty(key: property.key) as? Color ?? Color.primary)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(colorName(for: component.getProperty(key: property.key) as? Color ?? Color.primary))
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(swiftUIColors, id: \.0) { colorName, color in
                              Button(action: {
                                  DispatchQueue.main.async {
                                      component.setProperty(key: property.key, value: color)
                                  }
                                  isPresented = false
                              }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        Group {
                                            if isSelected(color) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .shadow(color: .black, radius: 1)
                                            }
                                        }
                                    )
                                
                                Text(colorName)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
            .frame(width: 200)
        }
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let currentColor = component.getProperty(key: property.key) as? Color else { return false }
        
        // Try direct comparison first
        if currentColor == color {
            return true
        }
        
        // Fallback to name comparison
        let currentColorName = colorName(for: currentColor)
        let targetColorName = swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
        return currentColorName == targetColorName && currentColorName != "Custom"
    }
}

// MARK: - Delete Component Section
struct DeleteComponentSection: View {
    let component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                    Text("Delete Component")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .alert("Delete Component", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteComponent()
                }
            } message: {
                Text("Are you sure you want to delete this component? This action cannot be undone.")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
        )
    }
    
    private func deleteComponent() {
        // Remove the component from the canvas
        canvasManager.removeComponent(component)
        
        // Clear the selection
        selectedComponent = nil
    }
}
#endif


