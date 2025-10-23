//
//  PropertiesPanelView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

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
            .background(Color.secondary.opacity(0.1))
            
            Divider()
            
            // Properties content
            if let component = selectedComponent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Properties
                        PropertiesSection(component: component)
                                                
                        // Modifiers
                        ModifierPanelView(component: component)
                        
                        // Duplicate Component Button
                        DuplicateComponentSection(component: component, canvasManager: canvasManager, selectedComponent: $selectedComponent)
                        
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
                    .fill(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
            )
        }
    }
}

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    @State private var textValue: String = ""
    @State private var numberValue: Double = 0.0
    @State private var showSFSymbolPicker: Bool = false
    
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
                if property.key == "symbolName" {
                    // Special SF Symbol picker
                    HStack {
                        Text(displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                        
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
                } else {
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
                }
                
            case .number:
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
    @State private var opacity: Double = 1.0
    
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                    // Opacity Text Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("100", value: $opacity, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    updateColorWithOpacity(opacity)
                                }
                            
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                .padding(.bottom, 8)
                
                Divider()
                
                // Color Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(swiftUIColors, id: \.0) { colorName, color in
                              Button(action: {
                                  DispatchQueue.main.async {
                                      let colorWithOpacity = color.opacity(opacity)
                                      component.setProperty(key: property.key, value: colorWithOpacity)
                                  }
                                  isPresented = false
                              }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color.opacity(opacity))
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
            .frame(width: 220)
            .onAppear {
                // Initialize opacity from current color
                if component.getProperty(key: property.key) as? Color != nil {
                    // For now, default to full opacity since extracting opacity from Color is complex
                    opacity = 1.0
                }
            }
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
    
    private func updateColorWithOpacity(_ newOpacity: Double) {
        // Get the current color and apply the new opacity
        if let currentColor = component.getProperty(key: property.key) as? Color {
            // Find the base color without opacity
            let baseColor = findBaseColor(for: currentColor)
            let colorWithOpacity = baseColor.opacity(newOpacity)
            component.setProperty(key: property.key, value: colorWithOpacity)
        }
    }
    
    private func findBaseColor(for color: Color) -> Color {
        // Try to find the base color by comparing with known colors
        for (_, baseColor) in swiftUIColors {
            if color == baseColor {
                return baseColor
            }
        }
        // If no match found, return the color as-is
        return color
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
                        .fill(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
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
}

struct DuplicateComponentSection: View {
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
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
                        .fill(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
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
            .background(Color.secondary.opacity(0.1))
            
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
            .background(Color.secondary.opacity(0.1))
            
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


