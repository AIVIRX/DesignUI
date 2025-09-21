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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Modifier header
                    HStack {
                        Image(systemName: modifier.type.icon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(modifier.type.rawValue)
                                .font(.headline)
                            
                            Text(modifier.type.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
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
                        case .brightness:
                            BrightnessModifierEditor(modifier: $modifier)
                        case .contrast:
                            ContrastModifierEditor(modifier: $modifier)
                        case .saturation:
                            SaturationModifierEditor(modifier: $modifier)
                        case .hueRotation:
                            HueRotationModifierEditor(modifier: $modifier)
                        case .grayscale:
                            GrayscaleModifierEditor(modifier: $modifier)
                        case .sepia:
                            SepiaModifierEditor(modifier: $modifier)
                        case .clipShape:
                            ClipShapeModifierEditor(modifier: $modifier)
                        case .mask:
                            MaskModifierEditor(modifier: $modifier)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Edit Modifier")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        component.updateModifier(modifier)
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - Frame Modifier Editor
struct FrameModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var width: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["width"] as? CGFloat ?? 0 },
            set: { modifier.properties["width"] = $0 }
        )
    }
    
    private var height: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["height"] as? CGFloat ?? 0 },
            set: { modifier.properties["height"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frame Size")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Width")
                        .font(.caption)
                    TextField("Width", value: width, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading) {
                    Text("Height")
                        .font(.caption)
                    TextField("Height", value: height, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}

// MARK: - Padding Modifier Editor
struct PaddingModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var top: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["top"] as? CGFloat ?? 0 },
            set: { modifier.properties["top"] = $0 }
        )
    }
    
    private var leading: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["leading"] as? CGFloat ?? 0 },
            set: { modifier.properties["leading"] = $0 }
        )
    }
    
    private var bottom: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["bottom"] as? CGFloat ?? 0 },
            set: { modifier.properties["bottom"] = $0 }
        )
    }
    
    private var trailing: Binding<CGFloat> {
        Binding(
            get: { modifier.properties["trailing"] as? CGFloat ?? 0 },
            set: { modifier.properties["trailing"] = $0 }
        )
    }
    
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
                        TextField("Top", value: top, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Leading")
                            .font(.caption)
                        TextField("Leading", value: leading, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bottom")
                            .font(.caption)
                        TextField("Bottom", value: bottom, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Trailing")
                            .font(.caption)
                        TextField("Trailing", value: trailing, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
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
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { modifier.properties["color"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overlay Color")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ColorPicker("Overlay Color", selection: color)
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
            set: { modifier.properties["size"] = $0 }
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

// MARK: - Brightness Modifier Editor
struct BrightnessModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var amount: Binding<Double> {
        Binding(
            get: { modifier.properties["amount"] as? Double ?? 0 },
            set: { modifier.properties["amount"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brightness")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: amount, in: -1...1)
                Text("\(String(format: "%.1f", amount.wrappedValue))")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
    }
}

// MARK: - Contrast Modifier Editor
struct ContrastModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var amount: Binding<Double> {
        Binding(
            get: { modifier.properties["amount"] as? Double ?? 1 },
            set: { modifier.properties["amount"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contrast")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: amount, in: 0...3)
                Text("\(String(format: "%.1f", amount.wrappedValue))")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
    }
}

// MARK: - Saturation Modifier Editor
struct SaturationModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var amount: Binding<Double> {
        Binding(
            get: { modifier.properties["amount"] as? Double ?? 1 },
            set: { modifier.properties["amount"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saturation")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: amount, in: 0...3)
                Text("\(String(format: "%.1f", amount.wrappedValue))")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
    }
}

// MARK: - Hue Rotation Modifier Editor
struct HueRotationModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var angle: Binding<Double> {
        Binding(
            get: { modifier.properties["angle"] as? Double ?? 0 },
            set: { modifier.properties["angle"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hue Rotation")
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

// MARK: - Grayscale Modifier Editor
struct GrayscaleModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var amount: Binding<Double> {
        Binding(
            get: { modifier.properties["amount"] as? Double ?? 0 },
            set: { modifier.properties["amount"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grayscale")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: amount, in: 0...1)
                Text("\(Int(amount.wrappedValue * 100))%")
                    .font(.caption)
                    .frame(width: 40)
            }
        }
    }
}

// MARK: - Sepia Modifier Editor
struct SepiaModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private var amount: Binding<Double> {
        Binding(
            get: { modifier.properties["amount"] as? Double ?? 0 },
            set: { modifier.properties["amount"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sepia")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Slider(value: amount, in: 0...1)
                Text("\(Int(amount.wrappedValue * 100))%")
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

#Preview {
    let component = UIComponent(type: .text)
    let modifier = ComponentModifier(type: .font, properties: ["style": "body", "size": 16.0, "weight": "regular"])
    
    return ModifierEditorView(component: component, modifier: .constant(modifier))
}
