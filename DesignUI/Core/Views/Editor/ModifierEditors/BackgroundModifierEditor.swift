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

// MARK: - Background Color Modifier Editor (for colors and gradients)
struct BackgroundColorModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var isPresented = false
    @State private var opacityText: String = ""
    
    private var currentColor: Color {
        modifier.getColor(key: "color", defaultValue: .blue)
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
        colorSection
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
                    
                Text(selectedColorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
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
                                
                                var updatedModifier = modifier
                                if opacity >= 0.99 && colorName != "Custom" && colorName != "Primary" {
                                    updatedModifier.properties["color"] = "color:\(colorName.lowercased())"
                                } else {
                                    updatedModifier.properties["color"] = color.opacity(opacity)
                                }
                                // Disable gradient when picking color
                                updatedModifier.properties["gradient"] = nil
                                
                                // Explicitly update component to trigger UI refresh
                                component.updateModifier(updatedModifier)
                                modifier = updatedModifier
                                
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
    
    private var selectedColorName: String {
        if let colorString = modifier.properties["color"] as? String {
            if colorString.hasPrefix("color:") {
                return String(colorString.dropFirst(6)).capitalized
            }
            return colorString.capitalized
        }
        return swiftUIColors.first { $0.1 == currentColor }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        // 1. Try to match by name if stored as string (Most reliable for named colors)
        if let targetName = swiftUIColors.first(where: { $0.1 == color })?.0,
           let storedString = modifier.properties["color"] as? String {
            let normalizedStored = storedString.replacingOccurrences(of: "color:", with: "")
            if normalizedStored.lowercased() == targetName.lowercased() {
                return true
            }
        }
        
        // 2. Fallback to Color equality (For custom colors or when string match fails)
        return currentColor == color
    }
    
    // Helper needed for grid? No, grid uses logic inside body or calls this.
    // We removed colorName(for: Color) usage in favor of selectedColorName for the label.
    // Wait, the grid loop might use colorName(for:) if we didn't check.
    // The grid loop uses `name` from swiftUIColors.
    
    private func updateColorWithOpacity(_ newOpacity: Double) {
        // Use currentColor instead of casting directly
        let baseColor = findBaseColor(for: currentColor)
        var updatedModifier = modifier
        updatedModifier.properties["color"] = baseColor.opacity(newOpacity)
        
        // Explicitly update component
        component.updateModifier(updatedModifier)
        modifier = updatedModifier
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    private func findBaseColor(for color: Color) -> Color {
        for (_, baseColor) in swiftUIColors {
            if color == baseColor { return baseColor }
        }
        return color
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
                modifier: modifier,
                component: component,
                onAdd: { newComponent in
                    component.addModifierChild(newComponent, modifierId: modifier.id)
                    showComponentLibrary = false
                }
            )
        }
    }
}


