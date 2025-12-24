//
//  BackgroundModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Component Library for Modifier
struct ComponentLibraryForModifierView: View {
    let modifier: ComponentModifier
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

// MARK: - Background Modifier Editor
struct BackgroundModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var isPresented = false
    @State private var opacityText: String = ""
    @State private var showComponentLibrary = false
    @State private var backgroundMode: String = "color"
    
    private var currentColor: Color {
        modifier.getColor(key: "color", defaultValue: .clear)
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
        ("Clear", .clear)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Mode Picker
            Picker("", selection: $backgroundMode) {
                Text("Color").tag("color")
                Text("Gradient").tag("gradient")
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)
            .onAppear {
                if modifier.properties["gradient"] != nil {
                    backgroundMode = "gradient"
                }
            }
            
            if backgroundMode == "color" {
                colorSection
            } else {
                GradientEditor(modifier: $modifier)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Component background section
            VStack(alignment: .leading, spacing: 8) {
                Text("Component Background")
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
                            Text("Add Another")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sheet(isPresented: $showComponentLibrary) {
            ComponentLibraryForModifierView(
                modifier: modifier,
                component: component,
                onAdd: { newComponent in
                    component.addModifierChild(newComponent, modifierId: modifier.id)
                    showComponentLibrary = false
                }
            )
        }
    }
    
    private var colorSection: some View {
        HStack {
            Text("Background Color")
            
            Spacer()
            
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
            colorPickerPopoverContent
        }
    }
    
    private var colorPickerPopoverContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Background Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Opacity Text Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Opacity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("100", text: $opacityText)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: opacityText) { _, newValue in
                                if newValue.isEmpty { return }
                                if let percentage = Double(newValue), percentage >= 0 && percentage <= 100 {
                                    let opacity = percentage / 100.0
                                    updateColorWithOpacity(opacity)
                                }
                            }
                            .onSubmit {
                                if opacityText.isEmpty || Double(opacityText) == nil {
                                    opacityText = "100"
                                }
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
                                let opacityValue = Double(opacityText) ?? 100.0
                                let opacity = max(0, min(100, opacityValue)) / 100.0
                                
                                if opacity >= 0.99 && colorName != "Custom" && colorName != "Primary" {
                                    modifier.properties["color"] = "color:\(colorName.lowercased())"
                                } else {
                                    modifier.properties["color"] = color.opacity(opacity)
                                }
                                // Disable gradient when picking color
                                modifier.properties["gradient"] = nil
                                NotificationCenter.default.post(name: .designChanged, object: nil)
                            }
                            isPresented = false
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color.opacity((Double(opacityText) ?? 100.0) / 100.0))
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
                opacityText = "100"
            }
        }
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let currentColor = modifier.properties["color"] as? Color else { return false }
        if currentColor == color { return true }
        let currentColorName = colorName(for: currentColor)
        let targetColorName = swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
        return currentColorName == targetColorName && currentColorName != "Custom"
    }
    
    private func updateColorWithOpacity(_ newOpacity: Double) {
        if let currentColor = modifier.properties["color"] as? Color {
            let baseColor = findBaseColor(for: currentColor)
            modifier.properties["color"] = baseColor.opacity(newOpacity)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    private func findBaseColor(for color: Color) -> Color {
        for (_, baseColor) in swiftUIColors {
            if color == baseColor { return baseColor }
        }
        return color
    }
}

// MARK: - Gradient Editor View
struct GradientEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var isColor1PickerPresented = false
    @State private var isColor2PickerPresented = false
    
    private let swiftUIColors: [(String, Color)] = [
        ("White", .white), ("Black", .black), ("Red", .red), ("Orange", .orange),
        ("Yellow", .yellow), ("Green", .green), ("Blue", .blue), ("Purple", .purple),
        ("Pink", .pink), ("Cyan", .cyan), ("Mint", .mint), ("Gray", .gray)
    ]
    
    private let unitPoints = ["top", "bottom", "leading", "trailing", "topLeading", "topTrailing", "bottomLeading", "bottomTrailing"]
    
    private var gradientDict: [String: Any] {
        modifier.properties["gradient"] as? [String: Any] ?? [
            "colors": ["color:blue", "color:purple"],
            "startPoint": "top",
            "endPoint": "bottom"
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color 1
            VStack(alignment: .leading, spacing: 4) {
                Text("Start Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                colorButton(index: 0, isPresented: $isColor1PickerPresented)
            }
            
            // Color 2
            VStack(alignment: .leading, spacing: 4) {
                Text("End Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                colorButton(index: 1, isPresented: $isColor2PickerPresented)
            }
            
            // Start Point
            VStack(alignment: .leading, spacing: 4) {
                Text("Start Point")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { gradientDict["startPoint"] as? String ?? "top" },
                    set: { updateGradientProperty(key: "startPoint", value: $0) }
                )) {
                    ForEach(unitPoints, id: \.self) { point in
                        Text(point).tag(point)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // End Point
            VStack(alignment: .leading, spacing: 4) {
                Text("End Point")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { gradientDict["endPoint"] as? String ?? "bottom" },
                    set: { updateGradientProperty(key: "endPoint", value: $0) }
                )) {
                    ForEach(unitPoints, id: \.self) { point in
                        Text(point).tag(point)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .onAppear {
            // Initialize gradient if it doesn't exist
            if modifier.properties["gradient"] == nil {
                updateGradientProperty(key: "colors", value: ["color:blue", "color:purple"])
            }
        }
    }
    
    private func colorButton(index: Int, isPresented: Binding<Bool>) -> some View {
        let colors = gradientDict["colors"] as? [Any] ?? ["color:blue", "color:purple"]
        let colorVal = colors.count > index ? colors[index] : "color:blue"
        let color = colorValueToColor(colorVal)
        
        return Button(action: { isPresented.wrappedValue = true }) {
            HStack {
                Circle().fill(color).frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                Text(colorLabel(for: colorVal))
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down").font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(Color.gray.opacity(0.1)).cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: isPresented) {
            colorGrid(index: index, isPresented: isPresented)
        }
    }
    
    private func colorGrid(index: Int, isPresented: Binding<Bool>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            ForEach(swiftUIColors, id: \.0) { name, color in
                Button(action: {
                    updateGradientColor(index: index, colorName: name.lowercased())
                    isPresented.wrappedValue = false
                }) {
                    Circle().fill(color).frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding().frame(width: 160)
    }
    
    private func updateGradientProperty(key: String, value: Any) {
        var dict = gradientDict
        dict[key] = value
        var updatedModifier = modifier
        updatedModifier.properties["gradient"] = dict
        modifier = updatedModifier
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    private func updateGradientColor(index: Int, colorName: String) {
        var dict = gradientDict
        var colors = dict["colors"] as? [Any] ?? ["color:blue", "color:purple"]
        if colors.count > index {
            colors[index] = "color:\(colorName)"
        } else {
            colors.append("color:\(colorName)")
        }
        dict["colors"] = colors
        var updatedModifier = modifier
        updatedModifier.properties["gradient"] = dict
        modifier = updatedModifier
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    private func colorValueToColor(_ val: Any) -> Color {
        if let str = val as? String {
            return ComponentProperty.colorStringToColor(str.hasPrefix("color:") ? String(str.dropFirst(6)) : str)
        }
        return val as? Color ?? .blue
    }
    
    private func colorLabel(for val: Any) -> String {
        if let str = val as? String, str.hasPrefix("color:") {
            return String(str.dropFirst(6)).capitalized
        }
        return "Custom"
    }
}
