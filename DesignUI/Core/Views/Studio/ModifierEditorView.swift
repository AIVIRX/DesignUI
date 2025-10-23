//
//  ModifierEditorView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
struct ModifierEditorView: View {
    @ObservedObject var component: UIComponent
    @Binding var modifier: ComponentModifier
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modifier header
            HStack {
                Image(systemName: modifier.type.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(modifier.type.rawValue)
                        .font(.headline)
                    
                    Text(modifier.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Modifier-specific controls
            Group {
                switch modifier.type {
                case .frame:
                    FrameModifierEditor(modifier: $modifier)
                case .padding:
                    PaddingModifierEditor(modifier: $modifier)
                case .background:
                    BackgroundModifierEditor(modifier: $modifier)
                case .overlay:
                    OverlayModifierEditor(modifier: $modifier)
                case .foregroundColor:
                    ColorModifierEditor(modifier: $modifier, title: "Foreground Color")
                case .font:
                    FontModifierEditor(modifier: $modifier)
                case .cornerRadius:
                    CornerRadiusModifierEditor(modifier: $modifier)
                case .shadow:
                    ShadowModifierEditor(modifier: $modifier)
                case .opacity:
                    OpacityModifierEditor(modifier: $modifier)
                case .rotation:
                    RotationModifierEditor(modifier: $modifier)
                case .scale:
                    ScaleModifierEditor(modifier: $modifier)
                case .offset:
                    OffsetModifierEditor(modifier: $modifier)
                case .blur:
                    BlurModifierEditor(modifier: $modifier)
                case .clipShape:
                    ClipShapeModifierEditor(modifier: $modifier)
                case .mask:
                    MaskModifierEditor(modifier: $modifier)
                }
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(width: 320)
    }
}

// MARK: - Frame Modifier Editor
struct FrameModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var widthType: FrameSizeType = .full
    @State private var heightType: FrameSizeType = .full
    @State private var widthValue: CGFloat = 100
    @State private var heightValue: CGFloat = 100
    
    enum FrameSizeType: String, CaseIterable {
        case `default` = "Default"
        case full = "Full"
        case custom = "Custom"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Width Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Width")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack {
                    Picker("Width Type", selection: $widthType) {
                        ForEach(FrameSizeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if widthType == .custom {
                        TextField("Width", value: $widthValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                modifier.properties["width"] = widthValue
                                NotificationCenter.default.post(name: .designChanged, object: nil)
                            }
                    } else if widthType == .full {
                        Text("Full Width")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    } else {
                        Text("Default Width")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    }
                }
            }
            
            // Height Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("Height Type", selection: $heightType) {
                        ForEach(FrameSizeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if heightType == .custom {
                        TextField("Height", value: $heightValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                modifier.properties["height"] = heightValue
                                NotificationCenter.default.post(name: .designChanged, object: nil)
                            }
                    } else if heightType == .full {
                        Text("Full Height")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    } else {
                        Text("Default Height")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    }
                }
            }
        }
        .onAppear {
            // Load existing values
            widthType = (modifier.properties["widthType"] as? String).flatMap(FrameSizeType.init) ?? .default
            heightType = (modifier.properties["heightType"] as? String).flatMap(FrameSizeType.init) ?? .default
            widthValue = modifier.properties["width"] as? CGFloat ?? 100
            heightValue = modifier.properties["height"] as? CGFloat ?? 100
        }
        .onChange(of: widthType) { _, newValue in
            modifier.properties["widthType"] = newValue.rawValue
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        .onChange(of: heightType) { _, newValue in
            modifier.properties["heightType"] = newValue.rawValue
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Padding Modifier Editor
struct PaddingModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var paddingAmount: CGFloat = 10
    @State private var paddingLocation: String = "all"
    
    private let paddingLocations = [
        ("all", "All Sides"),
        ("leading", "Leading"),
        ("trailing", "Trailing"),
        ("top", "Top"),
        ("bottom", "Bottom"),
        ("horizontal", "Horizontal"),
        ("vertical", "Vertical")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 12) {
                // Padding Location
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Location", selection: $paddingLocation) {
                        ForEach(paddingLocations, id: \.0) { location in
                            Text(location.1).tag(location.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onAppear {
                        paddingLocation = modifier.properties["location"] as? String ?? "all"
                    }
                    .onChange(of: paddingLocation) { _, newValue in
                        print("📏 Padding location changed to: \(newValue)")
                        modifier.properties["location"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                }
                
                // Padding Amount
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("10", value: $paddingAmount, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            paddingAmount = modifier.properties["amount"] as? CGFloat ?? 10
                        }
                        .onChange(of: paddingAmount) { _, newValue in
                            print("📏 Padding amount changed to: \(newValue)")
                            modifier.properties["amount"] = newValue
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                        .onSubmit {
                            print("📏 Padding amount submitted: \(paddingAmount)")
                            modifier.properties["amount"] = paddingAmount
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                }
            }
        }
    }
}

// MARK: - Background Modifier Editor
struct BackgroundModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var isPresented = false
    @State private var opacity: Double = 1.0
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { newColor in
                print("🎨 Background color changed to: \(newColor)")
                modifier.properties["color"] = newColor
                // Trigger change detection
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Color")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Background Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { isPresented = true }) {
                    HStack(spacing: 6) {
                        // Color preview circle
                        Circle()
                            .fill(color.wrappedValue)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text(colorName(for: color.wrappedValue))
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
                                    self.color.wrappedValue = colorWithOpacity
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
                    if modifier.properties["color"] as? Color != nil {
                        opacity = 1.0
                    }
                }
                }
            }
        }
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let currentColor = modifier.properties["color"] as? Color else { return false }
        
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
        if let currentColor = modifier.properties["color"] as? Color {
            // Find the base color without opacity
            let baseColor = findBaseColor(for: currentColor)
            let colorWithOpacity = baseColor.opacity(newOpacity)
            print("🎨 Background color opacity changed to: \(newOpacity) for color: \(colorWithOpacity)")
            modifier.properties["color"] = colorWithOpacity
            NotificationCenter.default.post(name: .designChanged, object: nil)
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

// MARK: - Overlay Modifier Editor
struct OverlayModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var overlayType: String = "color"
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { modifier.properties["color"] = $0 }
        )
    }
    
    private var overlayText: Binding<String> {
        Binding(
            get: { modifier.properties["text"] as? String ?? "Overlay" },
            set: { modifier.properties["text"] = $0 }
        )
    }
    
    private var overlayPosition: Binding<String> {
        Binding(
            get: { modifier.properties["position"] as? String ?? "topTrailing" },
            set: { modifier.properties["position"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overlay")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Overlay type picker
            Picker("Type", selection: $overlayType) {
                Text("Color").tag("color")
                Text("Text Badge").tag("text")
                Text("Icon").tag("icon")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: overlayType) { _, newValue in
                modifier.properties["type"] = newValue
            }
            
            // Type-specific controls
            switch overlayType {
            case "color":
                ColorPopover(property: ComponentProperty(
                    key: "color",
                    displayName: "Color",
                    type: .color,
                    value: color.wrappedValue,
                    defaultValue: Color.clear
                ), component: UIComponent(type: .text))
                
            case "text":
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Overlay Text", text: overlayText)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Position")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: overlayPosition) {
                            Text("Top Leading").tag("topLeading")
                            Text("Top Trailing").tag("topTrailing")
                            Text("Bottom Leading").tag("bottomLeading")
                            Text("Bottom Trailing").tag("bottomTrailing")
                            Text("Center").tag("center")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
            case "icon":
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Icon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        TextField("system.icon.name", text: Binding(
                            get: { modifier.properties["iconName"] as? String ?? "star.fill" },
                            set: { modifier.properties["iconName"] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Position")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: overlayPosition) {
                            Text("Top Leading").tag("topLeading")
                            Text("Top Trailing").tag("topTrailing")
                            Text("Bottom Leading").tag("bottomLeading")
                            Text("Bottom Trailing").tag("bottomTrailing")
                            Text("Center").tag("center")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
            default:
                EmptyView()
            }
        }
        .onAppear {
            overlayType = modifier.properties["type"] as? String ?? "color"
        }
    }
}

// MARK: - Color Modifier Editor
struct ColorModifierEditor: View {
    @Binding var modifier: ComponentModifier
    let title: String
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.primary },
            set: { modifier.properties["color"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ColorPicker(title, selection: color)
        }
    }
}

// MARK: - Font Modifier Editor
struct FontModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private let fontStyles = [
        "largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"
    ]
    
    private var fontStyle: Binding<String> {
        Binding(
            get: { modifier.properties["style"] as? String ?? "body" },
            set: { modifier.properties["style"] = $0 }
        )
    }
    
    private var fontSize: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["size"] as? CGFloat ?? 16 },
            set: { newValue in
                DispatchQueue.main.async {
                    modifier.properties["size"] = newValue
                }
            }
        )
    }
    
