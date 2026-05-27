//
//  ColorModifierEditor.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct ColorModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    let title: String
    
    @State private var selectedColorName: String = "primary"
    @State private var opacityValue: Double = 1.0
    @State private var isGradientMode: Bool = false
    @State private var activeGradientStop: GradientStop = .start
    @State private var gradientStartColorName: String = "primary"
    @State private var gradientStartOpacity: Double = 1.0
    @State private var gradientEndColorName: String = "purple"
    @State private var gradientEndOpacity: Double = 1.0
    @State private var gradientStartPoint: String = "top"
    @State private var gradientEndPoint: String = "bottom"

    private enum GradientStop {
        case start
        case end
    }
    
    private var encodedColor: String {
        String(format: "%@:%.2f", selectedColorName, opacityValue)
    }

    private var modePreviewColor: Color {
        ComponentProperty.colorStringToColor(selectedColorName).opacity(opacityValue)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                modeBar
                if isGradientMode {
                    gradientPickerContent
                } else {
                    pickerContent
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear {
            loadColor()
        }
        .onChange(of: modifier) { _, _ in
            loadColor()
        }
    }

    private func modeButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : .secondary)
                .frame(height: 30)
                .frame(minWidth: 72)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(selected ? Color.blue.opacity(0.9) : Color.secondary.opacity(0.14))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var modeBar: some View {
        HStack(spacing: 6) {
            modeButton(title: "Solid", selected: !isGradientMode) {
                isGradientMode = false
                saveColor()
            }
            modeButton(title: "Gradient", selected: isGradientMode) {
                activateGradientMode()
            }
            Spacer(minLength: 0)
            ZStack {
                CheckerboardBackground()
                    .clipShape(Circle())
                Circle()
                    .fill(modePreviewColor)
            }
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
    }

    private var pickerContent: some View {
        UniversalColorPickerView(
            selectedColorName: $selectedColorName,
            opacityValue: $opacityValue,
            title: title,
            onColorChanged: { saveColorContinuous() },
            onColorConfirmed: { saveColor() },
            supportsGradientMode: false
        )
    }

    private var gradientPickerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                stopButton(label: "A", stop: .start)
                stopButton(label: "B", stop: .end)
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                gradientPointMenu(
                    point: gradientStartPoint,
                    label: "Start"
                ) { newPoint in
                    gradientStartPoint = newPoint
                    saveGradient()
                }
                gradientPointMenu(
                    point: gradientEndPoint,
                    label: "End"
                ) { newPoint in
                    gradientEndPoint = newPoint
                    saveGradient()
                }
            }

            UniversalColorPickerView(
                selectedColorName: activeGradientColorBinding,
                opacityValue: activeGradientOpacityBinding,
                title: activeGradientStop == .start ? "Stop A" : "Stop B",
                onColorChanged: { saveGradientContinuous() },
                onColorConfirmed: { saveGradient() },
                supportsGradientMode: false
            )
        }
    }

    private func stopButton(label: String, stop: GradientStop) -> some View {
        let token = stop == .start ? gradientStartColorName : gradientEndColorName
        let selected = activeGradientStop == stop
        return Button {
            activeGradientStop = stop
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(ComponentProperty.colorStringToColor(token))
                    .frame(width: 12, height: 12)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(selected ? .white : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(selected ? Color.blue.opacity(0.9) : Color.secondary.opacity(0.14))
            )
        }
        .buttonStyle(.plain)
    }

    private var activeGradientColorBinding: Binding<String> {
        Binding(
            get: { activeGradientStop == .start ? gradientStartColorName : gradientEndColorName },
            set: { newValue in
                if activeGradientStop == .start {
                    gradientStartColorName = newValue
                } else {
                    gradientEndColorName = newValue
                }
            }
        )
    }

    private var activeGradientOpacityBinding: Binding<Double> {
        Binding(
            get: { activeGradientStop == .start ? gradientStartOpacity : gradientEndOpacity },
            set: { newValue in
                if activeGradientStop == .start {
                    gradientStartOpacity = newValue
                } else {
                    gradientEndOpacity = newValue
                }
            }
        )
    }

    private var gradientPointOptions: [String] {
        ["top", "bottom", "leading", "trailing", "center", "topleading", "toptrailing", "bottomleading", "bottomtrailing"]
    }

    private func gradientPointMenu(
        point: String,
        label: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(gradientPointOptions, id: \.self) { option in
                Button(readablePointLabel(option)) {
                    onSelect(option)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(readablePointLabel(point))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    private func readablePointLabel(_ value: String) -> String {
        switch value.lowercased() {
        case "top": return "Top"
        case "bottom": return "Bottom"
        case "leading": return "Left"
        case "trailing": return "Right"
        case "center": return "Center"
        case "topleading": return "Top Left"
        case "toptrailing": return "Top Right"
        case "bottomleading": return "Bottom Left"
        case "bottomtrailing": return "Bottom Right"
        default: return "Top"
        }
    }
    
    private func loadColor() {
        if let gradient = modifier.properties["gradient"] as? [String: Any],
           let colors = gradient["colors"] as? [Any],
           colors.count >= 2,
           let start = colors[0] as? String,
           let end = colors[1] as? String {
            isGradientMode = true
            let startParts = parseColorToken(start)
            let endParts = parseColorToken(end)
            gradientStartColorName = startParts.name
            gradientStartOpacity = startParts.opacity
            gradientEndColorName = endParts.name
            gradientEndOpacity = endParts.opacity
            gradientStartPoint = (gradient["startPoint"] as? String) ?? "top"
            gradientEndPoint = (gradient["endPoint"] as? String) ?? "bottom"
            if activeGradientStop == .start {
                selectedColorName = gradientStartColorName
                opacityValue = gradientStartOpacity
            } else {
                selectedColorName = gradientEndColorName
                opacityValue = gradientEndOpacity
            }
        } else {
            isGradientMode = false
            if let colorData = modifier.properties["color"] as? String {
                let parts = parseColorToken(colorData)
                selectedColorName = parts.name
                opacityValue = parts.opacity
            } else {
                selectedColorName = "primary"
                opacityValue = 1.0
            }
        }
    }
    
    private func saveColor() {
        var updatedModifier = modifier
        updatedModifier.properties.removeValue(forKey: "gradient")
        updatedModifier.properties["color"] = encodedColor
        modifier = updatedModifier
    }
    
    private func saveColorContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties.removeValue(forKey: "gradient")
        updatedModifier.properties["color"] = encodedColor
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }

    private func activateGradientMode() {
        isGradientMode = true
        if modifier.properties["gradient"] == nil {
            gradientStartColorName = selectedColorName
            gradientStartOpacity = opacityValue
            gradientEndColorName = "purple"
            gradientEndOpacity = 1.0
            gradientStartPoint = "top"
            gradientEndPoint = "bottom"
            activeGradientStop = .start
            saveGradient()
        }
    }

    private func saveGradient() {
        var updatedModifier = modifier
        updatedModifier.properties["color"] = String(format: "%@:%.2f", gradientStartColorName, gradientStartOpacity)
        updatedModifier.properties["gradient"] = [
            "colors": [
                String(format: "%@:%.2f", gradientStartColorName, gradientStartOpacity),
                String(format: "%@:%.2f", gradientEndColorName, gradientEndOpacity)
            ],
            "startPoint": gradientStartPoint,
            "endPoint": gradientEndPoint
        ]
        modifier = updatedModifier
    }

    private func saveGradientContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["color"] = String(format: "%@:%.2f", gradientStartColorName, gradientStartOpacity)
        updatedModifier.properties["gradient"] = [
            "colors": [
                String(format: "%@:%.2f", gradientStartColorName, gradientStartOpacity),
                String(format: "%@:%.2f", gradientEndColorName, gradientEndOpacity)
            ],
            "startPoint": gradientStartPoint,
            "endPoint": gradientEndPoint
        ]
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }

    private func parseColorToken(_ value: String) -> (name: String, opacity: Double) {
        let parts = value.split(separator: ":")
        let name = parts.first.map(String.init)?.lowercased() ?? "primary"
        let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
        return (name, max(0, min(1, opacity)))
    }
}

