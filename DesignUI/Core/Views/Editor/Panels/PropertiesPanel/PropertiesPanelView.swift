//
//  PropertiesPanelView.swift
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

struct PropertiesPanelView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    var useNavigationStack: Bool = true
    var showNavigationTitle: Bool = true
    var showComponentActionsSection: Bool = true
    
    // Gallery Sheet State
    @State private var showImageGallery = false
    @State private var galleryImageName = ""
    @State private var activeImagePropertyKey: String?
    @State private var showColorEditor = false
    @State private var colorEditorModifierId: UUID?
    @State private var colorEditorTitle: String = "Fill Color"
    
    var body: some View {
        #if os(iOS)
        if useNavigationStack {
            navigationContent
        } else {
            plainContent
        }
        #else
        plainContent
        #endif
    }
    
    private var navigationContent: some View {
        content
            .applyNavigationTitleIfNeeded(title: propertiesTitle, show: showNavigationTitle)
            .navigationDestination(isPresented: $showImageGallery) {
                ImageGalleryView(selectedImageName: $galleryImageName)
            }
            .navigationDestination(isPresented: $showColorEditor) {
                colorEditorDestinationView
            }
    }

    private var plainContent: some View {
        content
            .sheet(isPresented: $showImageGallery) {
                ImageGalleryView(selectedImageName: $galleryImageName)
            }
            .sheet(isPresented: $showColorEditor) {
                colorEditorDestinationView
            }
    }
    
    private var content: some View {
        VStack(alignment: .leading) {
            // Properties content
            if let component = selectedComponent {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        FastInspectorView(
                            component: component,
                            canvasManager: canvasManager,
                            showComponentActions: showComponentActionsSection && component.type != .statusBar,
                            onDuplicateComponent: {
                                guard let liveSelected = canvasManager.selectedComponent else { return }
                                canvasManager.duplicateComponent(liveSelected)
                            },
                            onDeleteComponent: {
                                guard let liveSelected = canvasManager.selectedComponent else { return }
                                canvasManager.removeComponent(liveSelected)
                                selectedComponent = nil
                            },
                            showGallery: $showImageGallery,
                            activePropertyKey: $activeImagePropertyKey,
                            showColorEditor: $showColorEditor,
                            colorEditorModifierId: $colorEditorModifierId,
                            colorEditorTitle: $colorEditorTitle
                        )
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // Force entire view to update when component INSTANCE changes (not just ID)
                .id(ObjectIdentifier(component))
                .onChange(of: galleryImageName) { _, newName in
                    if !newName.isEmpty {
                        updateImageProperty(with: newName)
                    }
                }
#if os(iOS)
#endif
            } else {
                // Fallback No selection state
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
        
    private var propertiesTitle: String {
        if PlatformLayoutContext.isPhone {
            return "Properties"
        }
        if PlatformLayoutContext.isPad {
            return ""
        }
        if let component = selectedComponent {
            return component.type.rawValue
        }
        return "Properties"
    }

    @ViewBuilder
    private var colorEditorDestinationView: some View {
        if let component = selectedComponent,
           let modifierId = colorEditorModifierId,
           let liveModifier = component.modifiers.first(where: { $0.id == modifierId }) {
            ColorModifierEditor(
                modifier: Binding(
                    get: { component.modifiers.first(where: { $0.id == modifierId }) ?? liveModifier },
                    set: { newModifier in
                        DispatchQueue.main.async {
                            canvasManager.updateModifier(for: component, modifier: newModifier)
                        }
                    }
                ),
                component: component,
                title: colorEditorTitle
            )
            #if os(iOS)
            .navigationTitle(colorEditorTitle)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onDisappear {
                colorEditorModifierId = nil
            }
        } else {
            EmptyView()
        }
    }
    
    private func updateImageProperty(with name: String) {
        guard let component = selectedComponent else { return }
        
        if component.type == .image {
            canvasManager.updateImageSelection(for: component, imageName: name)
        } else {
            if let key = activeImagePropertyKey {
                canvasManager.updateImageSelection(for: component, imageName: name, propertyKey: key)
            } else {
                canvasManager.updateImageSelection(for: component, imageName: name)
            }
        }

        DispatchQueue.main.async {
            activeImagePropertyKey = nil
            galleryImageName = ""
        }

        component.objectWillChange.send()
    }
}

private extension View {
    @ViewBuilder
    func applyNavigationTitleIfNeeded(title: String, show: Bool) -> some View {
        if show {
            self
                .navigationTitle(title)
            #if (iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        } else {
            self
        }
    }

    @ViewBuilder
    func helpIf(_ text: String?) -> some View {
        if let text, !text.isEmpty {
            self.help(text)
        } else {
            self
        }
    }
}

private struct FastInspectorView: View {
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    let showComponentActions: Bool
    let onDuplicateComponent: () -> Void
    let onDeleteComponent: () -> Void
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    @Binding var showColorEditor: Bool
    @Binding var colorEditorModifierId: UUID?
    @Binding var colorEditorTitle: String
    @State private var objectOpacityInput: String = "100"
    @State private var textInput: String = ""
    @State private var textFieldTextInput: String = ""
    @State private var textFieldPlaceholderInput: String = ""
    @State private var sliderValueInput: String = "0.5"
    @State private var sliderMinInput: String = "0"
    @State private var sliderMaxInput: String = "1"
    @State private var shapeCornerRadiusInput: String = "12"
    @State private var progressValueInput: String = "0.6"
    @State private var progressTotalInput: String = "1"
    @State private var chartPointCountValue: Double = 20
    @State private var gaugeValueInput: String = "50"
    @State private var gaugeMinInput: String = "0"
    @State private var gaugeMaxInput: String = "100"
    @State private var textFontSizeInput: String = "17"
    @State private var symbolInput: String = "star"
    @State private var showSFSymbolPicker: Bool = false
    @State private var frameWidthInput: String = "120"
    @State private var frameHeightInput: String = "120"
    @State private var paddingHorizontalInput: String = "0"
    @State private var paddingVerticalInput: String = "0"
    @State private var offsetXInput: String = "0"
    @State private var offsetYInput: String = "0"
    @State private var stackSpacingInput: String = "0"
    @State private var rotationInput: String = "0"
    @State private var cornerRadiusInput: String = "0"
    @State private var fillHexInputs: [UUID: String] = [:]
    @State private var fillOpacityInputs: [UUID: String] = [:]
    @State private var borderHexInputs: [UUID: String] = [:]
    @State private var borderOpacityInputs: [UUID: String] = [:]
    @State private var borderWidthInputs: [UUID: String] = [:]
    @State private var shadowHexInputs: [UUID: String] = [:]
    @State private var shadowOpacityInputs: [UUID: String] = [:]
    @State private var shadowRadiusInputs: [UUID: String] = [:]
    @State private var shadowXInputs: [UUID: String] = [:]
    @State private var shadowYInputs: [UUID: String] = [:]
    @State private var scrubStartValues: [String: Double] = [:]
    @State private var macFillPopoverModifierId: UUID?
    @State private var isSyncingInspectorInputs = false
    @FocusState private var isTextInputFocused: Bool
    @FocusState private var focusedFillField: FillFieldFocus?
    @FocusState private var focusedBorderColorField: FillFieldFocus?
    @FocusState private var focusedBorderWidthId: UUID?
    @FocusState private var focusedShadowColorField: FillFieldFocus?
    @FocusState private var focusedShadowNumericField: ShadowNumericFocus?
    @State private var numericInputTarget: NumericInputTarget?
    @State private var numericInputText: String = ""

    private enum FillFieldFocus: Hashable {
        case hex(UUID)
        case opacity(UUID)
    }

    private enum ShadowNumericFocus: Hashable {
        case radius(UUID)
        case x(UUID)
        case y(UUID)
    }

    private enum NumericInputTarget: Hashable {
        case frameWidth
        case frameHeight
        case offsetX
        case offsetY
        case paddingHorizontal
        case paddingVertical
        case opacity
        case cornerRadius
        case blur(UUID)
        case shadowRadius(UUID)
        case shadowX(UUID)
        case shadowY(UUID)
    }
    
    @ViewBuilder
    private var panelSections: some View {
        if isCanvasSettingsSelection {
            canvasSettingsSection
        } else {
            panelSectionsPrimary
            panelSectionsInteractive
            panelSectionsData
            panelSectionsTextAndLayout
            layoutSection
            effectGroupsSection
        }
    }
    
    @ViewBuilder
    private var panelSectionsPrimary: some View {
        if hasSymbolProperty {
            sfSymbolSection
        }
        if component.type == .map {
            mapSection
        }
        if component.type == .image {
            imageSection
        }
        if component.type == .scrollView {
            scrollViewSection
        }
        if component.type == .shape {
            shapeSection
        }
    }
    
    @ViewBuilder
    private var panelSectionsInteractive: some View {
        if component.type == .textField {
            textFieldSection
        }
        if component.type == .button {
            buttonSection
        }
        if component.type == .toggle {
            switchSection
        }
        if component.type == .slider {
            sliderSection
        }
    }
    
    @ViewBuilder
    private var panelSectionsData: some View {
        if component.type == .progressView {
            progressViewSection
        }
        if component.type == .chart {
            chartSection
        }
        if component.type == .gauge {
            gaugeSection
        }
        if component.type == .stack {
            stackSection
        }
    }
    
    @ViewBuilder
    private var panelSectionsTextAndLayout: some View {
        if editableTextKey != nil && component.type != .textField {
            textSection
        }
    }
    
    @ViewBuilder
    private var symbolPickerSheetContent: some View {
        #if os(iOS)
        NavigationStack {
            SFSymbolPickerView(selectedSymbol: $symbolInput) { selectedSymbol in
                symbolInput = selectedSymbol
                canvasManager.updateComponentProperty(for: component, key: "symbolName", value: selectedSymbol)
                showSFSymbolPicker = false
            }
        }
        #else
        SFSymbolPickerView(selectedSymbol: $symbolInput) { selectedSymbol in
            symbolInput = selectedSymbol
            canvasManager.updateComponentProperty(for: component, key: "symbolName", value: selectedSymbol)
            showSFSymbolPicker = false
        }
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            panelSections
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            syncInspectorInputs()
        }
        .onReceive(component.objectWillChange) { _ in
            syncInspectorInputs()
        }
        .sheet(isPresented: $showSFSymbolPicker) {
            symbolPickerSheetContent
        }
        .alert(numericInputTitle, isPresented: Binding(
            get: { numericInputTarget != nil },
            set: { showing in
                if !showing { numericInputTarget = nil }
            }
        )) {
            TextField("Value", text: $numericInputText)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
            Button("Cancel", role: .cancel) {
                numericInputTarget = nil
            }
            Button("Apply") {
                commitNumericInput()
            }
        } message: {
            Text("Enter an exact value")
        }
    }

    private var isPhone: Bool {
        PlatformLayoutContext.isPhone
    }

    private var numericInputTitle: String {
        guard let target = numericInputTarget else { return "Value" }
        switch target {
        case .frameWidth: return "Frame Width"
        case .frameHeight: return "Frame Height"
        case .offsetX: return "Offset X"
        case .offsetY: return "Offset Y"
        case .paddingHorizontal: return "Horizontal Padding"
        case .paddingVertical: return "Vertical Padding"
        case .opacity: return "Opacity %"
        case .cornerRadius: return "Corner Radius"
        case .blur: return "Blur Radius"
        case .shadowRadius: return "Shadow Radius"
        case .shadowX: return "Shadow X"
        case .shadowY: return "Shadow Y"
        }
    }

    private func commitNumericInput() {
        guard let target = numericInputTarget else { return }
        let cleaned = numericInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(cleaned) else {
            numericInputTarget = nil
            return
        }

        switch target {
        case .frameWidth:
            updateFrameDimension(key: "width", value: String(parsed), continuous: false)
        case .frameHeight:
            updateFrameDimension(key: "height", value: String(parsed), continuous: false)
        case .offsetX:
            setOffsetAxis("x", String(parsed), continuous: false)
        case .offsetY:
            setOffsetAxis("y", String(parsed), continuous: false)
        case .paddingHorizontal:
            setPaddingAxis("horizontal", String(parsed))
        case .paddingVertical:
            setPaddingAxis("vertical", String(parsed))
        case .opacity:
            setUniversalOpacity(max(0, min(100, parsed)) / 100.0)
        case .cornerRadius:
            setCornerRadius(String(parsed))
        case let .blur(effectId):
            if let effect = component.modifiers.first(where: { $0.id == effectId }) {
                let clamped = max(0, min(50, parsed))
                updateEffectModifier(effect) { mod in
                    mod.properties["radius"] = clamped
                }
            }
        case let .shadowRadius(effectId):
            if let effect = component.modifiers.first(where: { $0.id == effectId }) {
                updateShadowRadius(effect, value: max(0, parsed), continuous: false)
            }
        case let .shadowX(effectId):
            if let effect = component.modifiers.first(where: { $0.id == effectId }) {
                updateShadowOffset(effect, x: parsed, y: currentShadowY(for: effect), continuous: false)
            }
        case let .shadowY(effectId):
            if let effect = component.modifiers.first(where: { $0.id == effectId }) {
                updateShadowOffset(effect, x: currentShadowX(for: effect), y: parsed, continuous: false)
            }
        }

        numericInputTarget = nil
    }

    private var isCanvasSettingsSelection: Bool {
        component.type == .statusBar
    }

    private func syncInspectorInputs() {
        guard !isSyncingInspectorInputs else { return }
        isSyncingInspectorInputs = true
        defer {
            DispatchQueue.main.async {
                isSyncingInspectorInputs = false
            }
        }

        if isCanvasSettingsSelection {
            return
        }

        syncOpacityInputs()
        if !isTextInputFocused, editableTextKey != nil, component.type != .textField {
            syncTextInput()
        }

        if hasSymbolProperty {
            syncSymbolInput()
        }

        if editableTextKey != nil || hasSymbolProperty {
            syncTextFontSizeInput()
        }

        switch component.type {
        case .textField:
            syncTextFieldInputs()
        case .slider:
            syncSliderInputs()
        case .progressView:
            syncProgressInputs()
        case .chart:
            syncChartInputs()
        case .gauge:
            syncGaugeInputs()
        case .shape:
            syncShapeInputs()
        default:
            break
        }

        syncFrameInputs()
        syncPaddingInputs()
        syncOffsetInputs()
        syncStackInputs()
        syncRotationInput()
        syncCornerRadiusInput()
        syncFillInputs()
        syncBorderInputs()
        syncShadowInputs()
    }

    private var editableTextKey: String? {
        if component.getProperty(key: "text") != nil { return "text" }
        if component.getProperty(key: "placeholder") != nil { return "placeholder" }
        return nil
    }

    private var hasSymbolProperty: Bool {
        component.getProperty(key: "symbolName") != nil
    }

    private var imageNameValue: String {
        let name = (component.getProperty(key: "imageName") as? String) ?? ""
        let dataValue = (component.getProperty(key: "imageData") as? String) ?? ""
        if !name.isEmpty { return name }
        if !dataValue.isEmpty { return dataValue }
        return ""
    }

    private var imageFieldTitle: String {
        let value = imageNameValue
        return value.isEmpty ? "Select Image" : value
    }

    private var imageIsResizable: Bool {
        (component.getProperty(key: "resizable") as? Bool) ?? true
    }

    private var imageAspectRatio: String {
        let value = ((component.getProperty(key: "aspectRatio") as? String) ?? "fit").lowercased()
        switch value {
        case "fit", "fill", "none":
            return value
        default:
            return "fit"
        }
    }

    private var imageSection: some View {
        inspectorSection(
            "Image",
            plus: nil,
            showActions: showComponentActions && component.type == .image
        ) {
            VStack(spacing: 10) {
                Button {
                    activePropertyKey = "imageName"
                    showGallery = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(imageFieldTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(roundedFieldBackground)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Image")

                toggleField(
                    title: "Resizable",
                    value: imageIsResizable,
                    helpText: "Resizable"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "resizable", value: enabled)
                }

                compactMenuField(
                    title: imageAspectRatio.capitalized,
                    options: ["Fit", "Fill", "None"],
                    helpText: "Aspect Ratio"
                ) { selected in
                    canvasManager.updateComponentProperty(
                        for: component,
                        key: "aspectRatio",
                        value: selected.lowercased()
                    )
                }
            }
        }
    }

    private var scrollAxis: String {
        let axis = ((component.getProperty(key: "axis") as? String) ?? "vertical").lowercased()
        return axis == "horizontal" ? "horizontal" : "vertical"
    }

    private var scrollShowsIndicators: Bool {
        component.getBoolProperty(key: "showsIndicators", defaultValue: true)
    }

    private struct MapLocationPreset {
        let name: String
        let locationName: String
        let latitude: Double
        let longitude: Double
        let latitudeDelta: Double
        let longitudeDelta: Double
    }

    private let mapLocationPresets: [MapLocationPreset] = [
        .init(name: "Apple Park", locationName: "Apple Park, Cupertino", latitude: 37.3346, longitude: -122.0090, latitudeDelta: 0.018, longitudeDelta: 0.018),
        .init(name: "Cupertino", locationName: "Cupertino, California", latitude: 37.3229, longitude: -122.0322, latitudeDelta: 0.05, longitudeDelta: 0.05),
        .init(name: "San Francisco", locationName: "San Francisco, California", latitude: 37.7749, longitude: -122.4194, latitudeDelta: 0.08, longitudeDelta: 0.08),
        .init(name: "New York City", locationName: "New York, New York", latitude: 40.7128, longitude: -74.0060, latitudeDelta: 0.08, longitudeDelta: 0.08),
        .init(name: "London", locationName: "London, United Kingdom", latitude: 51.5072, longitude: -0.1276, latitudeDelta: 0.08, longitudeDelta: 0.08),
        .init(name: "Paris", locationName: "Paris, France", latitude: 48.8566, longitude: 2.3522, latitudeDelta: 0.08, longitudeDelta: 0.08),
        .init(name: "Tokyo", locationName: "Tokyo, Japan", latitude: 35.6764, longitude: 139.6500, latitudeDelta: 0.08, longitudeDelta: 0.08)
    ]

    private var mapPresetValue: String {
        let value = (component.getProperty(key: "mapPreset") as? String) ?? "Apple Park"
        if mapLocationPresets.contains(where: { $0.name == value }) {
            return value
        }
        return "Apple Park"
    }

    private var mapStyleValue: String {
        let value = ((component.getProperty(key: "mapStyle") as? String) ?? "standard").lowercased()
        switch value {
        case "standard", "imagery", "hybrid":
            return value
        default:
            return "standard"
        }
    }

    private var mapShowsTraffic: Bool {
        component.getBoolProperty(key: "showsTraffic", defaultValue: false)
    }

    private var mapSection: some View {
        inspectorSection(
            "Map",
            plus: nil,
            showActions: showComponentActions && component.type == .map
        ) {
            VStack(spacing: 10) {
                compactMenuField(
                    title: mapPresetValue,
                    options: mapLocationPresets.map(\.name),
                    helpText: "Location Preset"
                ) { selected in
                    applyMapPreset(named: selected)
                }

                compactMenuField(
                    title: mapStyleValue.capitalized,
                    options: ["Standard", "Imagery", "Hybrid"],
                    helpText: "Map Style"
                ) { selected in
                    canvasManager.updateComponentProperty(
                        for: component,
                        key: "mapStyle",
                        value: selected.lowercased()
                    )
                }

                toggleField(
                    title: "Shows Traffic",
                    value: mapShowsTraffic,
                    helpText: "Shows Traffic"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "showsTraffic", value: enabled)
                }
            }
        }
    }

    private func applyMapPreset(named name: String) {
        guard let preset = mapLocationPresets.first(where: { $0.name == name }) else { return }
        canvasManager.updateComponentProperties(
            for: component,
            updates: [
                (key: "mapPreset", value: preset.name),
                (key: "locationName", value: preset.locationName),
                (key: "latitude", value: preset.latitude),
                (key: "longitude", value: preset.longitude),
                (key: "latitudeDelta", value: preset.latitudeDelta),
                (key: "longitudeDelta", value: preset.longitudeDelta)
            ],
            description: "Updated Map Location",
            coalesceKey: "update_map_preset_\(component.id.uuidString)"
        )
    }

    private var scrollViewSection: some View {
        inspectorSection(
            "Scroll View",
            plus: nil,
            showActions: showComponentActions && component.type == .scrollView
        ) {
            VStack(spacing: 10) {
                compactMenuField(
                    title: scrollAxis.capitalized,
                    options: ["Vertical", "Horizontal"],
                    helpText: "Axis"
                ) { selected in
                    canvasManager.updateComponentProperty(
                        for: component,
                        key: "axis",
                        value: selected.lowercased()
                    )
                }

                toggleField(
                    title: "Shows Indicators",
                    value: scrollShowsIndicators,
                    helpText: "Shows Indicators"
                ) { enabled in
                    canvasManager.updateComponentProperty(
                        for: component,
                        key: "showsIndicators",
                        value: enabled
                    )
                }
            }
        }
    }

    private var shapeTypeValue: String {
        let value = (component.getProperty(key: "shapeType") as? String) ?? "Rectangle"
        let valid = ["Rectangle", "Circle", "Rounded Rectangle", "Capsule", "Ellipse"]
        return valid.contains(value) ? value : "Rectangle"
    }

    private var shapeSection: some View {
        inspectorSection(
            "Shape",
            plus: nil,
            showActions: showComponentActions && component.type == .shape
        ) {
            VStack(spacing: 10) {
                compactMenuField(
                    title: shapeTypeValue,
                    options: ["Rectangle", "Circle", "Rounded Rectangle", "Capsule", "Ellipse"],
                    helpText: "Shape Type"
                ) { selected in
                    canvasManager.updateComponentProperty(for: component, key: "shapeType", value: selected)
                    if selected == "Rounded Rectangle", component.getProperty(key: "cornerRadius") == nil {
                        canvasManager.updateComponentProperty(for: component, key: "cornerRadius", value: 12.0)
                    }
                    syncShapeInputs()
                }

                if shapeTypeValue == "Rounded Rectangle" {
                    iconPxInputField(
                        symbol: "button.roundedtop.horizontal",
                        text: $shapeCornerRadiusInput,
                        helpText: "Corner Radius",
                        scrubId: "shape-corner-radius",
                        scrubRange: 0...100
                    ) { committed in
                        setShapeCornerRadius(committed)
                    }
                }
            }
        }
    }

    private var buttonStyleValue: String {
        let value = (component.getProperty(key: "buttonStyle") as? String) ?? "borderedProminent"
        let valid = ["bordered", "borderedProminent", "borderless", "plain"]
        return valid.contains(value) ? value : "borderedProminent"
    }

    private var buttonSection: some View {
        inspectorSection(
            "Button",
            plus: nil,
            showActions: showComponentActions && component.type == .button
        ) {
            compactMenuField(
                title: buttonStyleValue,
                options: ["bordered", "borderedProminent", "borderless", "plain"],
                helpText: "Button Style"
            ) { selected in
                canvasManager.updateComponentProperty(for: component, key: "buttonStyle", value: selected)
            }
        }
    }

    private var switchIsOnValue: Bool {
        (component.getProperty(key: "isOn") as? Bool) ?? true
    }

    private var switchSection: some View {
        inspectorSection(
            "Switch",
            plus: nil,
            showActions: showComponentActions && component.type == .toggle
        ) {
            toggleField(
                title: "Is On",
                value: switchIsOnValue,
                helpText: "Is On"
            ) { enabled in
                canvasManager.updateComponentProperty(for: component, key: "isOn", value: enabled)
            }
        }
    }

    private var sliderSection: some View {
        inspectorSection(
            "Slider",
            plus: nil,
            showActions: showComponentActions && component.type == .slider
        ) {
            VStack(spacing: 10) {
                sliderNumberField(title: "Value", text: $sliderValueInput, key: "value")
                sliderNumberField(title: "Minimum", text: $sliderMinInput, key: "min")
                sliderNumberField(title: "Maximum", text: $sliderMaxInput, key: "max")
            }
        }
    }

    private var progressViewSection: some View {
        inspectorSection(
            "Progress View",
            plus: nil,
            showActions: showComponentActions && component.type == .progressView
        ) {
            VStack(spacing: 10) {
                progressNumberField(title: "Value", text: $progressValueInput, key: "value")
                progressNumberField(title: "Total", text: $progressTotalInput, key: "total")
            }
        }
    }

    private var chartStyleValue: String {
        (component.getProperty(key: "chartStyle") as? String) ?? "Line + Area"
    }

    private var chartDataPatternValue: String {
        (component.getProperty(key: "dataPreset") as? String) ?? "Increasing"
    }

    private var chartShowXAxis: Bool {
        (component.getProperty(key: "showXAxis") as? Bool) ?? true
    }

    private var chartShowYAxis: Bool {
        (component.getProperty(key: "showYAxis") as? Bool) ?? true
    }

    private var chartSection: some View {
        inspectorSection(
            "Chart",
            plus: nil,
            showActions: showComponentActions && component.type == .chart
        ) {
            VStack(spacing: 10) {
                compactMenuField(
                    title: chartStyleValue,
                    options: ["Line + Area", "Line", "Area", "Bar", "Stacked Bar", "Donut", "Sparkline"],
                    helpText: "Chart Style"
                ) { selected in
                    canvasManager.updateComponentProperty(for: component, key: "chartStyle", value: selected)
                }

                compactMenuField(
                    title: chartDataPatternValue,
                    options: ["Increasing", "Decreasing", "Stable", "Volatile", "Weekly Activity", "Spending", "Revenue"],
                    helpText: "Data Pattern"
                ) { selected in
                    canvasManager.updateComponentProperties(for: component, updates: [(key: "dataPreset", value: selected), (key: "dataPoints", value: "")], description: "Change Chart Preset")
                }

                if (component.getProperty(key: "dataPoints") as? String ?? "").isEmpty && ["Increasing", "Decreasing", "Stable", "Volatile"].contains(chartDataPatternValue) {
                    chartPointCountSlider
                }
                ChartInspectorControls(component: component, canvasManager: canvasManager)

                toggleField(
                    title: "Show X Axis",
                    value: chartShowXAxis,
                    helpText: "Show X Axis"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "showXAxis", value: enabled)
                }

                toggleField(
                    title: "Show Y Axis",
                    value: chartShowYAxis,
                    helpText: "Show Y Axis"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "showYAxis", value: enabled)
                }
            }
        }
    }

    private var chartPointCountSlider: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Point Count")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                Text(verbatim: "\(Int(chartPointCountValue.rounded()))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Slider(
                value: Binding(
                    get: { chartPointCountValue },
                    set: { newValue in
                        updateChartPointCount(newValue, continuous: true)
                    }
                ),
                in: 5...30,
                step: 1
            ) { editing in
                if !editing {
                    updateChartPointCount(chartPointCountValue, continuous: false)
                }
            }
            .tint(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
    }

    private var gaugeTypeValue: String {
        let raw = ((component.getProperty(key: "gaugeType") as? String) ?? "circular").lowercased()
        switch raw {
        case "linear", "circular", "circular range":
            return raw
        default:
            return "circular"
        }
    }

    private var gaugeShowValue: Bool {
        (component.getProperty(key: "showValue") as? Bool) ?? true
    }

    private var gaugeSection: some View {
        inspectorSection(
            "Gauge",
            plus: nil,
            showActions: showComponentActions && component.type == .gauge
        ) {
            VStack(spacing: 10) {
                compactMenuField(
                    title: gaugeTypeValue,
                    options: ["linear", "circular", "circular range"],
                    helpText: "Gauge Type"
                ) { selected in
                    canvasManager.updateComponentProperty(
                        for: component,
                        key: "gaugeType",
                        value: selected
                    )
                }

                gaugeNumberField(title: "Value", text: $gaugeValueInput, key: "value")
                gaugeNumberField(title: "Minimum", text: $gaugeMinInput, key: "min")
                gaugeNumberField(title: "Maximum", text: $gaugeMaxInput, key: "max")

                toggleField(
                    title: "Show Value",
                    value: gaugeShowValue,
                    helpText: "Show Value"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "showValue", value: enabled)
                }
            }
        }
    }

    private func progressNumberField(title: String, text: Binding<String>, key: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    updateProgressProperty(key: key, input: newValue, continuous: true)
                }
                .onSubmit {
                    updateProgressProperty(key: key, input: text.wrappedValue, continuous: false)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
    }

    private func sliderNumberField(title: String, text: Binding<String>, key: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    updateSliderProperty(key: key, input: newValue, continuous: true)
                }
                .onSubmit {
                    updateSliderProperty(key: key, input: text.wrappedValue, continuous: false)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
    }

    private func gaugeNumberField(title: String, text: Binding<String>, key: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    updateGaugeProperty(key: key, input: newValue, continuous: true)
                }
                .onSubmit {
                    updateGaugeProperty(key: key, input: text.wrappedValue, continuous: false)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
    }

    private var showStatusBarValue: Bool {
        (component.getProperty(key: "showStatusBar") as? Bool) ?? true
    }

    private var topSafeAreaValue: Bool {
        (component.getProperty(key: "topSafeArea") as? Bool) ?? true
    }

    private var canvasSettingsSection: some View {
        inspectorSection("Canvas Settings", plus: nil, showActions: false) {
            VStack(spacing: 10) {
                toggleField(
                    title: "Show Status Bar",
                    value: showStatusBarValue,
                    helpText: "Show Status Bar"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "showStatusBar", value: enabled)
                }

                toggleField(
                    title: "Top Safe Area",
                    value: topSafeAreaValue,
                    helpText: "Top Safe Area"
                ) { enabled in
                    canvasManager.updateComponentProperty(for: component, key: "topSafeArea", value: enabled)
                }
            }
        }
    }

    private var textSection: some View {
        inspectorSection("Text", plus: nil, showActions: showComponentActions && editableTextKey != nil) {
            VStack(spacing: 10) {
                textContentField
                fontSizeControlRow
                fontSizePresetRow
                fontStyleMenuRow
            }
        }
    }

    private var textFieldSection: some View {
        inspectorSection("Text Field", plus: nil, showActions: showComponentActions && component.type == .textField) {
            VStack(spacing: 10) {
                TextField("Current Text", text: $textFieldTextInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(roundedFieldBackground)
                    .onChange(of: textFieldTextInput) { _, newValue in
                        guard !isSyncingInspectorInputs else { return }
                        canvasManager.updateComponentPropertyContinuous(for: component, key: "text", value: newValue)
                    }
                    .onSubmit {
                        canvasManager.updateComponentProperty(for: component, key: "text", value: textFieldTextInput)
                    }
                    .help("Current Text")

                TextField("Placeholder", text: $textFieldPlaceholderInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(roundedFieldBackground)
                    .onChange(of: textFieldPlaceholderInput) { _, newValue in
                        guard !isSyncingInspectorInputs else { return }
                        canvasManager.updateComponentPropertyContinuous(for: component, key: "placeholder", value: newValue)
                    }
                    .onSubmit {
                        canvasManager.updateComponentProperty(for: component, key: "placeholder", value: textFieldPlaceholderInput)
                    }
                    .help("Placeholder")
            }
        }
    }

    private var textContentField: some View {
        TextField("Enter text", text: $textInput)
            .textFieldStyle(.plain)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(roundedFieldBackground)
            .focused($isTextInputFocused)
            .onChange(of: textInput) { _, newValue in
                guard isTextInputFocused, let key = editableTextKey else { return }
                canvasManager.updateComponentPropertyContinuous(for: component, key: key, value: newValue)
            }
            .onSubmit {
                guard let key = editableTextKey else { return }
                canvasManager.updateComponentProperty(for: component, key: key, value: textInput)
            }
            .help("Text Content")
    }

    private var fontSizeControlRow: some View {
        HStack(spacing: 8) {
            fontSizeIndicator(value: currentFontSizeValue)
            Text("Font Size")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            TextField(text: $textFontSizeInput, prompt: Text(verbatim: "17")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(width: 34)
                .onChange(of: textFontSizeInput) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        applyTypingFontSize(newValue)
                    }
                }
                .onSubmit {
                    setCustomFontSize(textFontSizeInput)
                }
            Text("px")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Divider().frame(height: 16)
            HStack(spacing: 0) {
                Button {
                    adjustFontSize(by: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                Divider().frame(height: 14)
                Button {
                    adjustFontSize(by: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
    }

    private var fontSizePresetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(fontSizePresets, id: \.key) { preset in
                    fontSizePresetChip(preset: preset)
                }
            }
        }
    }

    private func fontSizePresetChip(preset: (label: String, key: String, value: Double)) -> some View {
        let selected = resolvedFontPresetKey == preset.key
        return Text(preset.label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(selected ? .white : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selected ? Color.blue : Color.secondary.opacity(0.14))
            )
            .contentShape(Capsule())
            .onTapGesture {
                isTextInputFocused = false
                setFontSizePreset(preset.key)
            }
            .help("Font Size Preset")
    }

    private var resolvedFontPresetKey: String? {
        if fontSizePresets.contains(where: { $0.key == currentFontSizeToken }) {
            return currentFontSizeToken
        }
        let value = currentFontSizeValue
        return fontSizePresets.first(where: { abs($0.value - value) < 0.001 })?.key
    }

    private var fontStyleMenuRow: some View {
        HStack(spacing: 10) {
            compactMenuField(
                title: fontDesignLabel(for: currentFontDesign),
                options: ["Default", "Serif", "Rounded", "Monospaced"],
                helpText: "Font Design"
            ) { selected in
                let design = normalizeFontDesignSelection(selected)
                updateOrCreateModifier(.font) { mod in
                    mod.properties["fontDesign"] = design
                    if mod.properties["fontSize"] == nil { mod.properties["fontSize"] = "body" }
                    if mod.properties["fontWeight"] == nil { mod.properties["fontWeight"] = "regular" }
                }
            }

            compactMenuField(
                title: fontWeightLabel(for: currentFontWeight),
                options: ["UltraLight", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"],
                helpText: "Font Weight"
            ) { selected in
                let weight = normalizeFontWeightSelection(selected)
                updateOrCreateModifier(.font) { mod in
                    mod.properties["fontWeight"] = weight
                    if mod.properties["fontSize"] == nil { mod.properties["fontSize"] = "body" }
                    if mod.properties["fontDesign"] == nil { mod.properties["fontDesign"] = "default" }
                }
            }
        }
    }

    private var sfSymbolSection: some View {
        inspectorSection("Symbol", plus: nil, showActions: showComponentActions && editableTextKey == nil && hasSymbolProperty) {
            VStack(spacing: 10) {
                Button {
                    showSFSymbolPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: symbolInput.isEmpty ? "star" : symbolInput)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 22)

                        Text(symbolInput.isEmpty ? "star" : symbolInput)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(roundedFieldBackground)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("SF Symbol")

                fontSizeControlRow
                fontSizePresetRow
            }
        }
    }

    private var stackSection: some View {
        inspectorSection("Stack", plus: nil, showActions: showComponentActions && editableTextKey == nil && !hasSymbolProperty && component.type == .stack) {
            VStack(spacing: 10) {
                stackTypeSegmentedControl(selected: currentStackType)

                if let alignmentOptions {
                    alignmentSegmentedControl(options: alignmentOptions, selected: selectedAlignmentOption)
                }

                if currentStackType != "z" {
                    stackSpacingInlineField
                }
            }
        }
    }

    private var layoutSection: some View {
        let showLayoutActions =
            showComponentActions &&
            editableTextKey == nil &&
            !hasSymbolProperty &&
            component.type != .stack &&
            component.type != .image &&
            component.type != .scrollView &&
            component.type != .shape &&
            component.type != .button &&
            component.type != .toggle &&
            component.type != .slider &&
            component.type != .progressView &&
            component.type != .chart &&
            component.type != .gauge &&
            component.type != .textField

        return inspectorSection(
            "Layout",
            plus: nil,
            showActions: showLayoutActions
        ) {
            VStack(spacing: 10) {
                layoutFrameRow

                layoutPaddingRow

                layoutOffsetRow

                if component.type != .stack, let alignmentOptions {
                    alignmentSegmentedControl(options: alignmentOptions, selected: selectedAlignmentOption)
                        .help("Alignment")
                }

                layoutOpacityAndCornerRow
            }
        }
    }
    
    @ViewBuilder
    private var layoutFrameRow: some View {
        HStack(spacing: 10) {
            if isPhone {
                VStack(spacing: 8) {
                    mobileFrameSliderField(axis: "width")
                    mobileFrameSliderField(axis: "height")
                }
            } else {
                frameInlineField(axis: "width", text: $frameWidthInput)
                frameInlineField(axis: "height", text: $frameHeightInput)
            }
        }
    }
    
    @ViewBuilder
    private var layoutPaddingRow: some View {
        HStack(spacing: 10) {
            if isPhone {
                VStack(spacing: 8) {
                    mobileSliderField(
                        title: "H Padding",
                        systemImage: "arrow.left.and.right",
                        value: resolvedPaddingAmount(for: "horizontal"),
                        range: 0...64,
                        step: 1
                    ) { setPaddingAxis("horizontal", String($0), continuous: true) } onCommit: { value in
                        setPaddingAxis("horizontal", String(value), continuous: false)
                    } onDirectInput: {
                        numericInputText = String(Int(resolvedPaddingAmount(for: "horizontal").rounded()))
                        numericInputTarget = .paddingHorizontal
                    }
                    mobileSliderField(
                        title: "V Padding",
                        systemImage: "arrow.up.and.down",
                        value: resolvedPaddingAmount(for: "vertical"),
                        range: 0...64,
                        step: 1
                    ) { setPaddingAxis("vertical", String($0), continuous: true) } onCommit: { value in
                        setPaddingAxis("vertical", String(value), continuous: false)
                    } onDirectInput: {
                        numericInputText = String(Int(resolvedPaddingAmount(for: "vertical").rounded()))
                        numericInputTarget = .paddingVertical
                    }
                }
            } else {
                paddingAxisField(
                    symbol: "arrow.left.and.right",
                    text: $paddingHorizontalInput,
                    helpText: "Horizontal Padding"
                ) { committed in
                    setPaddingAxis("horizontal", committed)
                }
                paddingAxisField(
                    symbol: "arrow.up.and.down",
                    text: $paddingVerticalInput,
                    helpText: "Vertical Padding"
                ) { committed in
                    setPaddingAxis("vertical", committed)
                }
            }
        }
    }
    
    @ViewBuilder
    private var layoutOffsetRow: some View {
        HStack(spacing: 10) {
            if isPhone {
                VStack(spacing: 8) {
                    mobileSliderField(
                        title: "X Offset",
                        systemImage: "arrow.left.and.right",
                        value: currentOffsetX(),
                        range: -500...500,
                        step: 1
                    ) { value in
                        setOffsetAxis("x", String(value), continuous: true)
                    } onCommit: { value in
                        setOffsetAxis("x", String(value), continuous: false)
                    } onDirectInput: {
                        numericInputText = String(Int(currentOffsetX().rounded()))
                        numericInputTarget = .offsetX
                    }

                    mobileSliderField(
                        title: "Y Offset",
                        systemImage: "arrow.up.and.down",
                        value: currentOffsetY(),
                        range: -500...500,
                        step: 1
                    ) { value in
                        setOffsetAxis("y", String(value), continuous: true)
                    } onCommit: { value in
                        setOffsetAxis("y", String(value), continuous: false)
                    } onDirectInput: {
                        numericInputText = String(Int(currentOffsetY().rounded()))
                        numericInputTarget = .offsetY
                    }
                }
            } else {
                axisInputField(label: "X", text: $offsetXInput, helpText: "Offset X") { committed in
                    setOffsetAxis("x", committed)
                }
                axisInputField(label: "Y", text: $offsetYInput, helpText: "Offset Y") { committed in
                    setOffsetAxis("y", committed)
                }
            }
        }
    }
    
    @ViewBuilder
    private var layoutOpacityAndCornerRow: some View {
        HStack(spacing: 10) {
            if isPhone {
                VStack(spacing: 8) {
                    mobileSliderField(
                        title: "Opacity",
                        systemImage: "app.translucent",
                        value: currentUniversalOpacity() * 100.0,
                        range: 0...100,
                        step: 1
                    ) { setUniversalOpacity($0 / 100.0, continuous: true) } onCommit: { value in
                        setUniversalOpacity(value / 100.0, continuous: false)
                    } onDirectInput: {
                        numericInputText = String(Int((currentUniversalOpacity() * 100.0).rounded()))
                        numericInputTarget = .opacity
                    }
                    mobileSliderField(
                        title: "Corner Radius",
                        systemImage: "button.roundedtop.horizontal",
                        value: Double(cornerRadiusInput) ?? 0,
                        range: 0...100,
                        step: 1
                    ) { setCornerRadius(String($0), continuous: true) } onCommit: { value in
                        setCornerRadius(String(value), continuous: false)
                    } onDirectInput: {
                        numericInputText = cornerRadiusInput
                        numericInputTarget = .cornerRadius
                    }
                }
            } else {
                iconPercentInputField(symbol: "app.translucent", text: $objectOpacityInput, helpText: "Object Opacity") { percent in
                    setUniversalOpacity(percent / 100.0)
                }
                iconDegreeInputField(symbol: "rotate.right", text: $rotationInput, helpText: "Rotation") { committed in
                    setRotation(committed)
                }
                iconPxInputField(symbol: "button.roundedtop.horizontal", text: $cornerRadiusInput, helpText: "Corner Radius", scrubId: "modifier-corner-radius", scrubRange: 0...100) { committed in
                    setCornerRadius(committed)
                }
            }
        }
    }

    private var effectGroupsSection: some View {
        VStack(spacing: 10) {
            fillsGroup
            bordersGroup
            effectsGroup
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bordersGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupRow("Borders", type: .border, menuTypes: [.border, .stroke])

            ForEach(borderModifiers) { border in
                HStack(spacing: 10) {
                    Button {
                        canvasManager.removeModifier(from: component, modifier: border)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.secondary.opacity(0.16)))
                    }
                    .buttonStyle(.plain)

                    Button {
#if os(macOS)
                        macFillPopoverModifierId = border.id
#else
                        colorEditorModifierId = border.id
                        colorEditorTitle = border.type == .stroke ? "Stroke Color" : "Border Color"
                        showColorEditor = true
#endif
                    } label: {
                        Circle()
                            .fill(colorFromToken(borderColorToken(for: border)))
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.primary.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
#if os(macOS)
                    .popover(
                        isPresented: Binding(
                            get: { macFillPopoverModifierId == border.id },
                            set: { isPresented in
                                if !isPresented, macFillPopoverModifierId == border.id {
                                    macFillPopoverModifierId = nil
                                }
                            }
                        ),
                        arrowEdge: .trailing
                    ) {
                        ColorModifierEditor(
                            modifier: Binding(
                                get: { component.modifiers.first(where: { $0.id == border.id }) ?? border },
                                set: { newModifier in
                                    DispatchQueue.main.async {
                                        canvasManager.updateModifier(for: component, modifier: newModifier)
                                    }
                                }
                            ),
                            component: component,
                            title: border.type == .stroke ? "Stroke Color" : "Border Color"
                        )
                        .padding(8)
                    }
#endif

                    borderOpacityEditor(for: border)
                    borderWidthEditor(for: border)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fillsGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupRow("Fills", type: .fill, menuTypes: [.fill, .foregroundColor, .backgroundColor, .tint])

            ForEach(fillModifiers) { fill in
                fillRow(for: fill)
                .padding(.vertical, 2)
            }
        }
    }

    private func fillRow(for fill: ComponentModifier) -> some View {
        HStack(spacing: 10) {
            removeFillButton(for: fill)
            fillEditorButton(for: fill)

            if !hasGradientFill(fill) {
                fillHexEditor(for: fill)
                fillOpacityEditor(for: fill)
            } else {
                Spacer(minLength: 0)
            }
        }
    }

    private func removeFillButton(for fill: ComponentModifier) -> some View {
        Button {
            canvasManager.removeModifier(from: component, modifier: fill)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.secondary.opacity(0.16)))
        }
        .buttonStyle(.plain)
    }

    private func fillEditorButton(for fill: ComponentModifier) -> some View {
        let title = fillEditorTitle(for: fill)

        return Button {
#if os(macOS)
            macFillPopoverModifierId = fill.id
#else
            colorEditorModifierId = fill.id
            colorEditorTitle = title
            showColorEditor = true
#endif
        } label: {
            fillPreviewSwatch(for: fill)
        }
        .buttonStyle(.plain)
#if os(macOS)
        .popover(
            isPresented: Binding(
                get: { macFillPopoverModifierId == fill.id },
                set: { isPresented in
                    if !isPresented, macFillPopoverModifierId == fill.id {
                        macFillPopoverModifierId = nil
                    }
                }
            ),
            arrowEdge: .trailing
        ) {
            ColorModifierEditor(
                modifier: Binding(
                    get: {
                        component.modifiers.first(where: { $0.id == fill.id }) ?? fill
                    },
                    set: { newModifier in
                        DispatchQueue.main.async {
                            canvasManager.updateModifier(for: component, modifier: newModifier)
                        }
                    }
                ),
                component: component,
                title: title
            )
            .padding(8)
        }
#endif
    }

    private func fillEditorTitle(for fill: ComponentModifier) -> String {
        switch fill.type {
        case .fill:
            return "Fill Color"
        case .foregroundColor:
            return "Foreground Color"
        case .backgroundColor:
            return "Background Color"
        case .tint:
            return "Tint"
        default:
            return "Color"
        }
    }

    @ViewBuilder
    private func fillPreviewSwatch(for modifier: ComponentModifier) -> some View {
        if let gradient = modifier.getGradient(key: "gradient") {
            Circle()
                .fill(gradient)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.primary.opacity(0.35), lineWidth: 1))
        } else {
            Circle()
                .fill(colorFromToken(fillColorToken(for: modifier)))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.primary.opacity(0.35), lineWidth: 1))
        }
    }

    private func hasGradientFill(_ modifier: ComponentModifier) -> Bool {
        modifier.getGradient(key: "gradient") != nil
    }

    private func fillGradientData(for modifier: ComponentModifier) -> [String: Any]? {
        modifier.properties["gradient"] as? [String: Any]
    }

    private func fillColorToken(for modifier: ComponentModifier) -> String {
        (modifier.properties["color"] as? String) ?? "white:1.0"
    }

    private func fillHexText(for modifier: ComponentModifier) -> String {
        colorHexText(forToken: fillColorToken(for: modifier))
    }

    private func colorHexText(forToken token: String) -> String {
        let baseRaw = token.split(separator: ":").first.map(String.init) ?? "white"
        let base = baseRaw.lowercased()

        if baseRaw.hasPrefix("#") {
            return baseRaw.replacingOccurrences(of: "#", with: "").uppercased()
        }

        let map: [String: String] = [
            "white": "FFFFFF",
            "black": "000000",
            "gray": "808080",
            "red": "FF3B30",
            "orange": "FF9500",
            "yellow": "FFCC00",
            "green": "34C759",
            "mint": "00C7BE",
            "teal": "30B0C7",
            "cyan": "32ADE6",
            "blue": "007AFF",
            "indigo": "5856D6",
            "purple": "AF52DE",
            "pink": "FF2D55",
            "brown": "A2845E",
            "primary": "FFFFFF",
            "secondary": "999999"
        ]
        return map[base] ?? "FFFFFF"
    }

    private func fillOpacityPercent(for modifier: ComponentModifier) -> Int {
        let token = fillColorToken(for: modifier)
        let part = token.split(separator: ":").dropFirst().first.map(String.init) ?? "1.0"
        let opacity = max(0, min(1, Double(part) ?? 1.0))
        return Int((opacity * 100).rounded())
    }

    private func fillHexEditor(for fill: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: "#")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(
                "",
                text: Binding(
                    get: { fillHexInputs[fill.id] ?? fillHexText(for: fill) },
                    set: { newValue in
                        let sanitized = sanitizeHexInput(newValue)
                        fillHexInputs[fill.id] = sanitized
                        if sanitized.count == 6 {
                            updateFillHex(fill, hex: sanitized, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .focused($focusedFillField, equals: .hex(fill.id))
            .onSubmit {
                let sanitized = sanitizeHexInput(fillHexInputs[fill.id] ?? "")
                guard sanitized.count == 6 else {
                    fillHexInputs[fill.id] = fillHexText(for: fill)
                    return
                }
                updateFillHex(fill, hex: sanitized, continuous: false)
                fillHexInputs[fill.id] = sanitized
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func fillOpacityEditor(for fill: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            TextField(
                "",
                text: Binding(
                    get: { fillOpacityInputs[fill.id] ?? String(fillOpacityPercent(for: fill)) },
                    set: { newValue in
                        let sanitized = sanitizeOpacityInput(newValue)
                        fillOpacityInputs[fill.id] = sanitized
                        if let percent = Double(sanitized) {
                            updateFillOpacity(fill, percent: percent, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .focused($focusedFillField, equals: .opacity(fill.id))
            .onSubmit {
                let sanitized = sanitizeOpacityInput(fillOpacityInputs[fill.id] ?? "")
                let percent = Double(sanitized) ?? Double(fillOpacityPercent(for: fill))
                updateFillOpacity(fill, percent: percent, continuous: false)
                fillOpacityInputs[fill.id] = String(Int(max(0, min(100, percent)).rounded()))
            }
            Text(verbatim: "%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func syncFillInputs() {
        let ids = Set(fillModifiers.map(\.id))
        fillHexInputs = fillHexInputs.filter { ids.contains($0.key) }
        fillOpacityInputs = fillOpacityInputs.filter { ids.contains($0.key) }

        for fill in fillModifiers {
            if focusedFillField != .hex(fill.id) {
                fillHexInputs[fill.id] = fillHexText(for: fill)
            }
            if focusedFillField != .opacity(fill.id) {
                fillOpacityInputs[fill.id] = String(fillOpacityPercent(for: fill))
            }
        }
    }

    private func borderColorToken(for modifier: ComponentModifier) -> String {
        let raw = (modifier.properties["color"] as? String) ?? "primary:1.0"
        return raw.hasPrefix("color:") ? String(raw.dropFirst(6)) : raw
    }

    private func borderWidthValue(for modifier: ComponentModifier) -> Double {
        if modifier.type == .stroke {
            return modifier.getDouble(key: "lineWidth", defaultValue: 1.0)
        }
        return modifier.getDouble(key: "width", defaultValue: 1.0)
    }

    private func borderHexText(for modifier: ComponentModifier) -> String {
        colorHexText(forToken: borderColorToken(for: modifier))
    }

    private func borderOpacityPercent(for modifier: ComponentModifier) -> Int {
        let token = borderColorToken(for: modifier)
        let part = token.split(separator: ":").dropFirst().first.map(String.init) ?? "1.0"
        let opacity = max(0, min(1, Double(part) ?? 1.0))
        return Int((opacity * 100).rounded())
    }

    private func borderHexEditor(for border: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: "#")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(
                "",
                text: Binding(
                    get: { borderHexInputs[border.id] ?? borderHexText(for: border) },
                    set: { newValue in
                        let sanitized = sanitizeHexInput(newValue)
                        borderHexInputs[border.id] = sanitized
                        if sanitized.count == 6 {
                            updateBorderHex(border, hex: sanitized, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .focused($focusedBorderColorField, equals: .hex(border.id))
            .onSubmit {
                let sanitized = sanitizeHexInput(borderHexInputs[border.id] ?? "")
                guard sanitized.count == 6 else {
                    borderHexInputs[border.id] = borderHexText(for: border)
                    return
                }
                updateBorderHex(border, hex: sanitized, continuous: false)
                borderHexInputs[border.id] = sanitized
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func borderOpacityEditor(for border: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "app.translucent")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 14)

            TextField(
                "",
                text: Binding(
                    get: { borderOpacityInputs[border.id] ?? String(borderOpacityPercent(for: border)) },
                    set: { newValue in
                        let sanitized = sanitizeOpacityInput(newValue)
                        borderOpacityInputs[border.id] = sanitized
                        if let percent = Double(sanitized) {
                            updateBorderOpacity(border, percent: percent, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .focused($focusedBorderColorField, equals: .opacity(border.id))
            .onSubmit {
                let sanitized = sanitizeOpacityInput(borderOpacityInputs[border.id] ?? "")
                let percent = Double(sanitized) ?? Double(borderOpacityPercent(for: border))
                updateBorderOpacity(border, percent: percent, continuous: false)
                borderOpacityInputs[border.id] = String(Int(max(0, min(100, percent)).rounded()))
            }
            Text(verbatim: "%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func borderWidthEditor(for border: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lineweight")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 14)

            TextField(
                "",
                text: Binding(
                    get: { borderWidthInputs[border.id] ?? String(Int(borderWidthValue(for: border).rounded())) },
                    set: { newValue in
                        let cleaned = newValue
                            .replacingOccurrences(of: "px", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        borderWidthInputs[border.id] = cleaned
                        if let value = Double(cleaned) {
                            updateBorderWidth(border, width: value, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .focused($focusedBorderWidthId, equals: border.id)
            .onSubmit {
                let cleaned = (borderWidthInputs[border.id] ?? "")
                    .replacingOccurrences(of: "px", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let value = Double(cleaned) ?? borderWidthValue(for: border)
                updateBorderWidth(border, width: value, continuous: false)
                borderWidthInputs[border.id] = String(Int(max(0, value).rounded()))
            }
            Text("px")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func updateBorderWidth(_ border: ComponentModifier, width: Double, continuous: Bool) {
        guard var updated = component.modifiers.first(where: { $0.id == border.id }) else { return }
        let clamped = max(0, width)
        if border.type == .stroke {
            updated.properties["lineWidth"] = clamped
        } else {
            updated.properties["width"] = clamped
        }

        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func currentBorderOpacity(_ border: ComponentModifier) -> Double {
        let current = component.modifiers.first(where: { $0.id == border.id }) ?? border
        let token = borderColorToken(for: current)
        let opacityPart = token.split(separator: ":").dropFirst().first.map(String.init) ?? "1.0"
        return max(0, min(1, Double(opacityPart) ?? 1.0))
    }

    private func updateBorderHex(_ border: ComponentModifier, hex: String, continuous: Bool) {
        guard hex.count == 6, var updated = component.modifiers.first(where: { $0.id == border.id }) else { return }
        let opacity = currentBorderOpacity(border)
        updated.properties["color"] = String(format: "#%@:%.2f", hex.uppercased(), opacity)
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func updateBorderOpacity(_ border: ComponentModifier, percent: Double, continuous: Bool) {
        guard var updated = component.modifiers.first(where: { $0.id == border.id }) else { return }
        let clampedPercent = max(0, min(100, percent))
        let normalizedOpacity = clampedPercent / 100.0
        let currentToken = borderColorToken(for: updated)
        let base = currentToken.split(separator: ":").first.map(String.init) ?? "white"
        updated.properties["color"] = String(format: "%@:%.2f", base, normalizedOpacity)
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func syncBorderInputs() {
        let ids = Set(borderModifiers.map(\.id))
        borderHexInputs = borderHexInputs.filter { ids.contains($0.key) }
        borderOpacityInputs = borderOpacityInputs.filter { ids.contains($0.key) }
        borderWidthInputs = borderWidthInputs.filter { ids.contains($0.key) }

        for border in borderModifiers {
            if focusedBorderColorField != .hex(border.id) {
                borderHexInputs[border.id] = borderHexText(for: border)
            }
            if focusedBorderColorField != .opacity(border.id) {
                borderOpacityInputs[border.id] = String(borderOpacityPercent(for: border))
            }
            if focusedBorderWidthId != border.id {
                borderWidthInputs[border.id] = String(Int(borderWidthValue(for: border).rounded()))
            }
        }
    }

    private func sanitizeHexInput(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
            .filter { $0.isHexDigit }
            .prefix(6)
            .description
    }

    private func sanitizeOpacityInput(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        guard let value = Int(digits) else { return "" }
        return String(max(0, min(100, value)))
    }

    private func sanitizeSignedNumberInput(_ raw: String) -> String {
        let trimmed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "px", with: "")
        guard !trimmed.isEmpty else { return "" }
        let isNegative = trimmed.hasPrefix("-")
        let digits = trimmed.filter { $0.isNumber }
        if digits.isEmpty { return isNegative ? "-" : "" }
        return isNegative ? "-\(digits)" : digits
    }

    private func shadowColorToken(for effect: ComponentModifier) -> String {
        let raw = (effect.properties["color"] as? String) ?? "black"
        return raw.hasPrefix("color:") ? String(raw.dropFirst(6)) : raw
    }

    private func currentShadowOpacity(for effect: ComponentModifier) -> Double {
        let current = component.modifiers.first(where: { $0.id == effect.id }) ?? effect
        if let opacity = current.properties["opacity"] as? Double {
            return max(0, min(1, opacity))
        }
        if let opacity = current.properties["opacity"] as? Int {
            return max(0, min(1, Double(opacity)))
        }
        return 0.3
    }

    private func currentShadowRadius(for effect: ComponentModifier) -> Double {
        let current = component.modifiers.first(where: { $0.id == effect.id }) ?? effect
        if let radius = current.properties["radius"] as? Double { return radius }
        if let radius = current.properties["radius"] as? Int { return Double(radius) }
        return 2
    }

    private func currentShadowX(for effect: ComponentModifier) -> Double {
        let current = component.modifiers.first(where: { $0.id == effect.id }) ?? effect
        if let value = current.properties["offsetX"] as? Double { return value }
        if let value = current.properties["offsetX"] as? Int { return Double(value) }
        if let value = current.properties["x"] as? Double { return value }
        if let value = current.properties["x"] as? Int { return Double(value) }
        return 0
    }

    private func currentShadowY(for effect: ComponentModifier) -> Double {
        let current = component.modifiers.first(where: { $0.id == effect.id }) ?? effect
        if let value = current.properties["offsetY"] as? Double { return value }
        if let value = current.properties["offsetY"] as? Int { return Double(value) }
        if let value = current.properties["y"] as? Double { return value }
        if let value = current.properties["y"] as? Int { return Double(value) }
        return 2
    }

    private func updateShadowHex(_ effect: ComponentModifier, hex: String, continuous: Bool) {
        guard hex.count == 6, var updated = component.modifiers.first(where: { $0.id == effect.id }) else { return }
        updated.properties["color"] = "#\(hex.uppercased())"
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func updateShadowOpacity(_ effect: ComponentModifier, percent: Double, continuous: Bool) {
        guard var updated = component.modifiers.first(where: { $0.id == effect.id }) else { return }
        updated.properties["opacity"] = max(0, min(1, percent / 100.0))
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func updateShadowRadius(_ effect: ComponentModifier, value: Double, continuous: Bool) {
        guard var updated = component.modifiers.first(where: { $0.id == effect.id }) else { return }
        updated.properties["radius"] = max(0, value)
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func updateShadowOffset(_ effect: ComponentModifier, x: Double, y: Double, continuous: Bool) {
        guard var updated = component.modifiers.first(where: { $0.id == effect.id }) else { return }
        updated.properties["offsetX"] = x
        updated.properties["x"] = x
        updated.properties["offsetY"] = y
        updated.properties["y"] = y
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func syncShadowInputs() {
        let shadowEffects = effectModifiers.filter { $0.type == .shadow }
        let ids = Set(shadowEffects.map(\.id))
        shadowHexInputs = shadowHexInputs.filter { ids.contains($0.key) }
        shadowOpacityInputs = shadowOpacityInputs.filter { ids.contains($0.key) }
        shadowRadiusInputs = shadowRadiusInputs.filter { ids.contains($0.key) }
        shadowXInputs = shadowXInputs.filter { ids.contains($0.key) }
        shadowYInputs = shadowYInputs.filter { ids.contains($0.key) }

        for effect in shadowEffects {
            if focusedShadowColorField != .hex(effect.id) {
                shadowHexInputs[effect.id] = colorHexText(forToken: shadowColorToken(for: effect))
            }
            if focusedShadowColorField != .opacity(effect.id) {
                shadowOpacityInputs[effect.id] = String(Int((currentShadowOpacity(for: effect) * 100).rounded()))
            }
            if focusedShadowNumericField != .radius(effect.id) {
                shadowRadiusInputs[effect.id] = String(Int(currentShadowRadius(for: effect).rounded()))
            }
            if focusedShadowNumericField != .x(effect.id) {
                shadowXInputs[effect.id] = String(Int(currentShadowX(for: effect).rounded()))
            }
            if focusedShadowNumericField != .y(effect.id) {
                shadowYInputs[effect.id] = String(Int(currentShadowY(for: effect).rounded()))
            }
        }
    }

    private func currentFillModifier(_ fill: ComponentModifier) -> ComponentModifier? {
        component.modifiers.first(where: { $0.id == fill.id })
    }

    private func currentFillOpacity(_ fill: ComponentModifier) -> Double {
        let current = currentFillModifier(fill) ?? fill
        let token = fillColorToken(for: current)
        let opacityPart = token.split(separator: ":").dropFirst().first.map(String.init) ?? "1.0"
        return max(0, min(1, Double(opacityPart) ?? 1.0))
    }

    private func updateFillHex(_ fill: ComponentModifier, hex: String, continuous: Bool) {
        guard hex.count == 6, var updated = currentFillModifier(fill) else { return }
        let opacity = currentFillOpacity(fill)
        updated.properties["color"] = String(format: "#%@:%.2f", hex.uppercased(), opacity)
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private func updateFillOpacity(_ fill: ComponentModifier, percent: Double, continuous: Bool) {
        guard var updated = currentFillModifier(fill) else { return }
        let clampedPercent = max(0, min(100, percent))
        let normalizedOpacity = clampedPercent / 100.0
        let currentToken = fillColorToken(for: updated)
        let base = currentToken.split(separator: ":").first.map(String.init) ?? "white"
        updated.properties["color"] = String(format: "%@:%.2f", base, normalizedOpacity)
        if continuous {
            canvasManager.updateModifierContinuous(for: component, modifier: updated)
        } else {
            canvasManager.updateModifier(for: component, modifier: updated)
        }
    }

    private var effectsGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupRow("Effects", type: .glassEffect, menuTypes: [.glassEffect, .shadow, .blur, .clipShape])

            ForEach(effectModifiers) { effect in
                effectRow(for: effect)
            }
        }
    }

    @ViewBuilder
    private func effectRow(for effect: ComponentModifier) -> some View {
        if effect.type == .blur {
            blurInlineControl(for: effect)
                .padding(.vertical, 2)
        } else if effect.type == .shadow {
            shadowInlineControls(for: effect)
                .padding(.vertical, 2)
        } else if effect.type == .clipShape {
            clipShapeInlineControl(for: effect)
                .padding(.vertical, 2)
        } else {
            defaultEffectRow(for: effect)
                .padding(.vertical, 2)
        }
    }

    private func defaultEffectRow(for effect: ComponentModifier) -> some View {
        VStack(alignment: .leading, spacing: effect.type == .glassEffect ? 0 : 8) {
            effectHeaderRow(for: effect)
            if effect.type != .glassEffect {
                effectInlineControls(for: effect)
            }
        }
    }

    @ViewBuilder
    private func effectHeaderRow(for effect: ComponentModifier) -> some View {
        HStack(spacing: 10) {
            Button {
                canvasManager.removeModifier(from: component, modifier: effect)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.secondary.opacity(0.16)))
            }
            .buttonStyle(.plain)

            if effect.type == .glassEffect {
                glassEffectHeaderControls(for: effect)
            } else {
                Button {
                    // Effects are inline-editable in the panel.
                } label: {
                    Image(systemName: effect.type.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.14))
                        )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func glassEffectHeaderControls(for effect: ComponentModifier) -> some View {
        let selectedShape = (effect.properties["shape"] as? String) ?? "Default"

        Image(systemName: effect.type.icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.primary)

        compactMenuField(
            title: glassShapeDisplayName(selectedShape),
            options: ["Default", "Rect", "Rounded", "Circle", "Capsule", "Ellipse"]
        ) { selectedDisplay in
            let selected = glassShapeStorageName(selectedDisplay)
            updateEffectModifier(effect) { mod in
                if selected == "Default" {
                    mod.properties.removeValue(forKey: "shape")
                    mod.properties.removeValue(forKey: "shapeType")
                    mod.properties.removeValue(forKey: "cornerRadius")
                } else {
                    mod.properties["shape"] = selected
                    if selected == "RoundedRectangle" {
                        if mod.properties["cornerRadius"] == nil { mod.properties["cornerRadius"] = 10.0 }
                    } else {
                        mod.properties.removeValue(forKey: "cornerRadius")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)

        if selectedShape == "RoundedRectangle" {
            iconPxInputField(
                symbol: "button.roundedtop.horizontal",
                text: Binding(
                    get: {
                        let radius = currentGlassEffectCornerRadius(for: effect)
                        return String(Int(max(0, radius).rounded()))
                    },
                    set: { newValue in
                        guard isParsableNumberInput(newValue) else { return }
                        let parsed = max(0, Double(newValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10)
                        updateEffectModifierContinuous(effect) { mod in
                            mod.properties["cornerRadius"] = parsed
                        }
                    }
                ),
                helpText: "Corner Radius",
                scrubId: "glass-corner-radius-\(effect.id.uuidString)",
                scrubRange: 0...100
            ) { committed in
                let parsed = max(0, Double(committed.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10)
                updateEffectModifier(effect) { mod in
                    mod.properties["cornerRadius"] = parsed
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func clipShapeInlineControl(for effect: ComponentModifier) -> some View {
        let selectedShape = (effect.properties["shape"] as? String) ?? "Rectangle"

        return HStack(spacing: 10) {
            Button {
                canvasManager.removeModifier(from: component, modifier: effect)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.secondary.opacity(0.16)))
            }
            .buttonStyle(.plain)

            compactMenuField(
                title: selectedShape,
                options: ["Rectangle", "RoundedRectangle", "Circle", "Capsule", "Ellipse"]
            ) { selected in
                updateEffectModifier(effect) { mod in
                    mod.properties["shape"] = selected
                    if selected != "RoundedRectangle" {
                        mod.properties.removeValue(forKey: "cornerRadius")
                    } else if mod.properties["cornerRadius"] == nil {
                        mod.properties["cornerRadius"] = 10.0
                    }
                }
            }

            if selectedShape == "RoundedRectangle" {
                iconPxInputField(
                    symbol: "button.roundedtop.horizontal",
                    text: Binding(
                        get: {
                            let radius = currentClipShapeCornerRadius(for: effect)
                            return String(Int(max(0, radius).rounded()))
                        },
                        set: { newValue in
                            guard isParsableNumberInput(newValue) else { return }
                            let parsed = max(0, Double(newValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10)
                            updateEffectModifierContinuous(effect) { mod in
                                mod.properties["cornerRadius"] = parsed
                            }
                        }
                    ),
                    helpText: "Corner Radius",
                    scrubId: "clip-corner-radius-\(effect.id.uuidString)",
                    scrubRange: 0...100
                ) { committed in
                    let parsed = max(0, Double(committed.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10)
                    updateEffectModifier(effect) { mod in
                        mod.properties["cornerRadius"] = parsed
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func effectInlineControls(for effect: ComponentModifier) -> some View {
        switch effect.type {
        case .blur:
            blurInlineControl(for: effect)
        case .shadow:
            shadowInlineControls(for: effect)
        case .clipShape:
            HStack(spacing: 8) {
                Text("Shape")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                compactMenuField(
                    title: (effect.properties["shape"] as? String) ?? "Rectangle",
                    options: ["Rectangle", "RoundedRectangle", "Circle", "Capsule", "Ellipse"]
                ) { selected in
                    updateEffectModifier(effect) { mod in
                        mod.properties["shape"] = selected
                        if selected != "RoundedRectangle" {
                            mod.properties.removeValue(forKey: "cornerRadius")
                        } else if mod.properties["cornerRadius"] == nil {
                            mod.properties["cornerRadius"] = 10.0
                        }
                    }
                }
            }
        case .glassEffect:
            EmptyView()
        default:
            EmptyView()
        }
    }

    private func shadowInlineControls(for effect: ComponentModifier) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            shadowColorControlsRow(for: effect)
            shadowValueControls(for: effect)
        }
    }
    
    @ViewBuilder
    private func shadowColorControlsRow(for effect: ComponentModifier) -> some View {
        HStack(spacing: 10) {
            Button {
                canvasManager.removeModifier(from: component, modifier: effect)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.secondary.opacity(0.16)))
            }
            .buttonStyle(.plain)

            Button {
#if os(macOS)
                macFillPopoverModifierId = effect.id
#else
                colorEditorModifierId = effect.id
                colorEditorTitle = "Shadow Color"
                showColorEditor = true
#endif
            } label: {
                Circle()
                    .fill(colorFromToken(shadowColorToken(for: effect)))
                    .opacity(currentShadowOpacity(for: effect))
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.primary.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
#if os(macOS)
            .popover(
                isPresented: Binding(
                    get: { macFillPopoverModifierId == effect.id },
                    set: { isPresented in
                        if !isPresented, macFillPopoverModifierId == effect.id {
                            macFillPopoverModifierId = nil
                        }
                    }
                ),
                arrowEdge: .trailing
            ) {
                ColorModifierEditor(
                    modifier: Binding(
                        get: { component.modifiers.first(where: { $0.id == effect.id }) ?? effect },
                        set: { newModifier in
                            DispatchQueue.main.async {
                                canvasManager.updateModifier(for: component, modifier: newModifier)
                            }
                        }
                    ),
                    component: component,
                    title: "Shadow Color"
                )
                .padding(8)
            }
#endif

            shadowHexEditor(for: effect)
            shadowOpacityEditor(for: effect)
        }
    }
    
    @ViewBuilder
    private func shadowValueControls(for effect: ComponentModifier) -> some View {
        HStack(spacing: 8) {
            if isPhone {
                shadowValueControlsPhone(for: effect)
            } else {
                shadowValueControlsDesktop(for: effect)
            }
        }
    }
    
    private func shadowValueControlsPhone(for effect: ComponentModifier) -> some View {
        VStack(spacing: 8) {
            mobileSliderField(
                title: "Shadow Radius",
                systemImage: "smallcircle.filled.circle",
                value: currentShadowRadius(for: effect),
                range: 0...40,
                step: 1
            ) { updateShadowRadius(effect, value: max(0, $0), continuous: true) } onCommit: { value in
                updateShadowRadius(effect, value: max(0, value), continuous: false)
            } onDirectInput: {
                numericInputText = String(Int(currentShadowRadius(for: effect).rounded()))
                numericInputTarget = .shadowRadius(effect.id)
            }
            mobileSliderField(
                title: "Shadow X",
                systemImage: "arrow.left.and.right",
                value: currentShadowX(for: effect),
                range: -100...100,
                step: 1
            ) { updateShadowOffset(effect, x: $0, y: currentShadowY(for: effect), continuous: true) } onCommit: { value in
                updateShadowOffset(effect, x: value, y: currentShadowY(for: effect), continuous: false)
            } onDirectInput: {
                numericInputText = String(Int(currentShadowX(for: effect).rounded()))
                numericInputTarget = .shadowX(effect.id)
            }
            mobileSliderField(
                title: "Shadow Y",
                systemImage: "arrow.up.and.down",
                value: currentShadowY(for: effect),
                range: -100...100,
                step: 1
            ) { updateShadowOffset(effect, x: currentShadowX(for: effect), y: $0, continuous: true) } onCommit: { value in
                updateShadowOffset(effect, x: currentShadowX(for: effect), y: value, continuous: false)
            } onDirectInput: {
                numericInputText = String(Int(currentShadowY(for: effect).rounded()))
                numericInputTarget = .shadowY(effect.id)
            }
        }
    }
    
    private func shadowValueControlsDesktop(for effect: ComponentModifier) -> some View {
        Group {
            shadowNumberEditor(for: effect, label: "R", text: Binding(
                get: { shadowRadiusInputs[effect.id] ?? String(Int(currentShadowRadius(for: effect).rounded())) },
                set: { newValue in
                    let sanitized = sanitizeSignedNumberInput(newValue)
                    shadowRadiusInputs[effect.id] = sanitized
                    if let value = Double(sanitized) {
                        updateShadowRadius(effect, value: max(0, value), continuous: true)
                    }
                }
            ), focus: .radius(effect.id)) {
                let sanitized = sanitizeSignedNumberInput(shadowRadiusInputs[effect.id] ?? "")
                let value = Double(sanitized) ?? currentShadowRadius(for: effect)
                updateShadowRadius(effect, value: max(0, value), continuous: false)
                shadowRadiusInputs[effect.id] = String(Int(max(0, value).rounded()))
            }

            shadowNumberEditor(for: effect, label: "X", text: Binding(
                get: { shadowXInputs[effect.id] ?? String(Int(currentShadowX(for: effect).rounded())) },
                set: { newValue in
                    let sanitized = sanitizeSignedNumberInput(newValue)
                    shadowXInputs[effect.id] = sanitized
                    if let value = Double(sanitized) {
                        updateShadowOffset(effect, x: value, y: currentShadowY(for: effect), continuous: true)
                    }
                }
            ), focus: .x(effect.id)) {
                let sanitized = sanitizeSignedNumberInput(shadowXInputs[effect.id] ?? "")
                let value = Double(sanitized) ?? currentShadowX(for: effect)
                updateShadowOffset(effect, x: value, y: currentShadowY(for: effect), continuous: false)
                shadowXInputs[effect.id] = String(Int(value.rounded()))
            }

            shadowNumberEditor(for: effect, label: "Y", text: Binding(
                get: { shadowYInputs[effect.id] ?? String(Int(currentShadowY(for: effect).rounded())) },
                set: { newValue in
                    let sanitized = sanitizeSignedNumberInput(newValue)
                    shadowYInputs[effect.id] = sanitized
                    if let value = Double(sanitized) {
                        updateShadowOffset(effect, x: currentShadowX(for: effect), y: value, continuous: true)
                    }
                }
            ), focus: .y(effect.id)) {
                let sanitized = sanitizeSignedNumberInput(shadowYInputs[effect.id] ?? "")
                let value = Double(sanitized) ?? currentShadowY(for: effect)
                updateShadowOffset(effect, x: currentShadowX(for: effect), y: value, continuous: false)
                shadowYInputs[effect.id] = String(Int(value.rounded()))
            }
        }
    }

    private func shadowHexEditor(for effect: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: "#")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(
                "",
                text: Binding(
                    get: { shadowHexInputs[effect.id] ?? colorHexText(forToken: shadowColorToken(for: effect)) },
                    set: { newValue in
                        let sanitized = sanitizeHexInput(newValue)
                        shadowHexInputs[effect.id] = sanitized
                        if sanitized.count == 6 {
                            updateShadowHex(effect, hex: sanitized, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .focused($focusedShadowColorField, equals: .hex(effect.id))
            .onSubmit {
                let sanitized = sanitizeHexInput(shadowHexInputs[effect.id] ?? "")
                guard sanitized.count == 6 else {
                    shadowHexInputs[effect.id] = colorHexText(forToken: shadowColorToken(for: effect))
                    return
                }
                updateShadowHex(effect, hex: sanitized, continuous: false)
                shadowHexInputs[effect.id] = sanitized
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func shadowOpacityEditor(for effect: ComponentModifier) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "app.translucent")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 14)

            TextField(
                "",
                text: Binding(
                    get: { shadowOpacityInputs[effect.id] ?? String(Int((currentShadowOpacity(for: effect) * 100).rounded())) },
                    set: { newValue in
                        let sanitized = sanitizeOpacityInput(newValue)
                        shadowOpacityInputs[effect.id] = sanitized
                        if let percent = Double(sanitized) {
                            updateShadowOpacity(effect, percent: percent, continuous: true)
                        }
                    }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .focused($focusedShadowColorField, equals: .opacity(effect.id))
            .onSubmit {
                let sanitized = sanitizeOpacityInput(shadowOpacityInputs[effect.id] ?? "")
                let percent = Double(sanitized) ?? Double((currentShadowOpacity(for: effect) * 100).rounded())
                updateShadowOpacity(effect, percent: percent, continuous: false)
                shadowOpacityInputs[effect.id] = String(Int(max(0, min(100, percent)).rounded()))
            }
            Text(verbatim: "%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func shadowNumberEditor(
        for effect: ComponentModifier,
        label: String,
        text: Binding<String>,
        focus: ShadowNumericFocus,
        onSubmit: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(text: text) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .focused($focusedShadowNumericField, equals: focus)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
    }

    private func updateEffectModifier(_ effect: ComponentModifier, mutate: @escaping (inout ComponentModifier) -> Void) {
        guard var latest = component.modifiers.first(where: { $0.id == effect.id }) else { return }
        mutate(&latest)
        canvasManager.updateModifier(for: component, modifier: latest)
    }

    private func updateEffectModifierContinuous(_ effect: ComponentModifier, mutate: @escaping (inout ComponentModifier) -> Void) {
        guard var latest = component.modifiers.first(where: { $0.id == effect.id }) else { return }
        mutate(&latest)
        canvasManager.updateModifierContinuous(for: component, modifier: latest)
    }

    private func currentBlurRadius(for effect: ComponentModifier) -> Double {
        if let latest = component.modifiers.first(where: { $0.id == effect.id }) {
            if let v = latest.properties["radius"] as? Double { return v }
            if let v = latest.properties["radius"] as? Int { return Double(v) }
        }
        if let v = effect.properties["radius"] as? Double { return v }
        if let v = effect.properties["radius"] as? Int { return Double(v) }
        return 0
    }

    private func blurInlineControl(for effect: ComponentModifier) -> some View {
        let radius = currentBlurRadius(for: effect)
        let progress = max(0, min(1, radius / 50.0))
        return HStack(spacing: 10) {
            Button {
                canvasManager.removeModifier(from: component, modifier: effect)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.secondary.opacity(0.16)))
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.14))

                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.28))
                        .frame(width: width * progress)

                    Text("Blur")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.blue.opacity(0.95))
                        .padding(.horizontal, 12)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            setBlurRadius(for: effect, locationX: value.location.x, trackWidth: width, continuous: true)
                        }
                        .onEnded { value in
                            setBlurRadius(for: effect, locationX: value.location.x, trackWidth: width, continuous: false)
                        }
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)

            Button {
                numericInputText = String(Int(radius.rounded()))
                numericInputTarget = .blur(effect.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 14)
                    Text(String(Int(radius.rounded())))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(minWidth: 28, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.14))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func mobileSliderField(
        title: String,
        systemImage: String,
        value: Double,
        range: ClosedRange<Double>,
        step: Double,
        showHeader: Bool = true,
        compact: Bool = false,
        showContainer: Bool = true,
        onChange: @escaping (Double) -> Void,
        onCommit: @escaping (Double) -> Void,
        onDirectInput: @escaping () -> Void
    ) -> some View {
        let clampedValue = max(range.lowerBound, min(range.upperBound, value))
        let sliderBody = VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            if showHeader {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer(minLength: 0)
                    Button(action: onDirectInput) {
                        Text(verbatim: "\(Int(clampedValue.rounded()))")
                            .font(.system(size: compact ? 15 : 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, compact ? 8 : 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.secondary.opacity(0.16))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, compact ? 12 : 14)
            }

            Slider(
                value: Binding(
                    get: { clampedValue },
                    set: { onChange($0) }
                ),
                in: range,
                step: step,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        onCommit(clampedValue)
                    }
                }
            )
            .tint(.blue)
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.bottom, compact ? 2 : 6)
        }
        .padding(.top, compact ? 4 : 8)

        if showContainer {
            return AnyView(
                sliderBody
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(compact ? 0.10 : 0.14))
                    )
            )
        } else {
            return AnyView(sliderBody)
        }
    }

    private func setBlurRadius(for effect: ComponentModifier, locationX: CGFloat, trackWidth: CGFloat, continuous: Bool) {
        guard trackWidth > 1 else { return }
        let x = max(0, min(trackWidth, locationX))
        let percent = Float(x / trackWidth * 50.0)
        let newRadius = Double(min(max(0, percent), 50))
        if continuous {
            updateEffectModifierContinuous(effect) { mod in
                mod.properties["radius"] = newRadius
            }
        } else {
            updateEffectModifier(effect) { mod in
                mod.properties["radius"] = newRadius
            }
        }
    }

    private func groupRow(_ title: String, type: ModifierType?, menuTypes: [ModifierType]? = nil) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
            if let menuTypes {
                Menu {
                    ForEach(menuTypes) { t in
                        let isAlreadyAdded = component.modifiers.contains(where: { $0.type == t })
                        Button {
                            if !isAlreadyAdded {
                                ensureModifier(t)
                            }
                        } label: {
                            Label(t.rawValue, systemImage: t.icon)
                        }
                        .disabled(isAlreadyAdded)
                        .opacity(isAlreadyAdded ? 0.45 : 1.0)
                    }
                } label: {
                    plusCircle
                }
            } else if let type {
                Button {
                    ensureModifier(type)
                } label: {
                    plusCircle
                }
                .buttonStyle(.plain)
            } else {
                plusCircle.opacity(0.35)
            }
        }
    }

    private var plusCircle: some View {
        Image(systemName: "plus")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.secondary)
            .frame(width: 26, height: 26)
            .background(Circle().fill(Color.secondary.opacity(0.16)))
    }

    private var effectModifiers: [ComponentModifier] {
        let effectTypes: Set<ModifierType> = [.glassEffect, .shadow, .blur, .clipShape]
        return component.modifiers.filter { effectTypes.contains($0.type) }
    }

    private var borderModifiers: [ComponentModifier] {
        component.modifiers.filter { $0.type == .border || $0.type == .stroke }
    }

    private var fillModifiers: [ComponentModifier] {
        var seen = Set<ModifierType>()
        return component.modifiers.filter { modifier in
            guard singleInstanceFillTypes.contains(modifier.type) else { return false }
            if seen.contains(modifier.type) { return false }
            seen.insert(modifier.type)
            return true
        }
    }

    private func iconPercentInputField(
        symbol: String,
        text: Binding<String>,
        helpText: String? = nil,
        onCommitPercent: @escaping (Double) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            scrubIcon(
                systemName: symbol,
                scrubId: "percent:\(symbol)",
                currentValue: {
                    parsePercentInput(text.wrappedValue) ?? 100
                },
                range: 0...100
            ) { value in
                let clamped = max(0, min(100, value))
                text.wrappedValue = String(Int(clamped.rounded()))
                onCommitPercent(clamped)
            }

            TextField(text: text) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if let parsed = parsePercentInput(newValue) {
                        onCommitPercent(parsed)
                    }
                }
                .onSubmit {
                    let parsed = parsePercentInput(text.wrappedValue) ?? 100
                    text.wrappedValue = String(Int(parsed.rounded()))
                    onCommitPercent(parsed)
                }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .helpIf(helpText)
    }

    private func syncOpacityInputs() {
        let objectPercent = max(0, min(100, currentUniversalOpacity() * 100.0))
        objectOpacityInput = String(Int(objectPercent.rounded()))
    }

    private func inspectorSection<Content: View>(
        _ title: String,
        plus: (() -> Void)?,
        showActions: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                if showActions {
                    Button(action: onDuplicateComponent) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
#if os(macOS)
                    .keyboardShortcut("d", modifiers: .command)
#endif

                    Button(role: .destructive, action: onDeleteComponent) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
#if os(macOS)
                    .keyboardShortcut(.delete, modifiers: .command)
#endif
                }
                if let plus {
                    Button(action: plus) {
                        plusCircle
                    }
                    .buttonStyle(.plain)
                }
            }
            content()
        }
    }

    private func inspectorPillButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(roundedFieldBackground)
        }
        .buttonStyle(.plain)
    }

    private func compactMenuField(
        title: String,
        options: [String],
        helpText: String? = nil,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(roundedFieldBackground)
        }
        .buttonStyle(.plain)
        .helpIf(helpText)
    }

    private func toggleField(
        title: String,
        value: Bool,
        helpText: String? = nil,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Button {
            onChange(!value)
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: value ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(value ? .blue : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(roundedFieldBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .helpIf(helpText)
    }

    private var roundedFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.14))
    }

    private var frameWidthType: String {
        validFrameType((modifier(.frame)?.properties["widthType"] as? String) ?? "Default")
    }

    private var frameHeightType: String {
        validFrameType((modifier(.frame)?.properties["heightType"] as? String) ?? "Default")
    }

    private var frameWidthString: String {
        guard let m = modifier(.frame) else { return "120" }
        if let width = m.properties["width"] as? Double { return String(format: "%.0f", width) }
        if let width = m.properties["width"] as? Int { return "\(width)" }
        return "120"
    }

    private var frameHeightString: String {
        guard let m = modifier(.frame) else { return "120" }
        if let height = m.properties["height"] as? Double { return String(format: "%.0f", height) }
        if let height = m.properties["height"] as? Int { return "\(height)" }
        return "120"
    }

    private func frameInlineField(axis: String, text: Binding<String>) -> some View {
        let currentType = axis == "width" ? frameWidthType : frameHeightType
        let axisLabel = axis == "width" ? "W" : "H"
        let helpText = axis == "width" ? "Frame Width" : "Frame Height"

        return HStack(spacing: 8) {
            Menu {
                ForEach(["Default", "Full", "Custom"], id: \.self) { option in
                    Button(option) {
                        setFrameType(axis: axis, type: option)
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(axisLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 14)

            Spacer(minLength: 0)

            if currentType == "Custom" {
                TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.trailing)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        guard !isSyncingInspectorInputs else { return }
                        if isParsableNumberInput(newValue) {
                            updateFrameDimension(key: axis == "width" ? "width" : "height", value: newValue)
                        }
                    }
                    .onSubmit {
                        updateFrameDimension(key: axis == "width" ? "width" : "height", value: text.wrappedValue)
                    }

                Text("px")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            } else {
                Text(currentType)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
        .help(helpText)
    }

    private func mobileFrameSliderField(axis: String) -> some View {
        let isWidth = axis == "width"
        let axisTitle = isWidth ? "Width" : "Height"
        let currentType = isWidth ? frameWidthType : frameHeightType
        let key = isWidth ? "width" : "height"
        let currentValue = isWidth ? frameWidthString : frameHeightString
        let value = max(0, Double(currentValue) ?? 120)
        let maxRange = isWidth
            ? max(100, Double(canvasManager.devicePreset.size.width))
            : max(100, Double(canvasManager.devicePreset.size.height))

        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(["Default", "Full", "Custom"], id: \.self) { option in
                        Button(option) {
                            setFrameType(axis: axis, type: option)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(axisTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                if currentType == "Custom" {
                    Button {
                        numericInputText = currentValue
                        numericInputTarget = isWidth ? .frameWidth : .frameHeight
                    } label: {
                        Text(currentValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(roundedFieldBackground)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(currentType)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            if currentType == "Custom" {
                mobileSliderField(
                    title: axisTitle,
                    systemImage: isWidth ? "arrow.left.and.right" : "arrow.up.and.down",
                    value: value,
                    range: 0...maxRange,
                    step: 1,
                    showHeader: false,
                    compact: true,
                    showContainer: false
                ) { newValue in
                    updateFrameDimension(key: key, value: String(newValue), continuous: true)
                } onCommit: { committedValue in
                    updateFrameDimension(key: key, value: String(committedValue), continuous: false)
                } onDirectInput: {
                    numericInputText = currentValue
                    numericInputTarget = isWidth ? .frameWidth : .frameHeight
                }
            }
        }
        .padding(.bottom, currentType == "Custom" ? 8 : 10)
        .background(roundedFieldBackground)
    }

    private func mobileOffsetSliderField(axis: String) -> some View {
        let isX = axis == "x"
        let title = isX ? "X Offset" : "Y Offset"
        let currentValue = isX ? currentOffsetX() : currentOffsetY()
        let roundedValue = String(Int(currentValue.rounded()))

        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
                Button {
                    numericInputText = roundedValue
                    numericInputTarget = isX ? .offsetX : .offsetY
                } label: {
                    Text(roundedValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(roundedFieldBackground)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            mobileSliderField(
                title: title,
                systemImage: isX ? "arrow.left.and.right" : "arrow.up.and.down",
                value: currentValue,
                range: -500...500,
                step: 1,
                showHeader: false,
                compact: true,
                showContainer: false
            ) { newValue in
                setOffsetAxis(axis, String(newValue), continuous: true)
            } onCommit: { committedValue in
                setOffsetAxis(axis, String(committedValue), continuous: false)
            } onDirectInput: {
                numericInputText = roundedValue
                numericInputTarget = isX ? .offsetX : .offsetY
            }
        }
        .padding(.bottom, 8)
    }

    private func validFrameType(_ value: String) -> String {
        ["Default", "Full", "Custom"].contains(value) ? value : "Default"
    }

    private var alignmentOptions: [String]? {
        if component.type == .stack {
            return currentStackType == "horizontal"
                ? ["top", "center", "bottom"]
                : ["leading", "center", "trailing"]
        }
        if component.type == .hstack {
            return ["top", "center", "bottom"]
        }
        return ["leading", "center", "trailing"]
    }

    private var selectedAlignmentOption: String {
        let raw = (component.getProperty(key: "alignment") as? String) ?? "center"
        guard let options = alignmentOptions else { return raw }
        return options.contains(raw) ? raw : "center"
    }

    private func modifier(_ type: ModifierType) -> ComponentModifier? {
        component.modifiers.first(where: { $0.type == type })
    }

    private var currentFontDesign: String {
        ((modifier(.font)?.properties["fontDesign"] as? String) ?? "default").lowercased()
    }

    private var currentFontSizeToken: String {
        (modifier(.font)?.properties["fontSize"] as? String) ?? "body"
    }

    private var currentFontSizeValue: Double {
        fontSizeValue(from: currentFontSizeToken)
    }

    private var currentFontWeight: String {
        ((modifier(.font)?.properties["fontWeight"] as? String) ?? "regular").lowercased()
    }

    private var fontSizePresets: [(label: String, key: String, value: Double)] {
        [
            ("L", "largeTitle", 34),
            ("T1", "title", 28),
            ("T2", "title2", 22),
            ("T3", "title3", 20),
            ("H", "headline", 17),
            ("B", "body", 17),
            ("C", "callout", 16),
            ("S", "subheadline", 15),
            ("F", "footnote", 13),
            ("C1", "caption", 12),
            ("C2", "caption2", 11)
        ]
    }

    private func normalizeFontDesignSelection(_ value: String) -> String {
        switch value.lowercased() {
        case "serif": return "serif"
        case "rounded": return "rounded"
        case "monospaced": return "monospaced"
        default: return "default"
        }
    }

    private func fontDesignLabel(for value: String) -> String {
        switch value.lowercased() {
        case "serif": return "Serif"
        case "rounded": return "Rounded"
        case "monospaced": return "Monospaced"
        default: return "Default"
        }
    }

    private func normalizeFontWeightSelection(_ value: String) -> String {
        let lowered = value.lowercased()
        switch lowered {
        case "ultralight": return "ultraLight"
        case "semibold": return "semibold"
        default: return lowered
        }
    }

    private func fontWeightLabel(for value: String) -> String {
        switch value.lowercased() {
        case "ultralight": return "UltraLight"
        case "semibold": return "Semibold"
        case "medium": return "Medium"
        case "light": return "Light"
        case "thin": return "Thin"
        case "bold": return "Bold"
        case "heavy": return "Heavy"
        case "black": return "Black"
        default: return "Regular"
        }
    }

    private func fontSizeValue(from token: String) -> Double {
        if let direct = Double(token) { return direct }
        if let preset = fontSizePresets.first(where: { $0.key == token }) {
            return preset.value
        }
        return 17
    }

    private func syncTextFontSizeInput() {
        let value = max(8, min(72, currentFontSizeValue))
        textFontSizeInput = String(Int(value.rounded()))
    }

    private func setFontSizePreset(_ preset: String) {
        updateOrCreateModifier(.font) { mod in
            mod.properties["fontSize"] = preset
            if mod.properties["fontWeight"] == nil { mod.properties["fontWeight"] = "regular" }
            if mod.properties["fontDesign"] == nil { mod.properties["fontDesign"] = "default" }
        }
        syncTextFontSizeInput()
    }

    private func setCustomFontSize(_ raw: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsed = max(8, min(72, Double(cleaned) ?? currentFontSizeValue))
        let isWhole = abs(parsed.rounded() - parsed) < 0.0001
        let sizeToken = isWhole ? String(Int(parsed.rounded())) : String(format: "%.1f", parsed)
        updateOrCreateModifier(.font) { mod in
            mod.properties["fontSize"] = sizeToken
            if mod.properties["fontWeight"] == nil { mod.properties["fontWeight"] = "regular" }
            if mod.properties["fontDesign"] == nil { mod.properties["fontDesign"] = "default" }
        }
        syncTextFontSizeInput()
    }
    
    private func applyTypingFontSize(_ raw: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(cleaned), parsed >= 8, parsed <= 72 else { return }
        let isWhole = abs(parsed.rounded() - parsed) < 0.0001
        let sizeToken = isWhole ? String(Int(parsed.rounded())) : String(format: "%.1f", parsed)
        updateOrCreateModifier(.font) { mod in
            mod.properties["fontSize"] = sizeToken
            if mod.properties["fontWeight"] == nil { mod.properties["fontWeight"] = "regular" }
            if mod.properties["fontDesign"] == nil { mod.properties["fontDesign"] = "default" }
        }
    }

    private func adjustFontSize(by delta: Double) {
        let next = max(8, min(72, currentFontSizeValue + delta))
        setCustomFontSize(String(Int(next.rounded())))
    }

    private func fontSizeIndicator(value: Double) -> some View {
        let normalized = max(0, min(1, (value - 8) / (72 - 8)))
        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: normalized)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(verbatim: "A")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(width: 20, height: 20)
    }

    private func ensureModifier(_ type: ModifierType) {
        if singleInstanceFillTypes.contains(type) {
            enforceSingleModifierPerType(type)
        }
        if modifier(type) != nil { return }
        let created = ComponentModifier.createWithDefaults(type: type)
        canvasManager.addModifier(to: component, modifier: created)
    }

    private func updateOrCreateModifier(_ type: ModifierType, mutate: @escaping (inout ComponentModifier) -> Void) {
        if singleInstanceFillTypes.contains(type) {
            enforceSingleModifierPerType(type)
        }
        if var existing = modifier(type) {
            mutate(&existing)
            canvasManager.updateModifier(for: component, modifier: existing)
        } else {
            var created = ComponentModifier.createWithDefaults(type: type)
            mutate(&created)
            canvasManager.addModifier(to: component, modifier: created)
        }
    }

    private var singleInstanceFillTypes: Set<ModifierType> {
        [.fill, .foregroundColor, .backgroundColor, .tint]
    }

    private func enforceSingleModifierPerType(_ type: ModifierType) {
        let matches = component.modifiers.filter { $0.type == type }
        guard matches.count > 1 else { return }
        for duplicate in matches.dropFirst() {
            canvasManager.removeModifier(from: component, modifier: duplicate)
        }
    }

    private func enforceSingleFillModifiers() {
        for type in singleInstanceFillTypes {
            enforceSingleModifierPerType(type)
        }
    }

    private func updateFrameModifier(mutate: @escaping (inout ComponentModifier) -> Void) {
        updateOrCreateModifier(.frame, mutate: mutate)
    }

    private func setFrameType(axis: String, type: String) {
        let typeKey = axis == "width" ? "widthType" : "heightType"
        let valueKey = axis == "width" ? "width" : "height"

        let normalized = validFrameType(type)
        if normalized == "Default" {
            guard var frame = modifier(.frame) else { return }
            frame.properties[typeKey] = "Default"
            frame.properties.removeValue(forKey: valueKey)

            let widthType = validFrameType((frame.properties["widthType"] as? String) ?? "Default")
            let heightType = validFrameType((frame.properties["heightType"] as? String) ?? "Default")
            if widthType == "Default" && heightType == "Default" {
                canvasManager.removeModifier(from: component, modifier: frame)
            } else {
                canvasManager.updateModifier(for: component, modifier: frame)
            }
            return
        }

        updateFrameModifier { mod in
            mod.properties[typeKey] = normalized
            if normalized == "Custom", mod.properties[valueKey] == nil {
                mod.properties[valueKey] = 120.0
            }
            if normalized == "Full" {
                mod.properties.removeValue(forKey: valueKey)
            }
        }
    }

    private func updateFrameDimension(key: String, value: String, continuous: Bool = false) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let numeric = Double(cleaned) else { return }
        guard numeric.isFinite else { return }
        let clamped = max(0, numeric)

        if var existing = modifier(.frame) {
            existing.properties[key] = clamped
            if key == "width" {
                existing.properties["widthType"] = "Custom"
            } else {
                existing.properties["heightType"] = "Custom"
            }
            if continuous {
                canvasManager.updateModifierContinuous(for: component, modifier: existing)
            } else {
                canvasManager.updateModifier(for: component, modifier: existing)
            }
        } else {
            var created = ComponentModifier.createWithDefaults(type: .frame)
            created.properties[key] = clamped
            if key == "width" {
                created.properties["widthType"] = "Custom"
            } else {
                created.properties["heightType"] = "Custom"
            }
            canvasManager.addModifier(to: component, modifier: created)
        }
    }

    private func paddingAxisField(
        symbol: String,
        text: Binding<String>,
        helpText: String? = nil,
        onCommit: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            scrubIcon(
                systemName: symbol,
                scrubId: "padding:\(symbol)",
                currentValue: {
                    parseNumericInput(text.wrappedValue)
                },
                range: 0...500
            ) { value in
                let rounded = Int(max(0, value).rounded())
                text.wrappedValue = "\(rounded)"
                onCommit(text.wrappedValue)
            }
            .frame(width: 16)

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        onCommit(newValue)
                    }
                }
                .onSubmit {
                    onCommit(text.wrappedValue)
                }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .helpIf(helpText)
    }

    private func axisInputField(
        label: String,
        text: Binding<String>,
        helpText: String? = nil,
        onCommit: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 14)

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        onCommit(newValue)
                    }
                }
                .onSubmit {
                    onCommit(text.wrappedValue)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .frame(maxWidth: .infinity)
        .helpIf(helpText)
    }

    private func pxInputField(text: Binding<String>, onCommit: @escaping (String) -> Void) -> some View {
        HStack(spacing: 8) {
            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        onCommit(newValue)
                    }
                }
                .onSubmit {
                    onCommit(text.wrappedValue)
                }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
    }

    private func iconPxInputField(
        symbol: String,
        text: Binding<String>,
        helpText: String? = nil,
        scrubId: String? = nil,
        scrubRange: ClosedRange<Double> = 0...500,
        onCommit: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            scrubIcon(
                systemName: symbol,
                scrubId: scrubId ?? "px:\(symbol)",
                currentValue: {
                    parseNumericInput(text.wrappedValue)
                },
                range: scrubRange
            ) { value in
                let rounded = Int(min(max(value, scrubRange.lowerBound), scrubRange.upperBound).rounded())
                text.wrappedValue = "\(rounded)"
                onCommit(text.wrappedValue)
            }

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        onCommit(newValue)
                    }
                }
                .onSubmit {
                    onCommit(text.wrappedValue)
                }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .helpIf(helpText)
    }

    private func iconDegreeInputField(
        symbol: String,
        text: Binding<String>,
        helpText: String? = nil,
        onCommit: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            scrubIcon(
                systemName: symbol,
                scrubId: "degree:\(symbol)",
                currentValue: {
                    parseNumericInput(text.wrappedValue)
                },
                range: -360...360
            ) { value in
                let rounded = Int(value.rounded())
                text.wrappedValue = "\(rounded)"
                onCommit(text.wrappedValue)
            }

            TextField(text: text, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        onCommit(newValue)
                    }
                }
                .onSubmit {
                    onCommit(text.wrappedValue)
                }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .helpIf(helpText)
    }

    private func alignmentSegmentedControl(options: [String], selected: String) -> some View {
#if os(iOS)
        let selection = Binding<String>(
            get: { selected },
            set: { newValue in
                canvasManager.updateComponentProperty(for: component, key: "alignment", value: newValue)
            }
        )

        return Picker("Alignment", selection: selection) {
            ForEach(options, id: \.self) { option in
                Image(systemName: alignmentIcon(for: option))
                    .font(.system(size: 13, weight: .semibold))
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
#else
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    Button {
                        canvasManager.updateComponentProperty(for: component, key: "alignment", value: option)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selected == option ? Color.blue : Color.clear)
                            Image(systemName: alignmentIcon(for: option))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selected == option ? .white : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.14))
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let cellWidth = width / CGFloat(max(options.count, 1))
                        guard cellWidth > 0 else { return }
                        let raw = Int(value.location.x / cellWidth)
                        let index = min(max(raw, 0), options.count - 1)
                        let option = options[index]
                        if option != selected {
                            canvasManager.updateComponentProperty(for: component, key: "alignment", value: option)
                        }
                    }
            )
        }
        .frame(height: 36)
#endif
    }

    private func stackTypeSegmentedControl(selected: String) -> some View {
        let options = ["vertical", "horizontal", "z"]
        return HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    canvasManager.updateComponentProperty(for: component, key: "stackType", value: option)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selected == option ? Color.blue : Color.clear)
                        Image(systemName: stackTypeIcon(for: option))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selected == option ? .white : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.14))
        )
    }

    private func stackTypeIcon(for option: String) -> String {
        switch option {
        case "horizontal": return "arrow.right"
        case "z": return "square.stack.3d.up"
        default: return "arrow.down"
        }
    }

    private func alignmentIcon(for option: String) -> String {
        switch option {
        case "leading": return "text.alignleft"
        case "trailing": return "text.alignright"
        case "top": return "arrow.up.to.line"
        case "bottom": return "arrow.down.to.line"
        default: return "text.aligncenter"
        }
    }

    private var currentStackType: String {
        let raw = ((component.getProperty(key: "stackType") as? String) ?? "vertical").lowercased()
        if raw == "horizontal" || raw == "z" { return raw }
        return "vertical"
    }

    private func syncStackInputs() {
        guard component.type == .stack else {
            stackSpacingInput = "0"
            return
        }
        if let spacing = component.getProperty(key: "spacing") as? Double {
            stackSpacingInput = String(Int(spacing.rounded()))
        } else if let spacing = component.getProperty(key: "spacing") as? Int {
            stackSpacingInput = "\(spacing)"
        } else {
            stackSpacingInput = "0"
        }
    }

    private func setStackSpacing(_ valueText: String) {
        guard component.type == .stack else { return }
        let cleaned = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "px", with: "")
        let parsed = max(0, Double(cleaned) ?? 0)
        canvasManager.updateComponentProperty(for: component, key: "spacing", value: parsed)
        stackSpacingInput = String(Int(parsed.rounded()))
    }

    private var stackSpacingInlineField: some View {
        HStack(spacing: 8) {
            Text("Spacing")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            TextField(text: $stackSpacingInput, prompt: Text(verbatim: "0")) { EmptyView() }
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(width: 40)
                .onChange(of: stackSpacingInput) { _, newValue in
                    guard !isSyncingInspectorInputs else { return }
                    if isParsableNumberInput(newValue) {
                        setStackSpacing(newValue)
                    }
                }
                .onSubmit {
                    setStackSpacing(stackSpacingInput)
                }
            Text("px")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(roundedFieldBackground)
        .help("Stack Spacing")
    }

    private func syncPaddingInputs() {
        paddingHorizontalInput = String(Int(resolvedPaddingAmount(for: "horizontal").rounded()))
        paddingVerticalInput = String(Int(resolvedPaddingAmount(for: "vertical").rounded()))
    }

    private func currentOffsetX() -> Double {
        guard let current = modifier(.offset) else { return 0 }
        if let value = current.properties["x"] as? Double { return value }
        if let value = current.properties["x"] as? Int { return Double(value) }
        if let value = current.properties["offsetX"] as? Double { return value }
        if let value = current.properties["offsetX"] as? Int { return Double(value) }
        return 0
    }

    private func currentOffsetY() -> Double {
        guard let current = modifier(.offset) else { return 0 }
        if let value = current.properties["y"] as? Double { return value }
        if let value = current.properties["y"] as? Int { return Double(value) }
        if let value = current.properties["offsetY"] as? Double { return value }
        if let value = current.properties["offsetY"] as? Int { return Double(value) }
        return 0
    }

    private func syncOffsetInputs() {
        offsetXInput = String(Int(currentOffsetX().rounded()))
        offsetYInput = String(Int(currentOffsetY().rounded()))
    }

    private func syncFrameInputs() {
        frameWidthInput = frameWidthString
        frameHeightInput = frameHeightString
    }

    private func resolvedPaddingAmount(for axis: String) -> Double {
        if let exact = paddingModifier(for: axis),
           let amount = exact.properties["amount"] as? Double ?? (exact.properties["amount"] as? Int).map(Double.init) {
            return max(0, amount)
        }
        if let all = paddingModifier(for: "all"),
           let amount = all.properties["amount"] as? Double ?? (all.properties["amount"] as? Int).map(Double.init) {
            return max(0, amount)
        }
        return 0
    }

    private func paddingModifier(for location: String) -> ComponentModifier? {
        component.modifiers.first {
            $0.type == .padding && (($0.properties["location"] as? String)?.lowercased() ?? "all") == location
        }
    }

    private func setPaddingAxis(_ axis: String, _ valueText: String, continuous: Bool = false) {
        let cleaned = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "px", with: "")
        let parsed = max(0, Double(cleaned) ?? 0)
        let horizontal = axis == "horizontal" ? parsed : resolvedPaddingAmount(for: "horizontal")
        let vertical = axis == "vertical" ? parsed : resolvedPaddingAmount(for: "vertical")
        applyPaddingPair(horizontal: horizontal, vertical: vertical, continuous: continuous)
        if !continuous {
            syncPaddingInputs()
        }
    }

    private func setOffsetAxis(_ axis: String, _ valueText: String, continuous: Bool = false) {
        let cleaned = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "px", with: "")
        let parsed = Double(cleaned) ?? 0
        let x = axis == "x" ? parsed : currentOffsetX()
        let y = axis == "y" ? parsed : currentOffsetY()

        if !continuous && abs(x) < 0.0001 && abs(y) < 0.0001 {
            if let existing = modifier(.offset) {
                canvasManager.removeModifier(from: component, modifier: existing)
            }
        } else {
            if var existing = modifier(.offset) {
                existing.properties["x"] = x
                existing.properties["offsetX"] = x
                existing.properties["y"] = y
                existing.properties["offsetY"] = y
                if continuous {
                    canvasManager.updateModifierContinuous(for: component, modifier: existing)
                } else {
                    canvasManager.updateModifier(for: component, modifier: existing)
                }
            } else {
                var created = ComponentModifier.createWithDefaults(type: .offset)
                created.properties["x"] = x
                created.properties["offsetX"] = x
                created.properties["y"] = y
                created.properties["offsetY"] = y
                canvasManager.addModifier(to: component, modifier: created)
            }
        }
        if !continuous {
            syncOffsetInputs()
        }
    }

    private func applyPaddingPair(horizontal: Double, vertical: Double, continuous: Bool = false) {
        if let all = paddingModifier(for: "all") {
            canvasManager.removeModifier(from: component, modifier: all)
        }

        upsertPadding(location: "horizontal", amount: horizontal, continuous: continuous)
        upsertPadding(location: "vertical", amount: vertical, continuous: continuous)
    }

    private func upsertPadding(location: String, amount: Double, continuous: Bool = false) {
        if let existing = paddingModifier(for: location) {
            if amount <= 0 {
                canvasManager.removeModifier(from: component, modifier: existing)
            } else {
                var updated = existing
                updated.properties["location"] = location
                updated.properties["amount"] = amount
                if continuous {
                    canvasManager.updateModifierContinuous(for: component, modifier: updated)
                } else {
                    canvasManager.updateModifier(for: component, modifier: updated)
                }
            }
        } else if amount > 0 {
            var created = ComponentModifier.createWithDefaults(type: .padding)
            created.properties["location"] = location
            created.properties["amount"] = amount
            canvasManager.addModifier(to: component, modifier: created)
        }
    }

    private func syncTextInput() {
        guard let key = editableTextKey else {
            textInput = ""
            return
        }
        if let value = component.getProperty(key: key) as? String {
            textInput = value
        } else {
            textInput = ""
        }
    }

    private func syncTextFieldInputs() {
        guard component.type == .textField else { return }
        textFieldTextInput = (component.getProperty(key: "text") as? String) ?? ""
        textFieldPlaceholderInput = (component.getProperty(key: "placeholder") as? String) ?? ""
    }

    private func syncSliderInputs() {
        guard component.type == .slider else { return }

        let value = (component.getProperty(key: "value") as? Double)
            ?? (component.getProperty(key: "value") as? Int).map(Double.init)
            ?? 0.5
        let min = (component.getProperty(key: "min") as? Double)
            ?? (component.getProperty(key: "min") as? Int).map(Double.init)
            ?? 0.0
        let max = (component.getProperty(key: "max") as? Double)
            ?? (component.getProperty(key: "max") as? Int).map(Double.init)
            ?? 1.0

        sliderValueInput = formatSliderNumber(value)
        sliderMinInput = formatSliderNumber(min)
        sliderMaxInput = formatSliderNumber(max)
    }

    private func syncShapeInputs() {
        guard component.type == .shape else { return }
        let radius = (component.getProperty(key: "cornerRadius") as? Double)
            ?? (component.getProperty(key: "cornerRadius") as? Int).map(Double.init)
            ?? 12.0
        shapeCornerRadiusInput = String(Int(max(0, radius).rounded()))
    }

    private func syncProgressInputs() {
        guard component.type == .progressView else { return }

        let value = (component.getProperty(key: "value") as? Double)
            ?? (component.getProperty(key: "value") as? Int).map(Double.init)
            ?? 0.6
        let total = (component.getProperty(key: "total") as? Double)
            ?? (component.getProperty(key: "total") as? Int).map(Double.init)
            ?? 1.0

        progressValueInput = formatSliderNumber(value)
        progressTotalInput = formatSliderNumber(total)
    }

    private func syncChartInputs() {
        guard component.type == .chart else { return }

        let rawPointCount = (component.getProperty(key: "pointCount") as? Double)
            ?? (component.getProperty(key: "pointCount") as? Int).map(Double.init)
            ?? 20.0

        chartPointCountValue = max(5, min(30, rawPointCount.rounded()))
    }

    private func syncGaugeInputs() {
        guard component.type == .gauge else { return }

        let value = (component.getProperty(key: "value") as? Double)
            ?? (component.getProperty(key: "value") as? Int).map(Double.init)
            ?? 50.0
        let min = (component.getProperty(key: "min") as? Double)
            ?? (component.getProperty(key: "min") as? Int).map(Double.init)
            ?? 0.0
        let max = (component.getProperty(key: "max") as? Double)
            ?? (component.getProperty(key: "max") as? Int).map(Double.init)
            ?? 100.0

        gaugeValueInput = formatSliderNumber(value)
        gaugeMinInput = formatSliderNumber(min)
        gaugeMaxInput = formatSliderNumber(max)
    }

    private func updateSliderProperty(key: String, input: String, continuous: Bool) {
        guard component.type == .slider else { return }
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(cleaned) else { return }

        if continuous {
            canvasManager.updateComponentPropertyContinuous(for: component, key: key, value: parsed)
        } else {
            canvasManager.updateComponentProperty(for: component, key: key, value: parsed)
            switch key {
            case "value":
                sliderValueInput = formatSliderNumber(parsed)
            case "min":
                sliderMinInput = formatSliderNumber(parsed)
            case "max":
                sliderMaxInput = formatSliderNumber(parsed)
            default:
                break
            }
        }
    }

    private func updateProgressProperty(key: String, input: String, continuous: Bool) {
        guard component.type == .progressView else { return }
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(cleaned) else { return }

        if continuous {
            canvasManager.updateComponentPropertyContinuous(for: component, key: key, value: parsed)
        } else {
            canvasManager.updateComponentProperty(for: component, key: key, value: parsed)
            if key == "value" {
                progressValueInput = formatSliderNumber(parsed)
            } else if key == "total" {
                progressTotalInput = formatSliderNumber(parsed)
            }
        }
    }

    private func updateGaugeProperty(key: String, input: String, continuous: Bool) {
        guard component.type == .gauge else { return }
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(cleaned) else { return }

        if continuous {
            canvasManager.updateComponentPropertyContinuous(for: component, key: key, value: parsed)
        } else {
            canvasManager.updateComponentProperty(for: component, key: key, value: parsed)
            switch key {
            case "value":
                gaugeValueInput = formatSliderNumber(parsed)
            case "min":
                gaugeMinInput = formatSliderNumber(parsed)
            case "max":
                gaugeMaxInput = formatSliderNumber(parsed)
            default:
                break
            }
        }
    }

    private func setShapeCornerRadius(_ valueText: String) {
        guard component.type == .shape else { return }
        let cleaned = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "px", with: "")
        let parsed = max(0, min(100, Double(cleaned) ?? 0))
        canvasManager.updateComponentProperty(for: component, key: "cornerRadius", value: parsed)
        shapeCornerRadiusInput = String(Int(parsed.rounded()))
    }

    private func updateChartPointCount(_ value: Double, continuous: Bool) {
        guard component.type == .chart else { return }

        let clamped = max(5, min(30, value.rounded()))
        chartPointCountValue = clamped

        if continuous {
            canvasManager.updateComponentPropertyContinuous(for: component, key: "pointCount", value: clamped)
        } else {
            canvasManager.updateComponentProperty(for: component, key: "pointCount", value: clamped)
        }
    }

    private func formatSliderNumber(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.0001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.2f", value)
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }

    private func syncSymbolInput() {
        guard hasSymbolProperty else { return }
        if let current = component.getProperty(key: "symbolName") as? String, !current.isEmpty {
            symbolInput = current
        } else {
            symbolInput = "star"
        }
    }

    private func currentUniversalOpacity() -> Double {
        if let opacityModifier = modifier(.opacity) {
            return max(0, min(1, opacityModifier.getDouble(key: "opacity", defaultValue: 1.0)))
        }
        return 1.0
    }

    private func setUniversalOpacity(_ value: Double, continuous: Bool = false) {
        let clamped = max(0, min(1, value))
        if var existing = modifier(.opacity) {
            existing.properties["opacity"] = clamped
            if continuous {
                canvasManager.updateModifierContinuous(for: component, modifier: existing)
            } else {
                canvasManager.updateModifier(for: component, modifier: existing)
            }
        } else {
            var created = ComponentModifier.createWithDefaults(type: .opacity)
            created.properties["opacity"] = clamped
            canvasManager.addModifier(to: component, modifier: created)
        }
    }

    private func syncCornerRadiusInput() {
        if let radiusModifier = modifier(.cornerRadius) {
            let value = radiusModifier.getDouble(key: "radius", defaultValue: 0)
            cornerRadiusInput = String(Int(max(0, value).rounded()))
        } else {
            cornerRadiusInput = "0"
        }
    }

    private func setCornerRadius(_ valueText: String, continuous: Bool = false) {
        let cleaned = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "px", with: "")
        let parsed = max(0, min(100, Double(cleaned) ?? 0))

        if parsed <= 0 {
            if let existing = modifier(.cornerRadius) {
                canvasManager.removeModifier(from: component, modifier: existing)
            }
            cornerRadiusInput = "0"
            return
        }

        if var existing = modifier(.cornerRadius) {
            existing.properties["radius"] = parsed
            if continuous {
                canvasManager.updateModifierContinuous(for: component, modifier: existing)
            } else {
                canvasManager.updateModifier(for: component, modifier: existing)
            }
        } else {
            var created = ComponentModifier.createWithDefaults(type: .cornerRadius)
            created.properties["radius"] = parsed
            canvasManager.addModifier(to: component, modifier: created)
        }
        cornerRadiusInput = String(Int(parsed.rounded()))
    }

    private func glassEffectCornerRadius(for effect: ComponentModifier) -> Double {
        if let radius = effect.properties["cornerRadius"] as? Double { return radius }
        if let radius = effect.properties["cornerRadius"] as? CGFloat { return Double(radius) }
        if let radius = effect.properties["cornerRadius"] as? Int { return Double(radius) }
        return 10
    }

    private func currentGlassEffectCornerRadius(for effect: ComponentModifier) -> Double {
        if let latest = component.modifiers.first(where: { $0.id == effect.id }) {
            return glassEffectCornerRadius(for: latest)
        }
        return glassEffectCornerRadius(for: effect)
    }

    private func currentClipShapeCornerRadius(for effect: ComponentModifier) -> Double {
        if let latest = component.modifiers.first(where: { $0.id == effect.id }) {
            if let radius = latest.properties["cornerRadius"] as? Double { return radius }
            if let radius = latest.properties["cornerRadius"] as? CGFloat { return Double(radius) }
            if let radius = latest.properties["cornerRadius"] as? Int { return Double(radius) }
        }
        if let radius = effect.properties["cornerRadius"] as? Double { return radius }
        if let radius = effect.properties["cornerRadius"] as? CGFloat { return Double(radius) }
        if let radius = effect.properties["cornerRadius"] as? Int { return Double(radius) }
        return 10
    }

    private func glassShapeDisplayName(_ storageName: String) -> String {
        switch storageName {
        case "Rectangle": return "Rect"
        case "RoundedRectangle": return "Rounded"
        default: return storageName
        }
    }

    private func glassShapeStorageName(_ displayName: String) -> String {
        switch displayName {
        case "Rect": return "Rectangle"
        case "Rounded": return "RoundedRectangle"
        default: return displayName
        }
    }

    private func syncRotationInput() {
        if let rotationModifier = modifier(.rotation) {
            let value = rotationModifier.getDouble(key: "angle", defaultValue: 0)
            rotationInput = String(Int(value.rounded()))
        } else {
            rotationInput = "0"
        }
    }

    private func setRotation(_ valueText: String) {
        let cleaned = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "°", with: "")
        let parsed = Double(cleaned) ?? 0
        let clamped = max(-360, min(360, parsed))
        if abs(clamped) < 0.0001 {
            if let existing = modifier(.rotation) {
                canvasManager.removeModifier(from: component, modifier: existing)
            }
            rotationInput = "0"
            return
        }
        updateOrCreateModifier(.rotation) { mod in
            mod.properties["angle"] = clamped
        }
        rotationInput = String(Int(clamped.rounded()))
    }

    private func parsePercentInput(_ raw: String) -> Double? {
        let cleaned = raw
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let value = Double(cleaned) else { return nil }
        return max(0, min(100, value))
    }

    private func parseNumericInput(_ raw: String) -> Double {
        let cleaned = raw
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "px", with: "")
            .replacingOccurrences(of: "°", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0
    }

    private func isParsableNumberInput(_ raw: String) -> Bool {
        let cleaned = raw
            .replacingOccurrences(of: "px", with: "")
            .replacingOccurrences(of: "°", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }
        return Double(cleaned) != nil
    }

    private func colorFromToken(_ token: String) -> Color {
        let normalized = token.hasPrefix("color:") ? String(token.dropFirst(6)) : token
        return ComponentProperty.colorStringToColor(normalized)
    }

    private func scrubIcon(
        systemName: String,
        scrubId: String,
        currentValue: @escaping () -> Double,
        range: ClosedRange<Double>? = nil,
        onScrub: @escaping (Double) -> Void
    ) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(width: 14)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let start = scrubStartValues[scrubId] ?? {
                            let initial = currentValue()
                            scrubStartValues[scrubId] = initial
                            return initial
                        }()
                        var next = start + Double(value.translation.width / 6.0)
                        if let range {
                            next = min(max(next, range.lowerBound), range.upperBound)
                        }
                        onScrub(next)
                    }
                    .onEnded { _ in
                        scrubStartValues.removeValue(forKey: scrubId)
                    }
            )
#if os(macOS)
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
#endif
    }

}