    private var fontWeight: Binding<String> {
        Binding(
            get: { modifier.properties["weight"] as? String ?? "regular" },
            set: { modifier.properties["weight"] = $0 }
        )
    }
    
    private let fontWeights = ["regular", "bold", "light", "medium", "semibold", "heavy", "black"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Font")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Font Style
                VStack(alignment: .leading) {
                    Text("Style")
                        .font(.caption)
                    Picker("Font Style", selection: fontStyle) {
                        ForEach(fontStyles, id: \.self) { style in
                            Text(style.capitalized).tag(style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Font Size
                VStack(alignment: .leading) {
                    Text("Size")
                        .font(.caption)
                    HStack {
                        Slider(value: fontSize, in: 8...72)
                        Text("\(Int(fontSize.wrappedValue))")
                            .font(.caption)
                            .frame(width: 30)
                    }
                }
                
                // Font Weight
                VStack(alignment: .leading) {
                    Text("Weight")
                        .font(.caption)
                    Picker("Font Weight", selection: fontWeight) {
                        ForEach(fontWeights, id: \.self) { weight in
                            Text(weight.capitalized).tag(weight)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }
}

// MARK: - Corner Radius Modifier Editor
struct CornerRadiusModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var radius: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["radius"] as? CGFloat ?? 0 },
            set: { newValue in
                modifier.properties["radius"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Corner Radius")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                TextField("8", value: radius, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        // Trigger change detection
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                
                Text("px")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Shadow Modifier Editor
struct ShadowModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var radius: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["radius"] as? CGFloat ?? 0 },
            set: { newValue in
                modifier.properties["radius"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    private var x: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["x"] as? CGFloat ?? 0 },
            set: { newValue in
                modifier.properties["x"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    private var y: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["y"] as? CGFloat ?? 0 },
            set: { newValue in
                modifier.properties["y"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.black },
            set: { newValue in
                modifier.properties["color"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shadow")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Radius")
                        .font(.caption)
                    Slider(value: radius, in: 0...20)
                    Text("\(Int(radius.wrappedValue))")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                HStack {
                    Text("X Offset")
                        .font(.caption)
                    Slider(value: x, in: -20...20)
                    Text("\(Int(x.wrappedValue))")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                HStack {
                    Text("Y Offset")
                        .font(.caption)
                    Slider(value: y, in: -20...20)
                    Text("\(Int(y.wrappedValue))")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                ColorPicker("Shadow Color", selection: color)
            }
        }
    }
}

// MARK: - Opacity Modifier Editor
struct OpacityModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var opacity: Binding<Double> {
        Binding(
            get: { modifier.properties["opacity"] as? Double ?? 1.0 },
            set: { newValue in
                modifier.properties["opacity"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opacity")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                TextField("100", value: opacity, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        // Trigger change detection
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Rotation Modifier Editor
struct RotationModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var angle: Binding<Double> {
        Binding(
            get: { modifier.properties["angle"] as? Double ?? 0 },
            set: { newValue in
                modifier.properties["angle"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rotation")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: angle, in: -360...360)
                Text("\(Int(angle.wrappedValue))°")
                    .font(.caption)
                    .frame(width: 50)
            }
        }
    }
}

// MARK: - Scale Modifier Editor
struct ScaleModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var x: Binding<Double> {
        Binding(
            get: { modifier.properties["x"] as? Double ?? 1.0 },
            set: { modifier.properties["x"] = $0 }
        )
    }
    
    private var y: Binding<Double> {
        Binding(
            get: { modifier.properties["y"] as? Double ?? 1.0 },
            set: { modifier.properties["y"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scale")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("X Scale")
                        .font(.caption)
                    Slider(value: x, in: 0...3)
                    Text("\(String(format: "%.1f", x.wrappedValue))")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Y Scale")
                        .font(.caption)
                    Slider(value: y, in: 0...3)
                    Text("\(String(format: "%.1f", y.wrappedValue))")
                        .font(.caption)
                        .frame(width: 40)
                }
            }
        }
    }
}

// MARK: - Offset Modifier Editor
struct OffsetModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var x: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["x"] as? CGFloat ?? 0 },
            set: { modifier.properties["x"] = $0 }
        )
    }
    
    private var y: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["y"] as? CGFloat ?? 0 },
            set: { modifier.properties["y"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offset")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("X Offset")
                        .font(.caption)
                    Slider(value: x, in: -200...200)
                    Text("\(Int(x.wrappedValue))")
                        .font(.caption)
                        .frame(width: 50)
                }
                
                HStack {
                    Text("Y Offset")
                        .font(.caption)
                    Slider(value: y, in: -200...200)
                    Text("\(Int(y.wrappedValue))")
                        .font(.caption)
                        .frame(width: 50)
                }
            }
        }
    }
}

// MARK: - Blur Modifier Editor
struct BlurModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var radius: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["radius"] as? CGFloat ?? 0 },
            set: { modifier.properties["radius"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blur")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: radius, in: 0...20)
                Text("\(String(format: "%.1f", radius.wrappedValue))")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
    }
}


// MARK: - Clip Shape Modifier Editor
struct ClipShapeModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private let shapes = ["Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse"]
    
    private var shape: Binding<String> {
        Binding(
            get: { modifier.properties["shape"] as? String ?? "Rectangle" },
            set: { modifier.properties["shape"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clip Shape")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Picker("Shape", selection: shape) {
                ForEach(shapes, id: \.self) { shapeName in
                    Text(shapeName).tag(shapeName)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

// MARK: - Mask Modifier Editor
struct MaskModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var opacity: Binding<Double> {
        Binding(
            get: { modifier.properties["opacity"] as? Double ?? 1.0 },
            set: { newValue in
                modifier.properties["opacity"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mask")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Opacity")
                    .font(.caption)
                Slider(value: opacity, in: 0...1)
                Text("\(Int(opacity.wrappedValue * 100))%")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
    }
}
#endif
