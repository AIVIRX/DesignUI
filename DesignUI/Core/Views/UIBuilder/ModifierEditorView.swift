//
//  ModifierEditorView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

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
    @State private var widthValue: CGFloat = 0
    @State private var heightValue: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frame Size")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Width")
                        .font(.caption)
                    TextField("Width", value: $widthValue, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            widthValue = modifier.properties["width"] as? CGFloat ?? 0
                        }
                        .onChange(of: widthValue) { _, newValue in
                            modifier.properties["width"] = newValue
                        }
                        .onSubmit {
                            modifier.properties["width"] = widthValue
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Height")
                        .font(.caption)
                    TextField("Height", value: $heightValue, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            heightValue = modifier.properties["height"] as? CGFloat ?? 0
                        }
                        .onChange(of: heightValue) { _, newValue in
                            modifier.properties["height"] = newValue
                        }
                        .onSubmit {
                            modifier.properties["height"] = heightValue
                        }
                }
            }
        }
    }
}

// MARK: - Padding Modifier Editor
struct PaddingModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var topValue: CGFloat = 0
    @State private var leadingValue: CGFloat = 0
    @State private var bottomValue: CGFloat = 0
    @State private var trailingValue: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Padding")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Top")
                            .font(.caption)
                        TextField("Top", value: $topValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                topValue = modifier.properties["top"] as? CGFloat ?? 0
                            }
                            .onChange(of: topValue) { _, newValue in
                                modifier.properties["top"] = newValue
                            }
                            .onSubmit {
                                modifier.properties["top"] = topValue
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Leading")
                            .font(.caption)
                        TextField("Leading", value: $leadingValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                leadingValue = modifier.properties["leading"] as? CGFloat ?? 0
                            }
                            .onChange(of: leadingValue) { _, newValue in
                                modifier.properties["leading"] = newValue
                            }
                            .onSubmit {
                                modifier.properties["leading"] = leadingValue
                            }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bottom")
                            .font(.caption)
                        TextField("Bottom", value: $bottomValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                bottomValue = modifier.properties["bottom"] as? CGFloat ?? 0
                            }
                            .onChange(of: bottomValue) { _, newValue in
                                modifier.properties["bottom"] = newValue
                            }
                            .onSubmit {
                                modifier.properties["bottom"] = bottomValue
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Trailing")
                            .font(.caption)
                        TextField("Trailing", value: $trailingValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .onAppear {
                                trailingValue = modifier.properties["trailing"] as? CGFloat ?? 0
                            }
                            .onChange(of: trailingValue) { _, newValue in
                                modifier.properties["trailing"] = newValue
                            }
                            .onSubmit {
                                modifier.properties["trailing"] = trailingValue
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Background Modifier Editor
struct BackgroundModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { modifier.properties["color"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Color")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ColorPicker("Background Color", selection: color)
        }
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
            set: { modifier.properties["radius"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Corner Radius")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: radius, in: 0...50)
                Text("\(Int(radius.wrappedValue))")
                    .font(.caption)
                    .frame(width: 30)
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
            set: { modifier.properties["radius"] = $0 }
        )
    }
    
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
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.black },
            set: { modifier.properties["color"] = $0 }
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
            set: { modifier.properties["opacity"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opacity")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: opacity, in: 0...1)
                Text("\(Int(opacity.wrappedValue * 100))%")
                    .font(.caption)
                    .frame(width: 40)
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
            set: { modifier.properties["angle"] = $0 }
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
            set: { modifier.properties["opacity"] = $0 }
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