struct UniversalColorPickerView: View {
    @Binding var selectedColorName: String
    @Binding var opacityValue: Double
    let title: String
    var onColorChanged: (() -> Void)?
    var onColorConfirmed: (() -> Void)?
    var supportsGradientMode: Bool = true

    private enum PickerMode: String, CaseIterable {
        case solid
        case gradient
    }

    @State private var pickerMode: PickerMode = .solid
    @State private var hue: Double = 0
    @State private var saturation: Double = 0
    @State private var brightness: Double = 1
    @State private var redInput: String = "255"
    @State private var greenInput: String = "255"
    @State private var blueInput: String = "255"
    @State private var alphaInput: String = "100"
    @State private var hexInput: String = "#FFFFFF"
    @State private var isApplyingInternalUpdate = false
    @FocusState private var focusedField: FieldFocus?

    private enum FieldFocus: Hashable {
        case red, green, blue, alpha, hex
    }

    static let swiftUIColors: [(name: String, displayName: String, color: Color)] = [
        ("primary", "Primary", .primary),
        ("secondary", "Secondary", .secondary),
        ("black", "Black", .black),
        ("white", "White", .white),
        ("red", "Red", .red),
        ("orange", "Orange", .orange),
        ("yellow", "Yellow", .yellow),
        ("green", "Green", .green),
        ("mint", "Mint", .mint),
        ("teal", "Teal", .teal),
        ("cyan", "Cyan", .cyan),
        ("blue", "Blue", .blue),
        ("indigo", "Indigo", .indigo),
        ("purple", "Purple", .purple),
        ("pink", "Pink", .pink),
        ("brown", "Brown", .brown),
        ("gray", "Gray", .gray),
        ("clear", "Clear", .clear)
    ]

