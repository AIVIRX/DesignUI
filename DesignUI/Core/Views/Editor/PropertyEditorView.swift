//
//  PropertyEditorView.swift
//  DesignUI
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

struct PropertyEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    @State private var textValue: String = ""
    @State private var numberValue: Double = 0.0
    @State private var showSFSymbolPicker: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showImagePicker: Bool = false
    @State private var hasRegisteredUndo: Bool = false

    private let fontStyles = [
        "largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"
    ]
    
    private var displayName: String {
        return property.displayName
    }
    
    private func registerUndoIfNeeded() {
        if !hasRegisteredUndo {
            let coalesceKey = "update_property_\(component.id.uuidString)_\(property.key)"
            canvasManager.registerUndoAction("Updated \(property.key)", coalesceKey: coalesceKey)
            hasRegisteredUndo = true
        }
    }
    
    private func syncTextFromComponent() {
        if let currentValue = component.getProperty(key: property.key) as? String {
            textValue = currentValue
        } else {
            textValue = property.value as? String ?? ""
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch property.type {
            case .string:
                if (property.key == "imageData" || property.key == "imageName") && component.type == .image {
                    // Image picker for custom images (show for both keys)
                    ImagePickerEditor(property: property, component: component, canvasManager: canvasManager, useImageData: property.key == "imageData", showGallery: $showGallery, activePropertyKey: $activePropertyKey)
                } else if property.key == "symbolName" {
                    // Special SF Symbol picker
                    Button(action: {
                        showSFSymbolPicker = true
                    }) {
                        HStack {
                            Text(displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: textValue.isEmpty ? "star" : textValue)
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
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
                } else if property.key == "text" || property.key == "placeholder" {
                    // Text Component Content - Just the text field
                    TextField("Text", text: $textValue)
                        .font(.system(size: 13, weight: .medium))
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                        .onAppear {
                            // Read from component to get the latest value
                            syncTextFromComponent()
                        }
                        .onReceive(component.objectWillChange) { _ in
                            // Only sync from component when not actively editing
                            if !isTextFieldFocused,
                               let stringValue = component.getProperty(key: property.key) as? String {
                                textValue = stringValue
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                            hasRegisteredUndo = false
                            isTextFieldFocused = false
                            syncTextFromComponent()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                            hasRegisteredUndo = false
                            isTextFieldFocused = false
                            syncTextFromComponent()
                        }
                        .onChange(of: textValue) { _, newValue in
                            guard isTextFieldFocused else { return }
                            registerUndoIfNeeded()
                            canvasManager.updateComponentPropertyContinuous(for: component, key: property.key, value: newValue)
                        }
                        .onChange(of: isTextFieldFocused) { oldValue, newValue in
                            // When losing focus, ensure value is committed
                            if oldValue && !newValue {
                                hasRegisteredUndo = false
                                canvasManager.updateComponentPropertyContinuous(for: component, key: property.key, value: textValue)
                            }
                        }
                        .onSubmit {
                            canvasManager.updateComponentPropertyContinuous(for: component, key: property.key, value: textValue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    HStack {
                        TextField("Text", text: $textValue)
                            .font(.system(size: 13, weight: .medium))
                            .textFieldStyle(.plain)
                            .focused($isTextFieldFocused)
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
                            .frame(width: 120) // Fixed width for consistent alignment
                            .onAppear {
                                // Read from component to get the latest value, not the potentially stale property parameter
                                syncTextFromComponent()
                            }
                            .onReceive(component.objectWillChange) { _ in
                                // Only sync from component when not actively editing
                                if !isTextFieldFocused,
                                   let stringValue = component.getProperty(key: property.key) as? String {
                                    textValue = stringValue
                                }
                            }
                            .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                                hasRegisteredUndo = false
                                isTextFieldFocused = false
                                syncTextFromComponent()
                            }
                            .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                                hasRegisteredUndo = false
                                isTextFieldFocused = false
                                syncTextFromComponent()
                            }
                            .onChange(of: textValue) { _, newValue in
                                guard isTextFieldFocused else { return }
                                registerUndoIfNeeded()
                                canvasManager.updateComponentPropertyContinuous(for: component, key: property.key, value: newValue)
                            }
                            .onChange(of: isTextFieldFocused) { oldValue, newValue in
                                // When losing focus, ensure value is committed
                                if oldValue && !newValue {
                                    hasRegisteredUndo = false
                                    canvasManager.updateComponentPropertyContinuous(for: component, key: property.key, value: textValue)
                                }
                            }
                            .onSubmit {
                                // Commit the final value when Enter is pressed
                                canvasManager.updateComponentPropertyContinuous(for: component, key: property.key, value: textValue)
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                
            case .slider:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    let minIndex = 0
                    let maxIndex = 1
                    let min = (property.options?.count ?? 0) > minIndex ? (property.options?[minIndex] as? Double ?? 0.0) : 0.0
                    let max = (property.options?.count ?? 0) > maxIndex ? (property.options?[maxIndex] as? Double ?? 100.0) : 100.0
                    
                    Slider(value: Binding(
                        get: {
                            component.getProperty(key: property.key) as? Double ?? property.defaultValue as? Double ?? 0.0
                        },
                        set: { newValue in
                             canvasManager.updateComponentProperty(for: component, key: property.key, value: newValue)
                        }
                    ), in: min...max)
                    
                    Text(String(format: "%.0f", component.getProperty(key: property.key) as? Double ?? 0.0))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())

            case .number:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                        // Standard Number Field
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
                            if component.type == .gauge && property.key == "value" {
                                let minVal = component.getProperty(key: "min") as? Double ?? 0
                                let maxVal = component.getProperty(key: "max") as? Double ?? 100
                                let lower = min(minVal, maxVal)
                                let upper = max(minVal, maxVal)
                                let clamped = min(max(newValue, lower), upper)
                                canvasManager.updateComponentProperty(for: component, key: property.key, value: clamped)
                            } else {
                                canvasManager.updateComponentProperty(for: component, key: property.key, value: newValue)
                            }
                        }
                    ), format: .number.precision(.fractionLength(0...2)))
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
                                canvasManager.updateComponentProperty(for: component, key: property.key, value: newValue)
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: component.getProperty(key: property.key) as? Bool) { _, newValue in
                         if property.key == "showStatusBar", let value = newValue {
                             NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: value)
                         }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                .contentShape(Rectangle())
                
            case .color:
                
                ColorPropertyEditor(
                    title: displayName,
                    colorString: Binding(
                        get: { component.getProperty(key: property.key) as? String ?? property.defaultValue as? String ?? "primary" },
                        set: { canvasManager.updateComponentProperty(for: component, key: property.key, value: $0) }
                    )
                )
                
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
                                    canvasManager.updateComponentProperty(for: component, key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
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
                                    canvasManager.updateComponentProperty(for: component, key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
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
                                    canvasManager.updateComponentProperty(for: component, key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
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
                                    canvasManager.updateComponentProperty(for: component, key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized)
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
                    
                    TextField("", value: $numberValue, format: .number.precision(.fractionLength(0...2)))
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
                    canvasManager.updateComponentProperty(for: component, key: property.key, value: newValue)
                }
                .onSubmit {
                    // Commit the final value when Enter is pressed
                    canvasManager.updateComponentProperty(for: component, key: property.key, value: numberValue)
                }
                
            case .cornerRadius:
                HStack {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    TextField("", value: $numberValue, format: .number.precision(.fractionLength(0...2)))
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
                                canvasManager.updateComponentProperty(for: component, key: property.key, value: newValue)
                            }
                        }
                        .onSubmit {
                            DispatchQueue.main.async {
                                canvasManager.updateComponentProperty(for: component, key: property.key, value: numberValue)
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
                            canvasManager.updateComponentProperty(for: component, key: property.key, value: colors)
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
                                        canvasManager.updateComponentProperty(for: component, key: property.key, value: currentColors)
                                    }
                                }
                            ))
                            
                            Spacer()
                            
                            Button(action: {
                                var currentColors = (component.getProperty(key: property.key) as? [String]) ?? []
                                if index < currentColors.count {
                                    currentColors.remove(at: index)
                                    canvasManager.updateComponentProperty(for: component, key: property.key, value: currentColors)
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
                                    canvasManager.updateComponentProperty(for: component, key: property.key, value: option)
                                }
                            }) {
                                Text(option.capitalized) // Format for display: "topLeading" -> "Top Leading"? Keeping simple for now.
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
                canvasManager.updateComponentProperty(for: component, key: property.key, value: selectedSymbol)
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
                canvasManager.updateComponentProperty(for: component, key: property.key, value: selectedSymbol)
                textValue = selectedSymbol
            }
             .onReceive(NotificationCenter.default.publisher(for: .dismissChildNavigation)) { _ in
                showSFSymbolPicker = false
            }
        }
#endif
    }
}

// MARK: - Color Property Editor

