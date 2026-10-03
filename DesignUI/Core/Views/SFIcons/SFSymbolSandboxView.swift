//
//  SFSymbolSandboxView.swift
//
//  Interactive SF Symbols browser and code sandbox.
//

import SwiftUI
import Foundation

struct SFSymbolSandboxView: View {
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @State private var searchTask: Task<Void, Never>?

    private var filteredSymbols: [String] {
        let query = debouncedSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var grid: [GridItem] {
        [GridItem(.adaptive(minimum: 92), spacing: 12)]
    }

    private var symbolCountLabel: String {
        "\(filteredSymbols.count) symbols"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    symbolGridCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .navigationTitle("SF Symbols")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search SF Symbols")
            .onChange(of: searchText) { oldValue, newValue in
                handleSearchTextChange(oldValue: oldValue, newValue: newValue)
            }
            .onDisappear { searchTask?.cancel() }
            .navigationDestination(for: String.self) { symbol in
                SFSymbolDetailView(symbol: symbol)
            }
        }
    }


    private func infoChip(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private var symbolGridCard: some View {
        symbolGridContent
        .padding(16)
    }

    private var symbolGridContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            symbolGrid
        }
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: grid, spacing: 12) {
            ForEach(filteredSymbols, id: \.self) { symbol in
                symbolGridLink(for: symbol)
            }
        }
    }

    private func symbolGridLink(for symbol: String) -> some View {
        NavigationLink(value: symbol) {
            SymbolGridCell(symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func handleSearchTextChange(oldValue _: String, newValue: String) {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            debouncedSearch = newValue
        }
    }
}

private struct SFSymbolDetailView: View {
    let symbol: String
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    @State private var selectedEffect: SymbolMotionEffect = .bounce
    @State private var selectedRenderingMode: SymbolRenderingModeChoice = .hierarchical
    @State private var selectedWeight: SymbolWeightChoice = .semibold
    @State private var previewSize: Double = 72
    @State private var animationSpeed: Double = 1.0
    @State private var variableColorLevel: Double = 0.65
    @State private var localToast: ToastData?
    @State private var effectPlayValue = 0
    @State private var transientEffectActive = false
    @State private var replacePreviewToggle = false

    private var usesSplitLayout: Bool {
#if os(macOS)
        return true
#elseif os(iOS)
        return horizontalSizeClass == .regular
#else
        return false
#endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                previewCard
                if usesSplitLayout {
                    HStack(alignment: .top, spacing: 16) {
                        controlsCard
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        codeCard
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    controlsCard
                    codeCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .navigationTitle(symbol)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toast($localToast)
    }

    private var previewCard: some View {
        SFSymbolPreviewCard(
            symbolName: symbol,
            effectName: selectedEffect.displayName,
            effectButtonTint: effectButtonTint,
            isPlayDisabled: selectedEffect == .none,
            onPlay: triggerPreviewEffect
        ) {
            previewSymbol
                .frame(width: 180, height: 180)
        }
    }

    @ViewBuilder
    private var previewSymbol: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            switch selectedEffect {
            case .none:
                styledSymbolImage(name: symbol)
            case .bounce:
                styledSymbolImage(name: symbol)
                    .symbolEffect(.bounce.byLayer, options: animationOptions, value: effectPlayValue)
            case .pulse:
                styledSymbolImage(name: symbol)
                    .symbolEffect(.pulse.byLayer, options: animationOptions, value: effectPlayValue)
            case .scale:
                styledSymbolImage(name: symbol)
                    .symbolEffect(.scale.wholeSymbol, options: animationOptions, isActive: transientEffectActive)
            case .variableColor:
                styledSymbolImage(name: symbol)
                    .symbolEffect(.variableColor.iterative, options: animationOptions, value: effectPlayValue)
            case .rotation:
                if #available(iOS 18.0, macOS 15.0, *) {
                    styledSymbolImage(name: symbol)
                        .symbolEffect(.rotate.clockwise, options: animationOptions, value: effectPlayValue)
                } else {
                    styledSymbolImage(name: symbol)
                }
            case .wiggle:
                if #available(iOS 18.0, macOS 15.0, *) {
                    styledSymbolImage(name: symbol)
                        .symbolEffect(.wiggle.clockwise, options: animationOptions, value: effectPlayValue)
                } else {
                    styledSymbolImage(name: symbol)
                }
            case .breathe:
                if #available(iOS 18.0, macOS 15.0, *) {
                    styledSymbolImage(name: symbol)
                        .symbolEffect(.breathe.plain, options: animationOptions, value: effectPlayValue)
                } else {
                    styledSymbolImage(name: symbol)
                }
            case .appear:
                styledSymbolImage(name: symbol)
                    .symbolEffect(.appear.byLayer, options: animationOptions, isActive: transientEffectActive)
            case .replace:
                replacePreviewSymbol
            }
        } else {
            styledSymbolImage(name: symbol)
        }
    }

    private func styledSymbolImage(name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: previewSize, weight: selectedWeight.fontWeight, design: .rounded))
            .symbolRenderingMode(selectedRenderingMode.renderingMode)
            .foregroundStyle(selectedRenderingMode.foregroundStyles)
            .opacity(selectedEffect == .variableColor ? (0.35 + variableColorLevel * 0.65) : 1.0)
    }

    @ViewBuilder
    private var replacePreviewSymbol: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            Group {
                if replacePreviewToggle {
                    styledSymbolImage(name: alternatePreviewSymbol)
                } else {
                    styledSymbolImage(name: symbol)
                }
            }
            .contentTransition(.symbolEffect(.replace.wholeSymbol))
        } else {
            styledSymbolImage(name: symbol)
        }
    }

    private var animationOptions: SymbolEffectOptions {
        .default.speed(animationSpeed)
    }

    private var alternatePreviewSymbol: String {
        if symbol.contains(".fill") {
            return symbol.replacingOccurrences(of: ".fill", with: "")
        }

        let filledVariant = symbol + ".fill"
        return filledVariant == symbol ? "sparkles" : filledVariant
    }

    private var controlsCard: some View {
        SFSymbolControlsCard {
            effectPicker
            renderingModePicker
            weightPicker
            symbolSizeControl
            animationSpeedControl
            variableColorControl
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var symbolSizeControl: some View {
        SFSymbolSliderControlRow(
            title: "Symbol Size",
            valueText: "\(Int(previewSize)) pt",
            value: $previewSize,
            range: 20...125,
            step: 5
        )
    }

    private var animationSpeedControl: some View {
        SFSymbolSliderControlRow(
            title: "Animation Speed",
            valueText: String(format: "%.2fx", animationSpeed),
            value: $animationSpeed,
            range: 0.5...2.0,
            step: 0.25
        )
    }

    private var variableColorControl: some View {
        SFSymbolSliderControlRow(
            title: "Variable Color",
            valueText: "\(Int(variableColorLevel * 100))%",
            value: $variableColorLevel,
            range: 0...1,
            step: 0.05,
            footnote: "Use this as a preview intensity control while testing variable color symbols."
        )
    }

    private var effectPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Effect", selection: $selectedEffect) {
                ForEach(SymbolMotionEffect.allCases) { effect in
                    Text(effect.displayName).tag(effect)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var renderingModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Rendering", selection: $selectedRenderingMode) {
                ForEach(SymbolRenderingModeChoice.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var weightPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Weight", selection: $selectedWeight) {
                ForEach(SymbolWeightChoice.allCases) { weight in
                    Text(weight.displayName).tag(weight)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var codeCard: some View {
        VStack {
            LiveSyntaxHighlightedCode(code: currentSnippet, fontSize: 14, maxHeight: 260)
        }
    }

    private var currentSnippet: String {
        if selectedEffect == .replace {
            return replaceSnippet
        }
        if selectedEffect == .scale || selectedEffect == .appear {
            return transientSnippet
        }

        let weightCode = selectedWeight.swiftUIFontWeightCode
        let sizeCode = Int(previewSize)
        let renderingLine = selectedRenderingMode.codeLine
        let effectLine = selectedEffect.codeLine(
            animationSpeed: animationSpeed,
            animateEffects: false,
            variableColorLevel: variableColorLevel
        )

        return [
            "@State private var effectTrigger = 0",
            "",
            "Image(systemName: \"\(symbol)\")",
            "    .font(.system(size: \(sizeCode), weight: .\(weightCode), design: .rounded))",
            "    \(renderingLine)",
            effectLine.isEmpty ? nil : "    \(effectLine)",
            "",
            "Button(\"Play\") {",
            "    effectTrigger += 1",
            "}"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private var replaceSnippet: String {
        let weightCode = selectedWeight.swiftUIFontWeightCode
        let sizeCode = Int(previewSize)
        let renderingLine = selectedRenderingMode.codeLine

        return [
            "@State private var isAlternate = false",
            "",
            "Image(systemName: isAlternate ? \"\(alternatePreviewSymbol)\" : \"\(symbol)\")",
            "    .font(.system(size: \(sizeCode), weight: .\(weightCode), design: .rounded))",
            "    \(renderingLine)",
            "    .contentTransition(.symbolEffect(.replace.wholeSymbol))",
            "",
            "Button(\"Play\") {",
            "    withAnimation(.easeInOut(duration: \(String(format: "%.2f", effectDuration))) {",
            "        isAlternate.toggle()",
            "    }",
            "}"
        ]
        .joined(separator: "\n")
    }

    private var transientSnippet: String {
        let weightCode = selectedWeight.swiftUIFontWeightCode
        let sizeCode = Int(previewSize)
        let renderingLine = selectedRenderingMode.codeLine
        let effectLine = selectedEffect.codeLine(
            animationSpeed: animationSpeed,
            animateEffects: true,
            variableColorLevel: variableColorLevel
        )

        return [
            "@State private var isPlaying = false",
            "",
            "Image(systemName: \"\(symbol)\")",
            "    .font(.system(size: \(sizeCode), weight: .\(weightCode), design: .rounded))",
            "    \(renderingLine)",
            "    \(effectLine)",
            "",
            "Button(\"Play\") {",
            "    isPlaying = true",
            "    DispatchQueue.main.asyncAfter(deadline: .now() + \(String(format: "%.2f", effectDuration))) {",
            "        isPlaying = false",
            "    }",
            "}"
        ]
        .joined(separator: "\n")
    }

    private func copyCurrentSnippet() {
        copyToClipboard(currentSnippet)
        localToast = ToastData(title: "Copied SF Symbol code", icon: "checkmark.circle.fill")
    }

    private var effectButtonTint: Color {
        selectedEffect == .none ? .secondary.opacity(0.5) : .primary
    }

    private var effectDuration: Double {
        max(0.2, 0.6 / max(animationSpeed, 0.1))
    }

    private func triggerPreviewEffect() {
        switch selectedEffect {
        case .none:
            return
        case .replace:
            withAnimation(.easeInOut(duration: effectDuration)) {
                replacePreviewToggle.toggle()
            }
        case .scale, .appear:
            transientEffectActive = true
            let duration = effectDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                transientEffectActive = false
            }
        default:
            effectPlayValue += 1
        }
    }
}

private struct SymbolGridCell: View {
    let symbol: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .regular))
                .frame(height: 28)
                .frame(maxWidth: .infinity)

            Text(symbol)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 94)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SFSymbolPreviewCard<PreviewContent: View>: View {
    let symbolName: String
    let effectName: String
    let effectButtonTint: Color
    let isPlayDisabled: Bool
    let onPlay: () -> Void
    @ViewBuilder let previewContent: () -> PreviewContent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topTrailing) {
                SFSymbolPreviewBackground()

                playButton
                    .padding(14)

                VStack(spacing: 14) {
                    previewContent()
                    previewLabels
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: 260)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var playButton: some View {
        Button(action: onPlay) {
            Label("Play", systemImage: "play.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(effectButtonTint)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isPlayDisabled)
    }

    private var previewLabels: some View {
        VStack(spacing: 2) {
            Text(symbolName)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)

            Text(effectName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct SFSymbolPreviewBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.08),
                        Color.primary.opacity(0.03),
                        Color.primary.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

private struct SFSymbolControlsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
    }
}

private struct SFSymbolSliderControlRow: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: step)

            if let footnote, !footnote.isEmpty {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private enum SymbolMotionEffect: String, CaseIterable, Identifiable {
    case none
    case bounce
    case pulse
    case scale
    case variableColor
    case rotation
    case wiggle
    case breathe
    case replace
    case appear

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .bounce: return "Bounce"
        case .pulse: return "Pulse"
        case .scale: return "Scale"
        case .variableColor: return "Variable Color"
        case .rotation: return "Rotation"
        case .wiggle: return "Wiggle"
        case .breathe: return "Breathe"
        case .replace: return "Replace"
        case .appear: return "Appear"
        }
    }

    func codeLine(animationSpeed: Double, animateEffects: Bool, variableColorLevel: Double) -> String {
        guard self != .none, self != .replace else { return "" }

        let speed = String(format: "%.2f", animationSpeed)
        let active = animateEffects ? "true" : "false"
        let intensity = Int(variableColorLevel * 100)

        switch self {
        case .bounce:
            return ".symbolEffect(.bounce.byLayer, options: .default.speed(\(speed)), value: effectTrigger)"
        case .pulse:
            return ".symbolEffect(.pulse.byLayer, options: .default.speed(\(speed)), value: effectTrigger)"
        case .scale:
            return ".symbolEffect(.scale.wholeSymbol, options: .default.speed(\(speed)), isActive: \(active))"
        case .variableColor:
            return ".symbolEffect(.variableColor.iterative, options: .default.speed(\(speed)), value: effectTrigger) // Preview intensity: \(intensity)%"
        case .rotation:
            return ".symbolEffect(.rotate.clockwise, options: .default.speed(\(speed)), value: effectTrigger)"
        case .wiggle:
            return ".symbolEffect(.wiggle.clockwise, options: .default.speed(\(speed)), value: effectTrigger)"
        case .breathe:
            return ".symbolEffect(.breathe.plain, options: .default.speed(\(speed)), value: effectTrigger)"
        case .appear:
            return ".symbolEffect(.appear.byLayer, options: .default.speed(\(speed)), isActive: \(active))"
        case .replace:
            return ""
        case .none:
            return ""
        }
    }
}

private enum SymbolRenderingModeChoice: String, CaseIterable, Identifiable {
    case monochrome
    case hierarchical
    case palette
    case multicolor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monochrome: return "Monochrome"
        case .hierarchical: return "Hierarchical"
        case .palette: return "Palette"
        case .multicolor: return "Multicolor"
        }
    }

    var renderingMode: SymbolRenderingMode {
        switch self {
        case .monochrome: return .monochrome
        case .hierarchical: return .hierarchical
        case .palette: return .palette
        case .multicolor: return .multicolor
        }
    }

    var foregroundStyles: some ShapeStyle {
        switch self {
        case .monochrome:
            return AnyShapeStyle(Color.primary)
        case .hierarchical:
            return AnyShapeStyle(Color.secondary)
        case .palette:
            return AnyShapeStyle(Color.accentColor)
        case .multicolor:
            return AnyShapeStyle(Color.primary)
        }
    }

    var codeLine: String {
        switch self {
        case .monochrome:
            return ".symbolRenderingMode(.monochrome)"
        case .hierarchical:
            return ".symbolRenderingMode(.hierarchical)"
        case .palette:
            return ".symbolRenderingMode(.palette)"
        case .multicolor:
            return ".symbolRenderingMode(.multicolor)"
        }
    }
}

private enum SymbolWeightChoice: String, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold
    case bold

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var fontWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    var swiftUIFontWeightCode: String {
        rawValue
    }
}