    private var customBaseColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private var previewColor: Color {
        customBaseColor.opacity(opacityValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            topModeBar

            if supportsGradientMode && pickerMode == .gradient {
                gradientPlaceholder
            } else {
                customColorTab
            }
        }
        .onAppear {
            if !supportsGradientMode {
                pickerMode = .solid
            }
            loadFromSelection()
        }
        .onChange(of: selectedColorName) { _, _ in
            guard !isApplyingInternalUpdate else { return }
            loadFromSelection()
        }
        .onChange(of: opacityValue) { _, _ in
            guard !isApplyingInternalUpdate else { return }
            alphaInput = "\(Int((opacityValue * 100).rounded()))"
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
            focusedField = nil
            loadFromSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
            focusedField = nil
            loadFromSelection()
        }
    }
    
    private var topModeBar: some View {
        HStack {
            if supportsGradientMode {
                HStack(spacing: 4) {
                    modePillButton(title: "Solid", mode: .solid)
                    modePillButton(title: "Gradient", mode: .gradient)
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.14)))
            }
        }
    }

    private func modePillButton(title: String, mode: PickerMode) -> some View {
        Button {
            pickerMode = mode
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(pickerMode == mode ? .white : .secondary)
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(pickerMode == mode ? Color.blue.opacity(0.9) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var gradientPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gradient Editor")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Next step: stops, angle, and type controls.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
    }

    private var customColorTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            satBrightnessField
            hueSlider
            alphaSlider
            hexAndAlphaRow
        }
    }

    private var satBrightnessField: some View {
        SatBrightnessFieldView(
            hue: hue,
            saturation: $saturation,
            brightness: $brightness,
            onColorChange: { confirmed in
                publishCustomColor(confirmed: confirmed)
            }
        )
        .frame(height: 156)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var hueSlider: some View {
        customSlider(
            value: hue,
            palette: AnyView(
                LinearGradient(
                    colors: [
                        .red, .yellow, .green, .cyan, .blue, .purple, .red
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ),
            onChange: { newValue, confirmed in
                hue = newValue
                publishCustomColor(confirmed: confirmed)
            }
        )
    }

    private var alphaSlider: some View {
        customSlider(
            value: opacityValue,
            palette: AnyView(
                ZStack {
                    CheckerboardBackground()
                    LinearGradient(
                        colors: [customBaseColor.opacity(0), customBaseColor.opacity(1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            ),
            onChange: { newValue, confirmed in
                opacityValue = max(0, min(1, newValue))
                alphaInput = "\(Int((opacityValue * 100).rounded()))"
                publishCustomColor(confirmed: confirmed)
            }
        )
    }

    private func customSlider(value: Double, palette: AnyView, onChange: @escaping (Double, Bool) -> Void) -> some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let x = max(0, min(width, value * width))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.secondary.opacity(0.18))
                palette
                    .clipShape(RoundedRectangle(cornerRadius: 999))
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 0)
                    .position(x: max(10, min(width - 10, x)), y: 10)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { drag in
                        let p = max(0, min(1, drag.location.x / width))
                        onChange(p, false)
                    }
                    .onEnded { drag in
                        let p = max(0, min(1, drag.location.x / width))
                        onChange(p, true)
                    }
            )
        }
        .frame(height: 18)
    }

    private var hexAndAlphaRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                channelField(label: "R", text: $redInput, focus: .red)
                channelField(label: "G", text: $greenInput, focus: .green)
                channelField(label: "B", text: $blueInput, focus: .blue)
            }
            channelField(label: "#", text: $hexInput, focus: .hex, isHex: true)
            channelField(label: "A", text: $alphaInput, focus: .alpha, suffix: "%")
        }
    }

    private func channelField(
        label: String,
        text: Binding<String>,
        focus: FieldFocus,
        isHex: Bool = false,
        suffix: String? = nil
    ) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: isHex ? .monospaced : .default))
                .foregroundColor(.primary)
                .focused($focusedField, equals: focus)
                .onChange(of: text.wrappedValue) { _, newValue in
                    handleChannelInputChange(focus: focus, value: newValue)
                }
                .onSubmit {
                    applyChannelInput(focus: focus, value: text.wrappedValue, confirmed: true)
                }

            if let suffix {
                Text(suffix)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.14)))
    }

    private func loadFromSelection() {
        let resolved = ComponentProperty.colorStringToColor(selectedColorName)
        let rgba = rgbaComponents(from: resolved)
        let hsv = rgbToHSV(r: rgba.r, g: rgba.g, b: rgba.b)

        hue = hsv.h
        saturation = hsv.s
        brightness = hsv.v
        redInput = "\(Int((rgba.r * 255).rounded()))"
        greenInput = "\(Int((rgba.g * 255).rounded()))"
        blueInput = "\(Int((rgba.b * 255).rounded()))"
        alphaInput = "\(Int((opacityValue * 100).rounded()))"
        hexInput = rgbToHex(r: rgba.r, g: rgba.g, b: rgba.b)
    }

    private func publishCustomColor(confirmed: Bool) {
        let rgb = hsvToRGB(h: hue, s: saturation, v: brightness)
        redInput = "\(Int((rgb.r * 255).rounded()))"
        greenInput = "\(Int((rgb.g * 255).rounded()))"
        blueInput = "\(Int((rgb.b * 255).rounded()))"
        hexInput = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)

        isApplyingInternalUpdate = true
        selectedColorName = hexInput
        isApplyingInternalUpdate = false

        onColorChanged?()
        if confirmed {
            onColorConfirmed?()
        }
    }

    private func handleChannelInputChange(focus: FieldFocus, value: String) {
        applyChannelInput(focus: focus, value: value, confirmed: false)
    }

    private func applyChannelInput(focus: FieldFocus, value: String, confirmed: Bool) {
        switch focus {
        case .red:
            redInput = clampChannel(value)
        case .green:
            greenInput = clampChannel(value)
        case .blue:
            blueInput = clampChannel(value)
        case .alpha:
            alphaInput = clampPercent(value)
            if let alpha = Double(alphaInput) {
                opacityValue = max(0, min(1, alpha / 100.0))
            }
        case .hex:
            hexInput = sanitizeHex(value)
            applyHexIfValid(confirmed: confirmed)
            return
        }

        if let r = Double(redInput), let g = Double(greenInput), let b = Double(blueInput) {
            let rr = max(0, min(1, r / 255.0))
            let gg = max(0, min(1, g / 255.0))
            let bb = max(0, min(1, b / 255.0))
            let hsv = rgbToHSV(r: rr, g: gg, b: bb)
            hue = hsv.h
            saturation = hsv.s
            brightness = hsv.v
            publishCustomColor(confirmed: confirmed)
        }
    }

    private func applyHexIfValid(confirmed: Bool) {
        let hex = sanitizeHex(hexInput)
        guard let rgb = hexToRGB(hex) else { return }
        let hsv = rgbToHSV(r: rgb.r, g: rgb.g, b: rgb.b)
        hue = hsv.h
        saturation = hsv.s
        brightness = hsv.v
        publishCustomColor(confirmed: confirmed)
    }

    private func clampChannel(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard let value = Int(digits) else { return "0" }
        return "\(max(0, min(255, value)))"
    }

    private func clampPercent(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard let value = Int(digits) else { return "0" }
        return "\(max(0, min(100, value)))"
    }

    private func sanitizeHex(_ raw: String) -> String {
        var value = raw.uppercased().filter { "0123456789ABCDEF#".contains($0) }
        if !value.hasPrefix("#") { value = "#" + value }
        if value.count > 7 { value = String(value.prefix(7)) }
        return value
    }

    private func rgbToHex(r: Double, g: Double, b: Double) -> String {
        let ri = Int(max(0, min(255, (r * 255).rounded())))
        let gi = Int(max(0, min(255, (g * 255).rounded())))
        let bi = Int(max(0, min(255, (b * 255).rounded())))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    private func hexToRGB(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let int = Int(cleaned, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        return (r, g, b)
    }

    private func hsvToRGB(h: Double, s: Double, v: Double) -> (r: Double, g: Double, b: Double) {
        let i = Int(h * 6)
        let f = h * 6 - Double(i)
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        switch i % 6 {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }

    private func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxVal = max(r, max(g, b))
        let minVal = min(r, min(g, b))
        let delta = maxVal - minVal
        var h: Double = 0

        if delta > 0 {
            if maxVal == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxVal == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h /= 6
            if h < 0 { h += 1 }
        }

        let s = maxVal == 0 ? 0 : delta / maxVal
        return (h, s, maxVal)
    }

    private func rgbaComponents(from color: Color) -> (r: Double, g: Double, b: Double, a: Double) {
        #if os(macOS)
        let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.white
        return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent), Double(ns.alphaComponent))
        #else
        let ui = UIColor(color)
        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #endif
    }

}

