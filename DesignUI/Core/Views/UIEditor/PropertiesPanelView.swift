//
//  PropertiesPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(iOS)
import PhotosUI
#endif
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif
#if os(iOS)
import PhotosUI
#endif
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct PropertiesPanelView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    
    var body: some View {
        VStack(alignment: .leading) {
            // Properties content
            if let component = selectedComponent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Properties
                        PropertiesSection(component: component)
                                                
                        // Modifiers
                        ModifierPanelView(component: component)
                        
                        // Component Actions
                        ComponentActionsSection(component: component, canvasManager: canvasManager, selectedComponent: $selectedComponent)
                    }.padding()
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
                // For status bar, only show isVisible
                if component.type == .statusBar {
                    HStack {
                        Text("Is Visible")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { component.isVisible },
                            set: { newValue in
                                component.isVisible = newValue
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    )
                } else {
                    // For all other components, show their properties
                    ForEach(Array(component.properties.enumerated()), id: \.element.id) { index, property in
                        PropertyEditor(property: property, component: component)
                    }
                }
            }
        }
    }
}

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    @State private var textValue: String = ""
    @State private var numberValue: Double = 0.0
    @State private var showSFSymbolPicker: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var isHovered: Bool = false
    @Environment(\.colorScheme) var colorScheme

    private let fontStyles = [
        "largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"
    ]
    
    private var displayName: String {
        return property.displayName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch property.type {
            case .string:
                if property.key == "imageData" && component.type == .image {
                    // Image picker for custom images (only show this one for image components)
                    ImagePickerEditor(property: property, component: component, useImageData: true)
                } else if property.key == "imageName" && component.type == .image {
                    // Hide imageName property - we use imageData instead
                    EmptyView()
                } else if property.key == "symbolName" {
                    // Special SF Symbol picker
                    HStack {
                        Text(displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Open SF Symbols view
                            showSFSymbolPicker = true
                        }) {
                            HStack {
                                Image(systemName: textValue.isEmpty ? "star" : textValue)
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Text(textValue.isEmpty ? "Select Symbol" : textValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            textValue = property.value as? String ?? ""
                        }
                        .onReceive(component.objectWillChange) { _ in
                            if let stringValue = component.getProperty(key: property.key) as? String {
                                textValue = stringValue
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                    )
                    .onHover { hovering in
                        isHovered = hovering
                    }
                    .contentShape(Rectangle())
                } else {
                    TextField("Hello World", text: $textValue)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorScheme == .dark ? Color.black : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
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
                }
                
            case .number:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
            case .boolean:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                
            case .color:
                
                ColorPopover(property: property, component: component)
                
            case .font:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Button(action: {
                                DispatchQueue.main.async {
                                    component.setProperty(key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
                                    .foregroundColor(.primary)
                            }
                        }
                    } label: {
                        HStack {
                            Text((component.getProperty(key: property.key) as? String ?? (property.key == "fontSize" ? "body" : "regular")).capitalized)
                                .foregroundColor(.primary)
                                                        
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                
            case .alignment:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
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

                    .pickerStyle(.menu)
                    .accentColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                
            case .segmentedControl:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
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
                    .pickerStyle(.menu)
                    .accentColor(.primary)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                
            case .dropdown:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(component.getProperty(key: property.key) as? String ?? "Default")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // TODO: Show dropdown menu
                }
                
            case .spacing:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(component.getProperty(key: property.key) as? String ?? "Default")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // TODO: Show spacing picker
                }
                
            case .cornerRadius:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
                .contentShape(Rectangle())
                
            default:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Unsupported property type")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .popover(isPresented: $showSFSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $textValue) { selectedSymbol in
                component.setProperty(key: property.key, value: selectedSymbol)
                textValue = selectedSymbol
            }
        }
    }
}


// MARK: - Color Popover
struct ColorPopover: View {
    let property: ComponentProperty
    @ObservedObject var component: UIComponent
    @State private var isPresented = false
    @State private var isHovered = false
    
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
        ("Primary", Color.black),
        ("Secondary", .secondary),
        ("Tertiary", .primary.opacity(0.6)),
        ("Quaternary", .primary.opacity(0.3)),
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
        ("Gray2", Color(red: 0.99, green: 0.99, blue: 0.99)),
        ("Gray3", Color(red: 0.95, green: 0.95, blue: 0.97)),
        ("Gray4", Color(red: 0.90, green: 0.90, blue: 0.92)),
        ("Gray5", Color(red: 0.85, green: 0.85, blue: 0.87)),
        ("Gray6", Color(red: 0.78, green: 0.78, blue: 0.80)),
        ("Clear", .clear)
    ]
    
    var body: some View {
        HStack {
            Text(displayName)
                .font(.system(size: 12, weight: .medium))
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
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Color Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(swiftUIColors, id: \.0) { colorName, color in
                              Button(action: {
                                  DispatchQueue.main.async {
                                      component.setProperty(key: property.key, value: color)
                                  }
                                  isPresented = false
                              }) {
                            VStack(spacing: 4) {
                                Group {
                                    if colorName == "Primary" {
                                        // Split circle for Primary color
                                        ZStack {
                                            Circle()
                                                .fill(Color.black)
                                                .frame(width: 32, height: 32)
                                            
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 32, height: 32)
                                                .mask(
                                                    Rectangle()
                                                        .frame(width: 16, height: 32)
                                                        .offset(x: 8)
                                                )
                                        }
                                    } else if colorName == "Clear" {
                                        // Special visual for Clear color
                                        ZStack {
                                            Circle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                            
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                .frame(width: 32, height: 32)
                                            
                                            // Diagonal line to indicate "no color"
                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(width: 2, height: 20)
                                                .rotationEffect(.degrees(45))
                                        }
                                    } else {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .contentShape(Circle())
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
            .frame(width: 220)
        }
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Primary"
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

// MARK: - Component Actions Section
struct ComponentActionsSection: View {
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Duplicate Button
            Button(action: duplicateComponent) {
                HStack {
                    Text("Duplicate")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete Button
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack {
                    Text("Delete Component")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.red) // #FF453A
                    
                    Spacer()
                    
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.red) // #FF453A
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
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
    }
    
    private func deleteComponent() {
        // Remove the component from the canvas
        canvasManager.removeComponent(component)
        
        // Clear the selection
        selectedComponent = nil
    }
    
    private func duplicateComponent() {
        // Create a deep copy of the component with all its properties and modifiers
        let duplicatedComponent = createDeepCopy(of: component)
        
        // Check if this component is a child of another component
        if let parentComponent = findParentComponent(of: component, in: canvasManager.components) {
            // Find the index of the original component in its parent
            if let originalIndex = parentComponent.children.firstIndex(where: { $0.id == component.id }) {
                // Insert the duplicate right after the original component
                parentComponent.children.insert(duplicatedComponent, at: originalIndex + 1)
            } else {
                // Fallback: add to end if index not found
                parentComponent.addChild(duplicatedComponent)
            }
        } else {
            // For root components, find the index and insert after
            if let originalIndex = canvasManager.components.firstIndex(where: { $0.id == component.id }) {
                canvasManager.components.insert(duplicatedComponent, at: originalIndex + 1)
            } else {
                // Fallback: add to end if index not found
                canvasManager.addComponent(duplicatedComponent)
            }
        }
        
        // Select the new component
        selectedComponent = duplicatedComponent
    }
    
    private func findParentComponent(of targetComponent: UIComponent, in components: [UIComponent]) -> UIComponent? {
        for component in components {
            if component.children.contains(where: { $0.id == targetComponent.id }) {
                return component
            }
            if let found = findParentComponent(of: targetComponent, in: component.children) {
                return found
            }
        }
        return nil
    }
    
    private func createDeepCopy(of component: UIComponent) -> UIComponent {
        // Create a new component with the same type
        let newComponent = UIComponent(type: component.type)
        
        // Copy all properties
        newComponent.properties = component.properties.map { property in
            ComponentProperty(
                key: property.key,
                displayName: property.displayName,
                type: property.type,
                value: property.value,
                defaultValue: property.defaultValue,
                options: property.options,
                isRequired: property.isRequired
            )
        }
        
        // Copy all modifiers with their properties
        newComponent.modifiers = component.modifiers.map { modifier in
            ComponentModifier(
                type: modifier.type,
                properties: modifier.properties
            )
        }
        
        // Copy frame with a slight offset so it's visible
        newComponent.frame = CGRect(
            x: component.frame.origin.x + 20,
            y: component.frame.origin.y + 20,
            width: component.frame.width,
            height: component.frame.height
        )
        
        // Recursively copy children
        newComponent.children = component.children.map { child in
            createDeepCopy(of: child)
        }
        
        return newComponent
    }
}

// MARK: - SF Symbol Picker View
struct SFSymbolPickerView: View {
    @Binding var selectedSymbol: String
    let onSymbolSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @State private var searchTask: Task<Void, Never>?
    
    private var filteredSymbols: [String] {
        guard !debouncedSearch.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(debouncedSearch) }
    }
    
    private var grid: [GridItem] {
        [GridItem(.adaptive(minimum: 70), spacing: 8)]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select SF Symbol")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search SF Symbols", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchTask?.cancel()
                        searchTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 180_000_000)
                            debouncedSearch = newValue
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.clear)
            
            Divider()
            
            // Symbols grid
            ScrollView {
                LazyVGrid(columns: grid, spacing: 12) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button(action: {
                            selectedSymbol = symbol
                            onSymbolSelected(symbol)
                            dismiss()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                    .symbolRenderingMode(.hierarchical)
                                
                                Text(symbol)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .frame(width: 70, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedSymbol == symbol ? Color.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedSymbol == symbol ? Color.blue : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 400) // Limit height for popover
        }
        .frame(width: 400) // Fixed width for popover
    }
}

// MARK: - Image Picker Editor
struct ImagePickerEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    var useImageData: Bool = false // If true, sets imageData property instead of the current property
    @State private var selectedImage: Data?
    #if os(iOS)
    @State private var selectedItem: PhotosPickerItem?
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(property.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            // Image preview or placeholder - tappable to open picker
            let imageDataKey = useImageData ? "imageData" : property.key
            #if os(iOS)
            // iOS: Use PhotosPicker directly as the tappable area
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                imagePreviewView(imageDataKey: imageDataKey)
            }
            #else
            // macOS: Use tappable view that opens NSOpenPanel
            imagePreviewView(imageDataKey: imageDataKey)
                .contentShape(Rectangle())
                .onTapGesture {
                    openImagePicker()
                }
            #endif
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        #if os(iOS)
        .onChange(of: selectedItem) { oldItem, newItem in
            print("🖼️ PhotosPicker item changed: \(newItem != nil ? "selected" : "nil")")
            guard let item = newItem else {
                selectedImage = nil
                return
            }
            Task {
                print("🖼️ Loading image data from PhotosPicker...")
                // Try loading as UIImage first, then convert to Data
                if let image = try? await item.loadTransferable(type: UIImage.self) {
                    print("🖼️ Successfully loaded UIImage")
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        print("🖼️ Converted to JPEG data: \(imageData.count) bytes")
                        await MainActor.run {
                            selectedImage = imageData
                        }
                    } else {
                        print("⚠️ Failed to convert UIImage to JPEG data")
                    }
                } else if let data = try? await item.loadTransferable(type: Data.self) {
                    print("🖼️ Successfully loaded image data directly: \(data.count) bytes")
                    await MainActor.run {
                        selectedImage = data
                    }
                } else {
                    print("⚠️ Failed to load image data from PhotosPicker")
                }
            }
        }
        #endif
        .onChange(of: selectedImage) { _, newImageData in
            if let imageData = newImageData {
                print("🖼️ Image selected, size: \(imageData.count) bytes")
                // Convert to base64 and store
                let base64String = imageData.base64EncodedString()
                print("🖼️ Base64 string length: \(base64String.count)")
                if useImageData {
                    // Store in imageData property
                    component.setProperty(key: "imageData", value: base64String)
                    print("✅ Stored image in imageData property")
                } else {
                    // Store in the current property
                    component.setProperty(key: property.key, value: base64String)
                    print("✅ Stored image in \(property.key) property")
                }
            }
        }
    }
    
    @ViewBuilder
    private func imagePreviewView(imageDataKey: String) -> some View {
        let imageDataString = component.getProperty(key: imageDataKey) as? String ?? ""
        
        ZStack {
            if !imageDataString.isEmpty,
               let imageData = Data(base64Encoded: imageDataString),
               let image = createImage(from: imageData) {
                // Show preview of selected image
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #endif
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 150)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Tap to Select Image")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Clear button overlay (only show if image exists)
            if !imageDataString.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Clear image
                            if useImageData {
                                component.setProperty(key: "imageData", value: "")
                            } else {
                                component.setProperty(key: property.key, value: "")
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func openImagePicker() {
        #if os(macOS)
        // Open NSOpenPanel directly for macOS (Finder)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .png, .jpeg, .tiff, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            if let url = panel.url,
               let imageData = try? Data(contentsOf: url) {
                selectedImage = imageData
            }
        }
        #else
        // For iOS, PhotosPicker will be triggered by the binding
        // The picker is already attached to the view, so we just need to programmatically trigger it
        // Since PhotosPicker doesn't support programmatic triggering easily,
        // we'll use a workaround with a button that's always present but hidden
        #endif
    }
    
    #if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
    #else
    private func createImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    #endif
}

#if os(macOS)
import AppKit
import UniformTypeIdentifiers

struct ImagePickerMacOS: View {
    @Binding var selectedImage: Data?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Image")
                .font(.headline)
            
            Button("Choose File") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.image, .png, .jpeg, .tiff, .gif]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.message = "Choose an image file"
                panel.prompt = "Choose"
                
                if panel.runModal() == .OK {
                    if let url = panel.url,
                       let imageData = try? Data(contentsOf: url) {
                        selectedImage = imageData
                        dismiss()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
#else
import PhotosUI
import UniformTypeIdentifiers

struct ImagePicker: View {
    @Binding var selectedImage: Data?
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Image")
                    .font(.headline)
                    .padding(.top)
                
                // Use PhotosPicker which shows native iOS picker with Photos, Files, etc.
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImage = data
                            dismiss()
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif

