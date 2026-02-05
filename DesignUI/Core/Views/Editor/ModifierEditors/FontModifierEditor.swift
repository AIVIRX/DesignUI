//
//  FontModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Font Modifier Editor
struct FontModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var fontSize: String = "body"
    @State private var customFontSize: String = ""
    @State private var fontWeight: String = "regular"
    @State private var fontDesign: String = "default"
    @State private var weightSliderValue: Double = 3
    @State private var designSliderValue: Double = 0
    @FocusState private var isCustomSizeFocused: Bool
    
    private let fontSizes: [(name: String, displayName: String)] = [
        ("largeTitle", "Large Title"),
        ("title", "Title 1"),
        ("title2", "Title 2"),
        ("title3", "Title 3"),
        ("headline", "Headline"),
        ("body", "Body"),
        ("callout", "Callout"),
        ("subheadline", "Subheadline"),
        ("footnote", "Footnote"),
        ("caption", "Caption 1"),
        ("caption2", "Caption 2")
    ]

    private let fontWeights: [(name: String, displayName: String)] = [
        ("ultraLight", "Ultra Light"),
        ("thin", "Thin"),
        ("light", "Light"),
        ("regular", "Regular"),
        ("medium", "Medium"),
        ("semibold", "Semibold"),
        ("bold", "Bold"),
        ("heavy", "Heavy"),
        ("black", "Black")
    ]

    private let orderedWeights: [String] = [
        "ultraLight", "thin", "light", "regular", "medium",
        "semibold", "bold", "heavy", "black"
    ]
    
    private let fontDesigns: [String] = ["default", "serif", "rounded", "monospaced"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Design Slider
                fontDesignSlider

                // Weight Slider
                weightSlider
                
                // Size List (Presets + Custom)
                sizeList
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            loadFont()
        }
        .onChange(of: modifier) { _, _ in
            loadFont()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
            isCustomSizeFocused = false
            loadFont()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
            isCustomSizeFocused = false
            loadFont()
        }
    }
    
    // MARK: - Subviews
    
     private var fontDesignSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Design")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(designDisplayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: "textformat.alt")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 24, height: 24)
                    
                    // Slider (0-3)
                    UndoableSlider(
                        value: $designSliderValue,
                        range: 0...Double(fontDesigns.count - 1),
                        step: 1,
                        onValueChanged: { newValue in
                            updateDesignFromSlider(value: newValue)
                        },
                        onEditingEnded: { _ in
                            saveFont()
                        }
                    )
                    
                    // Spacer to match alignment
                    Color.clear
                        .frame(width: 20, height: 1)
                }
                .padding(.horizontal, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var sizeList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Size")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                // Custom Size Row
                HStack {
                    Text("Custom")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    TextField("Size", text: $customFontSize)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .focused($isCustomSizeFocused)
                        #if os(macOS)
                        .onSubmit {
                            validateAndSaveFontSize()
                        }
                        .onChange(of: customFontSize) { _, newValue in 
                             // Filter out non-numeric characters (allow one decimal point)
                             let filtered = newValue.filter { "0123456789.".contains($0) }
                             if filtered != newValue {
                                 customFontSize = filtered
                                 return
                             }
                             
                             // Instant update logic if valid
                             if let val = Double(filtered), val >= 1 {
                                 if fontSize != filtered {
                                     fontSize = filtered
                                     saveFontContinuous()
                                 }
                             }
                        }
                        .onChange(of: isCustomSizeFocused) { _, isFocused in
                            if !isFocused {
                                validateAndSaveFontSize()
                            }
                        }
                        #endif
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider().padding(.leading, 16)
                
                ForEach(fontSizes, id: \.name) { sizeInfo in
                    FontOptionRow(
                        name: sizeInfo.name,
                        displayName: sizeInfo.displayName,
                        isSelected: fontSize == sizeInfo.name, // Will be false if fontSize is a number string
                        font: getPreviewFont(for: sizeInfo.name), // Show preview with current design
                        weight: getWeight(for: fontWeight),
                        onSelect: {
                            fontSize = sizeInfo.name
                            customFontSize = "" // Clear custom input
                            saveFont()
                        }
                    )
                    
                    if sizeInfo.name != fontSizes.last?.name {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var weightSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(getDisplayName(for: fontWeight))
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: "bold")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 24, height: 24)
                    
                    // Slider (0-8)
                    UndoableSlider(
                        value: $weightSliderValue,
                        range: 0...8,
                        step: 1,
                        onValueChanged: { newValue in
                            updateWeightFromSlider(value: newValue)
                        },
                        onEditingEnded: { _ in
                            saveFont()
                        }
                    )
                    
                    // Value label (Hidden or descriptive?)
                    Text("\(Int(weightSliderValue))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .frame(width: 20, alignment: .trailing)
                        .opacity(0.5)
                }
                .padding(.horizontal, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    
    private var previewFont: Font {
        getFont(for: fontSize)
    }
    
    private var previewWeight: Font.Weight {
        getWeight(for: fontWeight)
    }
    
    private func getDisplayName(for weight: String) -> String {
        fontWeights.first(where: { $0.name == weight })?.displayName ?? "Regular"
    }
    
    // Helper to allow semantic font previews with design
    private func getPreviewFont(for name: String) -> Font {
        let design = getDesign(for: fontDesign)
        let weight = getWeight(for: fontWeight)
        
        // Replicate semantic sizes logic briefly or use system style if available with design
        // Since we want the PREVIEW to look like the family, we can use .system(style, design)
        // Note: .system(_ style: Font.TextStyle, design: Font.Design, weight: Font.Weight) is valid
        
        switch name {
        case "largeTitle": return .system(.largeTitle, design: design, weight: weight)
        case "title": return .system(.title, design: design, weight: weight)
        case "title2": return .system(.title2, design: design, weight: weight)
        case "title3": return .system(.title3, design: design, weight: weight)
        case "headline": return .system(.headline, design: design, weight: weight)
        case "body": return .system(.body, design: design, weight: weight)
        case "callout": return .system(.callout, design: design, weight: weight)
        case "subheadline": return .system(.subheadline, design: design, weight: weight)
        case "footnote": return .system(.footnote, design: design, weight: weight)
        case "caption": return .system(.caption, design: design, weight: weight)
        case "caption2": return .system(.caption2, design: design, weight: weight)
        default: return .system(.body, design: design, weight: weight)
        }
    }
    
    private var designDisplayName: String {
        switch fontDesign {
        case "default": return "Default"
        case "serif": return "Serif"
        case "rounded": return "Rounded"
        case "monospaced": return "Monospaced"
        default: return "Default"
        }
    }
    
    private func getFont(for name: String) -> Font {
       // This was used for legacy preview, we now use getPreviewFont for rows
       // Keeping for safety if used elsewhere, but redirecting to standard logic
       return getPreviewFont(for: name)
    }

    private func getWeight(for name: String) -> Font.Weight {
        switch name {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    
    private func getDesign(for name: String) -> Font.Design {
        switch name {
        case "serif": return .serif
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        default: return .default
        }
    }
    
    private func loadFont() {
        let storedSize = modifier.properties["fontSize"] as? String ?? "body"
        fontSize = storedSize
        
        // If stored size is a number, populate custom field
        if Double(storedSize) != nil {
            customFontSize = storedSize
        } else {
            customFontSize = ""
        }
        
        fontWeight = modifier.properties["fontWeight"] as? String ?? "regular"
        fontDesign = modifier.properties["fontDesign"] as? String ?? "default"
        
        updateSliderFromWeight()
        updateSliderFromDesign()
    }
    
    private func updateSliderFromWeight() {
        if let index = orderedWeights.firstIndex(of: fontWeight) {
            weightSliderValue = Double(index)
        } else {
            weightSliderValue = 3 // Default regular
        }
    }
    
    private func updateWeightFromSlider(value: Double) {
        let index = Int(round(value))
        if index >= 0 && index < orderedWeights.count {
            fontWeight = orderedWeights[index]
            saveFontContinuous()
        }
    }
    
    private func updateSliderFromDesign() {
        if let index = fontDesigns.firstIndex(of: fontDesign) {
            designSliderValue = Double(index)
        } else {
            designSliderValue = 0 // Default
        }
    }
    
    private func updateDesignFromSlider(value: Double) {
        let index = Int(round(value))
        if index >= 0 && index < fontDesigns.count {
            fontDesign = fontDesigns[index]
            saveFontContinuous()
        }
    }
    
    private func saveFont() {
        var updatedModifier = modifier
        
        // If custom field has number and matches fontSize, use it. 
        // Logic handled by onSelect/onSubmit updating 'fontSize'
        updatedModifier.properties["fontSize"] = fontSize
        updatedModifier.properties["fontWeight"] = fontWeight
        updatedModifier.properties["fontDesign"] = fontDesign
        modifier = updatedModifier
    }
    
    private func saveFontContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["fontSize"] = fontSize
        updatedModifier.properties["fontWeight"] = fontWeight
        updatedModifier.properties["fontDesign"] = fontDesign
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
    
    private func validateAndSaveFontSize() {
        if !customFontSize.isEmpty, let val = Double(customFontSize), val >= 1 {
            fontSize = customFontSize
            saveFont()
        } else {
            // Invalid or empty?
            // Only revert to "body" if the CURRENT settings are custom (numeric)
            // If the user currently has a preset selected (e.g. "largeTitle"),
            // leaving the custom field empty is valid/expected behavior.
            if Double(fontSize) != nil {
                fontSize = "body"
                customFontSize = ""
                saveFont()
            } else {
                // We are on a preset, just clean up the input field visual state
                if !customFontSize.isEmpty {
                    customFontSize = ""
                }
            }
        }
    }
}

// MARK: - Font Option Row
struct FontOptionRow: View {
    let name: String
    let displayName: String
    let isSelected: Bool
    var font: Font = .body
    var weight: Font.Weight = .regular
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(displayName)
                    .font(font)
                    .fontWeight(weight)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
