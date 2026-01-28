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
    
    // Gallery Sheet State
    @State private var showImageGallery = false
    @State private var galleryImageName = ""
    @State private var activeImagePropertyKey: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            // Properties content
            if let component = selectedComponent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Properties
                        PropertiesSection(
                            component: component,
                            showGallery: $showImageGallery,
                            activePropertyKey: $activeImagePropertyKey
                        )
                                                
                        // Modifiers and Actions - hide for status bar
                        if component.type != .statusBar {
                            ModifierPanelView(component: component, canvasManager: canvasManager)
                                // Force view recreation when component INSTANCE or modifiers change
                                // Using ObjectIdentifier ensures view recreates after undo (new instance, same ID)
                                .id("\(ObjectIdentifier(component))-\(component.modifiers.count)")
                            
                            // Component Actions
                            ComponentActionsSection(component: component, canvasManager: canvasManager, selectedComponent: $selectedComponent)
                        }
                    }
                    .padding()
                }
                // Force entire view to update when component INSTANCE changes (not just ID)
                .id(ObjectIdentifier(component))
                .sheet(isPresented: $showImageGallery, onDismiss: {
                    // Update image property when gallery closes
                    if !galleryImageName.isEmpty {
                        updateImageProperty(with: galleryImageName)
                    }
                }) {
                    ImageGalleryView(selectedImageName: $galleryImageName)
                        .presentationDetents([.medium])
                }
                .onChange(of: galleryImageName) { _, newName in
                    if !newName.isEmpty {
                        updateImageProperty(with: newName)
                    }
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
    
    // MARK: - Helper Methods
    
    private func updateImageProperty(with name: String) {
        guard let component = selectedComponent else { return }
        
        // If we are updating an Image component, we must distinguish between:
        // 1. Files/Assets (names) -> "imageName"
        // 2. Raw Data (base64) -> "imageData" (handled by ImagePickerEditor usually)
        
        // Since this method is called by the Gallery (which returns filenames),
        // we should ALWAYS prefer "imageName" for Image components.
        
        if component.type == .image {
            // Set the name and clear any conflicting data
            component.setProperty(key: "imageName", value: name)
            component.setProperty(key: "imageData", value: "")
        } else {
            // For other components (e.g. background modifiers), use the active key
            if let key = activeImagePropertyKey {
                component.setProperty(key: key, value: name)
                
                // If the key happened to be "imageName", ensure imageData is cleared
                if key == "imageName" {
                    component.setProperty(key: "imageData", value: "")
                }
            } else {
                // Fallback
                component.setProperty(key: "imageName", value: name)
                component.setProperty(key: "imageData", value: "")
            }
        }
        
        component.objectWillChange.send()
    }
}

struct PropertiesSection: View {
    @ObservedObject var component: UIComponent
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(component.type.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            // For status bar, only show isVisible
            if component.type == .statusBar {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Is Visible")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { component.isVisible },
                            set: { newValue in
                                component.isVisible = newValue
                                // Post notification to trigger save
                                NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: newValue)
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            } else {
                // For all other components, show their properties in a grouped form
                // Filter out minLength property for Spacer components, foregroundColor for all components, font properties, cornerRadius for buttons/shapes, fill for shapes, backgroundColor for SF Symbols, and imageName for images (use modifiers instead)
                let filteredProperties = component.properties.filter { property in
                    if property.key == "minLength" && component.type == .spacer {
                        return false
                    }
                    if property.key == "foregroundColor" {
                        return false // Always filter out foregroundColor - use modifier instead
                    }
                    if property.key == "fontWeight" {
                        return false // Use Font modifier instead
                    }
                    if property.key == "fontSize" {
                        return false // Use Font Size modifier instead
                    }
                    if property.key == "backgroundColor" && component.type == .sfSymbol {
                        return false // Filter out backgroundColor for SF Symbols - use modifier instead
                    }
                    if property.key == "imageName" && component.type == .image {
                        return false // Filter out imageName for images - we use imageData instead
                    }
                    if property.key == "cornerRadius" {
                        if component.type == .rectangle || component.type == .roundedRectangle || component.type == .circle || component.type == .capsule || component.type == .ellipse {
                            return false // Filter out cornerRadius for shapes - use modifier instead
                        }
                    }
                    if property.key == "fill" && (component.type == .rectangle || component.type == .roundedRectangle || component.type == .circle || component.type == .capsule || component.type == .ellipse) {
                        return false // Filter out fill for shapes - use modifier instead
                    }
                    return true
                }
                
                // Only show properties section if there are properties to display
                if !filteredProperties.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredProperties.enumerated()), id: \.element.id) { index, property in
                            PropertyEditor(property: property, component: component, showGallery: $showGallery, activePropertyKey: $activePropertyKey)
                            
                            // Add divider between properties if there are 2+ and not the last one
                            if filteredProperties.count >= 2 && index < filteredProperties.count - 1 {
                                Divider()
                                    .opacity(0.3)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        }
    }
}

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    @State private var textValue: String = ""
    @State private var numberValue: Double = 0.0
    @State private var showSFSymbolPicker: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showImagePicker: Bool = false

    @Environment(\.colorScheme) var colorScheme
    
    private var menuTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

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
                    ImagePickerEditor(property: property, component: component, useImageData: true, showGallery: $showGallery, activePropertyKey: $activePropertyKey)
                } else if property.key == "symbolName" {
                    // Special SF Symbol picker
                    HStack {
                        Text(displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        
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
                            // Read from component to get the latest value
                            if let currentValue = component.getProperty(key: property.key) as? String {
                                textValue = currentValue
                            } else {
                                textValue = property.value as? String ?? ""
                            }
                        }
                        .onReceive(component.objectWillChange) { _ in
                            if let stringValue = component.getProperty(key: property.key) as? String {
                                textValue = stringValue
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    .contentShape(Rectangle())
                } else {
                    TextField("Hello World", text: $textValue)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .onAppear {
                            // Read from component to get the latest value, not the potentially stale property parameter
                            if let currentValue = component.getProperty(key: property.key) as? String {
                                textValue = currentValue
                            } else {
                                textValue = property.value as? String ?? ""
                            }
                        }
                        .onReceive(component.objectWillChange) { _ in
                            // Only sync from component when not actively editing
                            if !isTextFieldFocused,
                               let stringValue = component.getProperty(key: property.key) as? String {
                                textValue = stringValue
                            }
                        }
                        .onChange(of: textValue) { _, newValue in
                            component.setProperty(key: property.key, value: newValue)
                        }
                        .onChange(of: isTextFieldFocused) { oldValue, newValue in
                            // When losing focus, ensure value is committed
                            if oldValue && !newValue {
                                component.setProperty(key: property.key, value: textValue)
                            }
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
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Use computed binding that reads directly from component
                    TextField("", value: Binding(
                        get: {
                            if let val = component.getProperty(key: property.key) as? Double {
                                return val
                            } else if let val = component.getProperty(key: property.key) as? Int {
                                return Double(val)
                            }
                            return property.value as? Double ?? (property.value as? Int).map { Double($0) } ?? 0.0
                        },
                        set: { newValue in
                            component.setProperty(key: property.key, value: newValue)
                        }
                    ), format: .number)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                        .frame(width: 80) // Fixed width for number input
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                .contentShape(Rectangle())
            case .boolean:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
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

                .contentShape(Rectangle())
                
            case .color:
                
                ColorPopover(property: property, component: component)
                
            case .font:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
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

                .contentShape(Rectangle())
                
            case .alignment:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Button(action: {
                                DispatchQueue.main.async {
                                    component.setProperty(key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
                                    .foregroundColor(menuTextColor)
                            }
                        }
                    } label: {
                        HStack {
                            Text((component.getProperty(key: property.key) as? String ?? "center").capitalized)
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

                .contentShape(Rectangle())
                
            case .segmentedControl:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Button(action: {
                                DispatchQueue.main.async {
                                    component.setProperty(key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
                                    .foregroundColor(menuTextColor)
                            }
                        }
                    } label: {
                        HStack {
                            Text((component.getProperty(key: property.key) as? String ?? (property.options as? [String])?.first ?? "").capitalized)
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

                .contentShape(Rectangle())
                
            case .dropdown:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Button(action: {
                                DispatchQueue.main.async {
                                    component.setProperty(key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
                                    .foregroundColor(menuTextColor)
                            }
                        }
                    } label: {
                        HStack {
                            Text((component.getProperty(key: property.key) as? String ?? (property.options as? [String])?.first ?? "Default").capitalized)
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

                .contentShape(Rectangle())
                
            case .spacing:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    TextField("", value: $numberValue, format: .number)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        
                        .frame(width: 80) // Fixed width for number input
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                .contentShape(Rectangle())
                .onAppear {
                    if let doubleValue = component.getProperty(key: property.key) as? Double {
                        numberValue = doubleValue
                    } else if let stringValue = component.getProperty(key: property.key) as? String,
                              let doubleValue = Double(stringValue) {
                        numberValue = doubleValue
                    }
                }
                .onReceive(component.objectWillChange) { _ in
                    if let doubleValue = component.getProperty(key: property.key) as? Double {
                        numberValue = doubleValue
                    } else if let stringValue = component.getProperty(key: property.key) as? String,
                              let doubleValue = Double(stringValue) {
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
                
            case .cornerRadius:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    TextField("", value: $numberValue, format: .number)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .onAppear {
                            // Read from component to get the latest value
                            if let currentValue = component.getProperty(key: property.key) as? Double {
                                numberValue = currentValue
                            } else {
                                numberValue = property.value as? Double ?? 0.0
                            }
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

                .contentShape(Rectangle())
                
            case .colorArray:
                VStack(spacing: 8) {
                    HStack {
                        Text(displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            var colors = (component.getProperty(key: property.key) as? [String]) ?? []
                            colors.append("blue:1.0")
                            component.setProperty(key: property.key, value: colors)
                        }) {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    let colors = (component.getProperty(key: property.key) as? [String]) ?? []
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, colorStr in
                        HStack {
                            GradientColorPicker(colorString: Binding(
                                get: { 
                                    let currentColors = (component.getProperty(key: property.key) as? [String]) ?? []
                                    return index < currentColors.count ? currentColors[index] : "blue:1.0"
                                },
                                set: { newVal in
                                    var currentColors = (component.getProperty(key: property.key) as? [String]) ?? []
                                    if index < currentColors.count {
                                        currentColors[index] = newVal
                                        component.setProperty(key: property.key, value: currentColors)
                                    }
                                }
                            ))
                            
                            Spacer()
                            
                            Button(action: {
                                var currentColors = (component.getProperty(key: property.key) as? [String]) ?? []
                                if index < currentColors.count {
                                    currentColors.remove(at: index)
                                    component.setProperty(key: property.key, value: currentColors)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)


            case .unitPoint:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(property.options as? [String] ?? [], id: \.self) { option in
                            Button(action: {
                                DispatchQueue.main.async {
                                    component.setProperty(key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized) // Format for display: "topLeading" -> "Top Leading"? Keeping simple for now.
                                    .foregroundColor(menuTextColor)
                            }
                        }
                    } label: {
                        HStack {
                            Text((component.getProperty(key: property.key) as? String ?? "top").capitalized)
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

                
            default:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Unsupported property type")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
#if os(iOS)
        .sheet(isPresented: $showSFSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $textValue) { selectedSymbol in
                component.setProperty(key: property.key, value: selectedSymbol)
                textValue = selectedSymbol
            }
             .onReceive(NotificationCenter.default.publisher(for: .dismissChildNavigation)) { _ in
                showSFSymbolPicker = false
            }
            .presentationDetents([.medium, .large])
        }
#else
        .popover(isPresented: $showSFSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $textValue) { selectedSymbol in
                component.setProperty(key: property.key, value: selectedSymbol)
                textValue = selectedSymbol
            }
             .onReceive(NotificationCenter.default.publisher(for: .dismissChildNavigation)) { _ in
                showSFSymbolPicker = false
            }
        }
#endif
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
        case "fontSize": return "Size"
        case "foregroundColor": return "Color"
        case "backgroundColor": return "Background"
        case "cornerRadius": return "Corner Radius"
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
    

    
    private var currentColor: Color {
        component.getProperty(key: property.key) as? Color ?? Color.primary
    }
    
    var body: some View {
        HStack {
            Text(displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            colorPickerButton
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
            colorPopoverContent
        }
    }
    
    private var colorPickerButton: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(currentColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text(colorName(for: currentColor))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var colorPopoverContent: some View {
        // Use a simple list-based picker matching UniversalColorPickerView
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 0) {
                    ForEach(UniversalColorPickerView.swiftUIColors, id: \.name) { colorInfo in
                        ColorRowView(
                            colorName: colorInfo.name,
                            displayName: colorInfo.displayName,
                            color: colorInfo.color,
                            isSelected: colorName(for: currentColor).lowercased() == colorInfo.name,
                            onSelect: {
                                DispatchQueue.main.async {
                                    self.component.setProperty(key: self.property.key, value: colorInfo.name)
                                }
                                isPresented = false
                            }
                        )
                        
                        if colorInfo.name != UniversalColorPickerView.swiftUIColors.last?.name {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .frame(minWidth: 280, maxHeight: 400)
    }
    
    // Helper to get display name for the button label
    private func colorName(for color: Color) -> String {
        // Reverse lookup in UniversalColorPickerView
        if let match = UniversalColorPickerView.swiftUIColors.first(where: { $0.color == color }) {
            return match.displayName
        }
        return "Custom"
    }
    
}

// MARK: - Component Actions Section
struct ComponentActionsSection: View {
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    
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
            Button(action: deleteComponent) {
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
#if os(macOS)
            .keyboardShortcut(.delete, modifiers: [])
#endif
        }
    }
    
    private func deleteComponent() {
        // Use selectedComponent binding to ensure we delete the CURRENTLY selected component
        guard let componentToDelete = selectedComponent else { return }
        
        // Remove the component from the canvas
        canvasManager.removeComponent(componentToDelete)
        
        // Clear the selection
        selectedComponent = nil
    }
    
    private func duplicateComponent() {
        // Use CanvasManager's duplicateComponent which has proper undo registration
        canvasManager.duplicateComponent(component)
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
        }
        .frame(width: 400, height: 500) // Fixed width and height for popover to support scrolling
    }
}

// MARK: - Image Picker Editor
struct ImagePickerEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    var useImageData: Bool = false
    
    // Bindings to parent view state for gallery sheet
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    
    @State private var selectedImage: Data?
    #if os(iOS)
    @State private var selectedItem: PhotosPickerItem?
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            // macOS: Tappable view that opens gallery
            imagePreviewView(imageDataKey: imageDataKey)
                .contentShape(Rectangle())
                .onTapGesture {
                    activePropertyKey = property.key
                    showGallery = true
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
                // Load as Data since UIImage doesn't conform to Transferable
                if let data = try? await item.loadTransferable(type: Data.self) {
                    print("🖼️ Successfully loaded image data: \(data.count) bytes")
                    // Verify it's a valid image and compress if needed
                    if let image = UIImage(data: data) {
                        if let compressedData = image.jpegData(compressionQuality: 0.8) {
                            print("🖼️ Compressed to JPEG: \(compressedData.count) bytes")
                            await MainActor.run {
                                selectedImage = compressedData
                            }
                        } else {
                            // Use original data if compression fails
                            await MainActor.run {
                                selectedImage = data
                            }
                        }
                    } else {
                        print("⚠️ Data is not a valid image")
                    }
                } else {
                    print("⚠️ Failed to load image data from PhotosPicker")
                }
            }
        }
        #endif
        .onChange(of: selectedImage) { _, newImageData in
            if let imageData = newImageData {
                print("🖼️ Image selected, original size: \(imageData.count) bytes")
                
                // Aggressively compress and resize BEFORE base64 encoding to prevent lag
                // This converts 4K images to tiny 512px thumbnails
                let finalData: Data
                if let compressed = ImageGalleryManager.compressAndResizeImage(data: imageData) {
                    finalData = compressed
                    print("🖼️ Compressed to: \(finalData.count) bytes")
                } else {
                    finalData = imageData
                    print("⚠️ Compression failed, using original data")
                }
                
                // Auto-save to Library (Syncs to iCloud)
                if let filename = ImageGalleryManager.shared.saveImage(data: finalData) {
                    print("✅ Saved to Image Library: \(filename)")
                    // Update imageName so it uses the synced file (Priority 1)
                    component.setProperty(key: "imageName", value: filename)
                }
                
                // Convert to base64 and store (Portable Backup)
                let base64String = finalData.base64EncodedString()
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
        let baseImageName = component.getProperty(key: "imageName") as? String ?? ""
        
        ZStack {
            // Priority 1: Gallery filename from imageName property
            if !baseImageName.isEmpty,
               let fileURL = ImageGalleryManager.shared.getImageUrl(filename: baseImageName),
               FileManager.default.fileExists(atPath: fileURL.path) {
                AsyncImage(url: fileURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    case .empty:
                        ProgressView()
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(maxWidth: .infinity, maxHeight: 150)
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Tap to select image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    @unknown default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(maxWidth: .infinity, maxHeight: 150)
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Tap to select image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .id(baseImageName)
            }
            // Priority 2: Direct load via ImageGalleryManager (Bundled Assets match here)
            else if !baseImageName.isEmpty, let platformImage = ImageGalleryManager.shared.loadImage(filename: baseImageName) {
                #if os(macOS)
                Image(nsImage: platformImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #else
                Image(uiImage: platformImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #endif
            }
            // Priority 3: Gallery filename from imageData property (old components)
            else if baseImageName.isEmpty && !imageDataString.isEmpty,
                    (imageDataString.hasSuffix(".jpg") || imageDataString.hasSuffix(".jpeg") || imageDataString.hasSuffix(".png") || imageDataString.hasSuffix(".gif") || imageDataString.hasSuffix(".heic") || ImageGalleryManager.shared.getAllImageFilenames().contains(imageDataString)) {
                
                Group {
                    // Try to load as file first
                    if let fileURL = ImageGalleryManager.shared.getImageUrl(filename: imageDataString),
                       FileManager.default.fileExists(atPath: fileURL.path) {
                        AsyncImage(url: fileURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            case .empty:
                                ProgressView()
                            case .failure:
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    // Fallback to load via Manager (for bundled assets in imageData)
                    else if let platformImage = ImageGalleryManager.shared.loadImage(filename: imageDataString) {
                        #if os(macOS)
                        Image(nsImage: platformImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        #else
                        Image(uiImage: platformImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        #endif
                    }
                    // If neither file nor bundled asset, show placeholder
                    else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(maxWidth: .infinity, maxHeight: 150)
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Tap to select image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .id(imageDataString)
            }
            // Priority 4: Base64 image data
            else if !imageDataString.isEmpty,
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
                                component.setProperty(key: "imageName", value: "")
                            } else {
                                component.setProperty(key: property.key, value: "")
                                // If using a custom property key that isn't imageData, we might technically store filename elsewhere, but let's clear imageName too just in case
                                component.setProperty(key: "imageName", value: "")
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
                // Extract filename without extension
                let filename = url.deletingPathExtension().lastPathComponent
                component.setProperty(key: "imageName", value: filename)
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


// MARK: - Simple Color Picker (For Arrays)
struct SimpleColorPicker: View {
    @Binding var colorString: String
    @State private var isPresented = false
    @State private var isHovered = false
    
    private let swiftUIColors: [(String, Color)] = [
        ("Primary", .primary),
        ("Secondary", .secondary),
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
    
    private var currentColor: Color {
        ComponentProperty.colorStringToColor(colorString)
    }
    
    private func colorName(for color: Color) -> String {
        // Simple check against basic colors
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }

    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(currentColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text(colorString.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(swiftUIColors, id: \.0) { colorName, color in
                         Button(action: {
                            colorString = colorName.lowercased()
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
}

// NOTE: StandardColorPickerContent has been removed
// Use UniversalColorPickerView from ColorModifierEditor.swift instead

struct GradientColorPicker: View {
    @Binding var colorString: String
    @State private var isPresented = false
    @State private var selectedColorName: String = "blue"
    @State private var opacityValue: Double = 1.0
    
    private var currentColor: Color {
        let color = UniversalColorPickerView.color(for: selectedColorName)
        return color.opacity(opacityValue)
    }
    
    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 6) {
                // Color preview with transparency indicator
                ZStack {
                    if opacityValue < 1.0 {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 20, height: 20)
                    }
                    Circle()
                        .fill(currentColor)
                        .frame(width: 20, height: 20)
                }
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text("\(selectedColorName.capitalized) \(opacityValue < 1.0 ? "(\(Int(opacityValue * 100))%)" : "")")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            parseColorString()
        }
        .popover(isPresented: $isPresented) {
            // Use the universal color picker
            UniversalColorPickerView(
                selectedColorName: $selectedColorName,
                opacityValue: $opacityValue,
                title: "Gradient Color",
                onColorChanged: {
                    saveColor()
                },
                onColorConfirmed: {
                    saveColor()
                }
            )
        }
    }
    
    private func parseColorString() {
        let parts = colorString.split(separator: ":")
        if parts.count >= 1 {
            selectedColorName = String(parts[0]).lowercased()
        }
        if parts.count >= 2, let opacity = Double(parts[1]) {
            opacityValue = opacity
        } else {
            opacityValue = 1.0
        }
    }
    
    private func saveColor() {
        colorString = "\(selectedColorName):\(opacityValue)"
    }
}