private struct SatBrightnessFieldView: View {
    let hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double
    let onColorChange: (Bool) -> Void

    private let markerDiameter: CGFloat = 18
    private var markerRadius: CGFloat { markerDiameter / 2 }

    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let height = max(1, geo.size.height)
            let markerX = clampedMarkerX(width: width)
            let markerY = clampedMarkerY(height: height)

            ZStack(alignment: .topLeading) {
                saturationGradient
                brightnessGradient
                markerView(x: markerX, y: markerY)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width, height: height))
        }
    }

    private var saturationGradient: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.white, Color(hue: hue, saturation: 1, brightness: 1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private var brightnessGradient: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func markerView(x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: markerDiameter, height: markerDiameter)
            .background(Circle().fill(Color.black.opacity(0.25)))
            .position(x: x, y: y)
            .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 0)
    }

    private func clampedMarkerX(width: CGFloat) -> CGFloat {
        let rawX = saturation * width
        return max(markerRadius, min(width - markerRadius, rawX))
    }

    private func clampedMarkerY(height: CGFloat) -> CGFloat {
        let rawY = (1 - brightness) * height
        return max(markerRadius, min(height - markerRadius, rawY))
    }

    private func dragGesture(width: CGFloat, height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let clampedX = max(0, min(width, value.location.x))
                let clampedY = max(0, min(height, value.location.y))
                saturation = clampedX / width
                brightness = 1 - (clampedY / height)
                onColorChange(false)
            }
            .onEnded { _ in
                onColorChange(true)
            }
    }
}

private struct CheckerboardBackground: View {
    private let cell: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            let cols = Int(ceil(geo.size.width / cell))
            let rows = Int(ceil(geo.size.height / cell))
            Canvas { ctx, _ in
                for row in 0..<rows {
                    for col in 0..<cols {
                        let isDark = (row + col).isMultiple(of: 2)
                        let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                        ctx.fill(Path(rect), with: .color(isDark ? Color.white.opacity(0.24) : Color.white.opacity(0.08)))
                    }
                }
            }
        }
    }
}
