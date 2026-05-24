
import SwiftUI
import Charts

extension ComponentRenderer {
    func renderText() -> some View {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        return Text(text)
    }
    
    private func iosFont(for fontSize: String, weight: Font.Weight, deviceSize: CGSize? = nil) -> Font {
        return createIOSFont(for: fontSize, weight: weight, design: .default, deviceSize: deviceSize ?? self.deviceSize)
    }
    
    func renderShape() -> some View {
        let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"

        switch shapeType {
        case "Circle":
            return AnyView(Circle().foregroundStyle(.primary))
        case "Capsule":
            return AnyView(Capsule().foregroundStyle(.primary))
        case "Ellipse":
            return AnyView(Ellipse().foregroundStyle(.primary))
        case "Rounded Rectangle":
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return AnyView(RoundedRectangle(cornerRadius: radius).foregroundStyle(.primary))
        default:
            return AnyView(Rectangle().foregroundStyle(.primary))
        }
    }
    
    func renderImage() -> some View {
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        
        var imageName = component.getProperty(key: "imageName") as? String ?? ""
        
        if imageName.isEmpty {
            let imageData = component.getProperty(key: "imageData") as? String ?? ""
            
            if !imageData.isEmpty {
                if imageData.hasSuffix(".jpg") || imageData.hasSuffix(".jpeg") || imageData.hasSuffix(".png") || imageData.hasSuffix(".gif") || imageData.hasSuffix(".heic") {
                    imageName = imageData
                }
                else if ImageGalleryManager.shared.getAllImageFilenames().contains(imageData) {
                     imageName = imageData
                }
            }
        }
        
        if !imageName.isEmpty && ImageGalleryManager.shared.imageExists(filename: imageName) {
             return AnyView(ImageComponentView(
                imageName: imageName,
                resizable: resizable,
                aspectRatio: aspectRatio,
                deviceSize: deviceSize
             ))
        }

        if let remoteURL = URL(string: imageName),
           let scheme = remoteURL.scheme?.lowercased(),
           (scheme == "http" || scheme == "https") {
            return AnyView(RemoteImageComponentView(
                url: remoteURL,
                resizable: resizable,
                aspectRatio: aspectRatio,
                deviceSize: deviceSize
            ))
        }
        
        if let imageDataString = component.getProperty(key: "imageData") as? String,
           !imageDataString.isEmpty {
            if let imageData = Data(base64Encoded: imageDataString, options: .ignoreUnknownCharacters),
               !imageData.isEmpty {
                if let image = createImage(from: imageData) {
                    let maxWidth = deviceSize?.width ?? 1000
                    let maxHeight = deviceSize?.height ?? 1000
                    
                    #if os(macOS)
                    let imageSize = getImageSize(image)
                    let imageAspectRatio = imageSize.width > 0 && imageSize.height > 0 ? imageSize.width / imageSize.height : nil
                    
                    var view: AnyView = AnyView(Image(nsImage: image)
                        .resizableIfNeeded(resizable))
                    
                    if aspectRatio != "none", let aspectRatioValue = imageAspectRatio {
                        switch aspectRatio {
                        case "fit":
                            view = AnyView(view.aspectRatio(aspectRatioValue, contentMode: .fit))
                        case "fill":
                            view = AnyView(view.aspectRatio(aspectRatioValue, contentMode: .fill))
                        default:
                            view = AnyView(view.aspectRatio(aspectRatioValue, contentMode: .fit))
                        }
                    } else if aspectRatio != "none" {
                        switch aspectRatio {
                        case "fit":
                            view = AnyView(view.aspectRatio(contentMode: .fit))
                        case "fill":
                            view = AnyView(view.aspectRatio(contentMode: .fill))
                        default:
                            break
                        }
                    }
                    #else
                    let imageSize = getImageSize(image)
                    let imageAspectRatio = imageSize.width > 0 && imageSize.height > 0 ? imageSize.width / imageSize.height : nil
                    
                    var view: AnyView = AnyView(Image(uiImage: image)
                        .resizableIfNeeded(resizable))
                    
                    if aspectRatio != "none", let aspectRatioValue = imageAspectRatio {
                        switch aspectRatio {
                        case "fit":
                            view = AnyView(view.aspectRatio(aspectRatioValue, contentMode: .fit))
                        case "fill":
                            view = AnyView(view.aspectRatio(aspectRatioValue, contentMode: .fill).clipped())
                        default:
                            view = AnyView(view.aspectRatio(aspectRatioValue, contentMode: .fit))
                        }
                    } else if aspectRatio != "none" {
                        switch aspectRatio {
                        case "fit":
                            view = AnyView(view.aspectRatio(contentMode: .fit))
                        case "fill":
                            view = AnyView(view.aspectRatio(contentMode: .fill).clipped())
                        default:
                            break
                        }
                    }
                    #endif
                    
                    view = AnyView(view.frame(maxWidth: maxWidth, maxHeight: maxHeight))
                }
            }
        }
        
        let defaultSize: CGFloat = 100
        
        let placeholderView = ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
            VStack(spacing: 4) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("Select Image")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: defaultSize, height: defaultSize)
        
        return AnyView(placeholderView)
    }

    #if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        guard !data.isEmpty else {
            debugLog("⚠️ Image data is empty")
            return nil
        }
        
        guard let image = NSImage(data: data) else {
            debugLog("⚠️ Failed to create NSImage from data")
            return nil
        }
        
        guard image.isValid else {
            debugLog("⚠️ NSImage is invalid")
            return nil
        }
        
        return image
    }
    #else
    private func createImage(from data: Data) -> UIImage? {
        guard !data.isEmpty else {
            debugLog("⚠️ Image data is empty")
            return nil
        }
        
        guard let image = UIImage(data: data) else {
            debugLog("⚠️ Failed to create UIImage from data")
            return nil
        }
        
        guard image.size.width > 0 && image.size.height > 0 else {
            debugLog("⚠️ UIImage has invalid size")
            return nil
        }
        
        return image
    }
    #endif
    
    #if os(macOS)
    private func getImageSize(_ image: NSImage) -> CGSize {
        return image.size
    }
    #else
    private func getImageSize(_ image: UIImage) -> CGSize {
        return image.size
    }
    #endif
    
    func renderButton() -> some View {
        let buttonStyle = component.getProperty(key: "buttonStyle") as? String ?? "borderedProminent"
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        return AnyView(
            Button(action: {}) {
                if contentChildren.isEmpty {
                    EmptyView()
                } else {
                    ForEach(contentChildren, id: \.id) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                            onSelectChild?(child, additive)
                        }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                    }
                }
            }
            .applyButtonStyle(buttonStyle)
        )
    }
    
    func renderGauge() -> some View {
        let gaugeType = component.getProperty(key: "gaugeType") as? String ?? "circular"
        let rawValue = (component.getProperty(key: "value") as? Double)
            ?? (component.getProperty(key: "value") as? Int).map(Double.init)
            ?? 50
        let rawMin = (component.getProperty(key: "min") as? Double)
            ?? (component.getProperty(key: "min") as? Int).map(Double.init)
            ?? 0
        let rawMax = (component.getProperty(key: "max") as? Double)
            ?? (component.getProperty(key: "max") as? Int).map(Double.init)
            ?? 100
        let showValue = component.getProperty(key: "showValue") as? Bool ?? true
        
        let minValue = Swift.min(rawMin, rawMax)
        let maxValue = Swift.max(rawMin, rawMax)
        let safeValue = rawValue.isFinite ? rawValue : minValue
        let value = Swift.min(Swift.max(safeValue, minValue), maxValue)
        
        return AnyView(
            Group {
                switch gaugeType {
                case "linear":
                    Gauge(value: value, in: minValue...maxValue) {
                        if showValue {
                            Text("\(Int(value))")
                        }
                    }
                    .gaugeStyle(.linearCapacity)
                    
                case "circular":
                    Gauge(value: value, in: minValue...maxValue) {
                        if showValue {
                            Text("\(Int(value))")
                        } else {
                            EmptyView()
                        }
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    
                case "circular range":
                    Gauge(value: value, in: minValue...maxValue) {
                        EmptyView()
                    } currentValueLabel: {
                        if showValue {
                            Text("\(Int(value))")
                        } else {
                            EmptyView()
                        }
                    } minimumValueLabel: {
                        Text("\(Int(minValue))")
                    } maximumValueLabel: {
                        Text("\(Int(maxValue))")
                    }
                    .gaugeStyle(.accessoryCircular)
                    
                default:
                    Gauge(value: value, in: minValue...maxValue) {}
                        .gaugeStyle(.accessoryCircularCapacity)
                }
            }
        )
    }

    func renderVStack() -> some View {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = VStack(alignment: horizontalAlignmentFromString(alignment), spacing: spacing) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentChildren.map { $0.id })
        return base
    }

    func renderStack() -> some View {
        let stackType = (component.getProperty(key: "stackType") as? String ?? "vertical").lowercased()
        switch stackType {
        case "horizontal":
            return AnyView(renderHStack())
        case "z":
            return AnyView(renderZStack())
        default:
            return AnyView(renderVStack())
        }
    }
    
    func renderHStack() -> some View {
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = HStack(alignment: verticalAlignmentFromString(alignment), spacing: spacing) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentChildren.map { $0.id })
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base)
    }
    
    func renderZStack() -> some View {
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = ZStack(alignment: alignmentFromString(alignment)) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: contentChildren.map { $0.id })
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base)
    }
    
    func renderSpacer() -> some View {
        return Spacer()
    }
    
    func renderDivider() -> some View {
        return Divider()
    }
    
    func renderRectangle() -> some View {
        return AnyView(Rectangle().foregroundStyle(.primary))
    }
    
    func renderCircle() -> some View {
        return AnyView(Circle().foregroundStyle(.primary))
    }
    
    func renderRoundedRectangle() -> some View {
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
        return AnyView(RoundedRectangle(cornerRadius: cornerRadius).foregroundStyle(.primary))
    }
    
    func renderCapsule() -> some View {
        return AnyView(Capsule().foregroundStyle(.primary))
    }
    
    func renderEllipse() -> some View {
        return AnyView(Ellipse().foregroundStyle(.primary))
    }
    
    func renderLinearGradient() -> some View {
        let colors = component.getProperty(key: "colors") as? [String] ?? ["blue", "green"]
        let startPointStr = component.getProperty(key: "startPoint") as? String ?? "top"
        let endPointStr = component.getProperty(key: "endPoint") as? String ?? "bottom"
        
        let gradientColors = colors.map { colorStr -> Color in
            let parts = colorStr.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "blue"
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            return ComponentProperty.colorStringToColor(colorName).opacity(opacity)
        }
        
        let startPoint = unitPointFromString(startPointStr)
        let endPoint = unitPointFromString(endPointStr)
        
        return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: startPoint, endPoint: endPoint)
    }
    
    func renderScrollView() -> some View {
        let axesString = component.getProperty(key: "axis") as? String ?? "vertical"
        let showsIndicators = component.getProperty(key: "showsIndicators") as? Bool ?? true
        
        let axes: Axis.Set = axesString == "horizontal" ? .horizontal : .vertical
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        
        let contentChildren = component.children.filter { $0.modifierId == nil }
        let content = Group {
            if axes == .horizontal {
                HStack(spacing: 8) {
                    ForEach(contentChildren, id: \.id) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                            onSelectChild?(child, additive)
                        }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                    }
                }
            } else {
                VStack(alignment: .center, spacing: 8) {
                    ForEach(contentChildren, id: \.id) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                            onSelectChild?(child, additive)
                        }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }

        if isScreenshotCapture {
            if axes == .horizontal {
                return AnyView(
                    HStack(spacing: 8) {
                        ForEach(contentChildren, id: \.id) { child in
                            ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                                onSelectChild?(child, additive)
                            }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            } else {
                return AnyView(
                    VStack(alignment: .center, spacing: 8) {
                        ForEach(contentChildren, id: \.id) { child in
                            ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                                onSelectChild?(child, additive)
                            }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture, canvasManager: canvasManager)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                )
            }
        }
        
        let base: AnyView = AnyView(
            ScrollView(axes, showsIndicators: showsIndicators) {
                content
            }
            #if os(macOS)
            .onHover { isHovering in
                canvasManager?.isHoveringScrollable = isHovering
            }
            #endif
        )
        
        if hasExplicitFrame {
            return AnyView(base.frame(width: component.frame.width, height: component.frame.height))
        }
        
        if axes == .horizontal {
            return AnyView(base.frame(minWidth: 160))
        } else {
            return AnyView(base.frame(minWidth: 120, minHeight: 160))
        }
    }
    
    func renderSFSymbol() -> some View {
        let rawSymbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        let symbolName = sfSymbolExists(rawSymbolName) ? rawSymbolName : "questionmark.circle"
        
        // Do not force local font/color fallback here.
        // This allows parent container modifiers (e.g. Font on VStack) to inherit correctly.
        return AnyView(
            Image(systemName: symbolName)
                .symbolRenderingMode(.monochrome)
        )
    }
    
    private func sfSymbolExists(_ name: String) -> Bool {
        #if os(macOS)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #else
        return UIImage(systemName: name) != nil
        #endif
    }
    
    func renderTextField() -> some View {
        let state = textFieldRenderState()
        return textFieldView(state: state)
    }
    
    private func textFieldRenderState() -> (displayText: String, isPlaceholder: Bool) {
        let text = component.getProperty(key: "text") as? String ?? ""
        let placeholder = component.getProperty(key: "placeholder") as? String ?? "Placeholder"
        
        let displayText = text.isEmpty ? placeholder : text
        let isPlaceholder = text.isEmpty
        return (displayText, isPlaceholder)
    }
    
    private func textFieldView(state: (displayText: String, isPlaceholder: Bool)) -> some View {
        Text(state.displayText)
            .foregroundColor(state.isPlaceholder ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(textFieldBackground)
            .padding(4)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?(false)
            }
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            .background(textFieldBackgroundFill)
    }
    
    private var textFieldBackgroundFill: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.white.opacity(0.8))
    }
    
    func renderToggle() -> some View {
        let isOn = component.getProperty(key: "isOn") as? Bool ?? true
        
        let binding = Binding<Bool>(
            get: { isOn },
            set: { newValue in
                if let canvasManager = canvasManager {
                    canvasManager.updateComponentProperty(for: component, key: "isOn", value: newValue)
                } else {
                    self.component.setProperty(key: "isOn", value: newValue)
                }
            }
        )
        
        return CustomSwitchView(isOn: binding)
            .padding(4)
    }
    
    func renderSlider() -> some View {
        let value = component.getProperty(key: "value") as? Double ?? 0.5
        let min = component.getProperty(key: "min") as? Double ?? 0.0
        let max = component.getProperty(key: "max") as? Double ?? 1.0
        
        let binding = Binding<Double>(
            get: { value },
            set: { newValue in
                if let canvasManager = canvasManager {
                    canvasManager.updateComponentProperty(for: component, key: "value", value: newValue)
                } else {
                    self.component.setProperty(key: "value", value: newValue)
                }
            }
        )
        
        return CustomSliderView(value: binding, range: min...max)
            .padding(.horizontal)
    }
    
    func renderProgressView() -> some View {
        let value = component.getProperty(key: "value") as? Double ?? 0.6
        let total = component.getProperty(key: "total") as? Double ?? 1.0
        let safeTotal = total > 0 ? total : 1.0
        let safeValue = min(max(value, 0), safeTotal)

        return AnyView(
            ProgressView(value: safeValue, total: safeTotal)
                .progressViewStyle(.linear)
                .frame(minWidth: 120)
                .padding(.horizontal, 4)
        )
    }

    func renderPlaceholder() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack {
                    Image(systemName: "questionmark")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text(component.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
    
    private func unitPointFromString(_ string: String) -> UnitPoint {
        switch string {
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        case "center": return .center
        case "topLeading": return .topLeading
        case "topTrailing": return .topTrailing
        case "bottomLeading": return .bottomLeading
        case "bottomTrailing": return .bottomTrailing
        default: return .top
        }
    }

}

private extension Image {
    func resizableIfNeeded(_ needed: Bool) -> some View {
        needed ? AnyView(self.resizable()) : AnyView(self)
    }
}

extension View {
    func applyOverlayChildren(_ overlayChildren: [UIComponent], deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> some View {
        var view = AnyView(self)
        
        for overlayChild in overlayChildren {
            let overlayView = ComponentRenderer(
                component: overlayChild,
                deviceSize: deviceSize,
                colorScheme: colorScheme,
                onTap: { additive in
                    onSelectChild?(overlayChild, additive)
                },
                onSelectChild: onSelectChild,
                selectedComponentIds: selectedComponentIds
            )
            
            let alignment = Alignment.topTrailing
            view = AnyView(view.overlay(overlayView, alignment: alignment))
        }
        
        return view
    }
    
    func applyModifiers(_ modifiers: [ComponentModifier], component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>, isScreenshotCapture: Bool = false) -> some View {
        var view = AnyView(self)

        for modifier in orderedModifiersForRendering(modifiers) {
            view = AnyView(applyModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture))
        }
        
        return view
    }

    private func orderedModifiersForRendering(_ modifiers: [ComponentModifier]) -> [ComponentModifier] {
        let effectTypes: Set<ModifierType> = [.opacity, .shadow, .blur, .glassEffect, .clipShape]
        let fillTypes: Set<ModifierType> = [.fill, .foregroundColor, .tint]
        let layoutTypes: Set<ModifierType> = [.frame, .padding, .rotation, .offset]

        return modifiers
            .enumerated()
            .sorted { lhs, rhs in
                let lhsPriority = modifierRenderPriority(lhs.element.type, fillTypes: fillTypes, layoutTypes: layoutTypes, effectTypes: effectTypes)
                let rhsPriority = modifierRenderPriority(rhs.element.type, fillTypes: fillTypes, layoutTypes: layoutTypes, effectTypes: effectTypes)
                if lhsPriority == rhsPriority {
                    return lhs.offset < rhs.offset
                }
                return lhsPriority < rhsPriority
            }
            .map(\.element)
    }

    private func modifierRenderPriority(
        _ type: ModifierType,
        fillTypes: Set<ModifierType>,
        layoutTypes: Set<ModifierType>,
        effectTypes: Set<ModifierType>
    ) -> Int {
        if fillTypes.contains(type) { return 0 }
        if layoutTypes.contains(type) { return 1 }
        if type == .backgroundColor { return 2 }
        if type == .cornerRadius { return 3 }
        if effectTypes.contains(type) { return 4 }
        return 2
    }
    
    private func parseColorWithOpacity(modifier: ComponentModifier) -> (Color, Double) {
        if let colorData = modifier.properties["color"] as? String {
            let parts = colorData.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "primary"
            let color = ComponentProperty.colorStringToColor(colorName)
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            return (color, opacity)
        }
        return (.primary, 1.0)
    }
    
    private func resolveStrokeCornerRadius(for component: UIComponent) -> CGFloat {
        if let radius = component.getProperty(key: "cornerRadius") as? CGFloat {
            return radius
        }
        if let radius = component.getProperty(key: "cornerRadius") as? Double {
            return CGFloat(radius)
        }
        if let radiusModifier = component.modifiers.first(where: { $0.type == .cornerRadius }) {
            return radiusModifier.getCGFloat(key: "radius", defaultValue: 0)
        }
        return 0
    }
    
    private func strokeShapeView(for component: UIComponent, color: Color, lineWidth: CGFloat) -> AnyView {
        if component.type == .shape {
            let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"
            switch shapeType {
            case "Circle":
                return AnyView(Circle().stroke(color, lineWidth: lineWidth))
            case "Capsule":
                return AnyView(Capsule().stroke(color, lineWidth: lineWidth))
            case "Ellipse":
                return AnyView(Ellipse().stroke(color, lineWidth: lineWidth))
            case "Rounded Rectangle":
                let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
                return AnyView(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
            default:
                return AnyView(Rectangle().stroke(color, lineWidth: lineWidth))
            }
        }
        
        switch component.type {
        case .roundedRectangle:
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return AnyView(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
        case .circle:
            return AnyView(Circle().stroke(color, lineWidth: lineWidth))
        case .capsule:
            return AnyView(Capsule().stroke(color, lineWidth: lineWidth))
        case .ellipse:
            return AnyView(Ellipse().stroke(color, lineWidth: lineWidth))
        case .rectangle:
            return AnyView(Rectangle().stroke(color, lineWidth: lineWidth))
        default:
            let cornerRadius = resolveStrokeCornerRadius(for: component)
            if cornerRadius > 0 {
                return AnyView(RoundedRectangle(cornerRadius: cornerRadius).stroke(color, lineWidth: lineWidth))
            }
            return AnyView(Rectangle().stroke(color, lineWidth: lineWidth))
        }
    }
    
    private func applyModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>, isScreenshotCapture: Bool = false) -> AnyView {
        switch modifier.type {
        case .frame:
            return applyFrameModifier(modifier, to: view, component: component, deviceSize: deviceSize)
            
        case .padding:
            return applyPaddingModifier(modifier, to: view)
            
        case .background:
            return applyBackgroundModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            
        case .backgroundColor:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.background(gradient))
            }
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.background(color.opacity(opacity)))
            
        case .foregroundColor:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.foregroundStyle(gradient))
            }
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.foregroundStyle(color.opacity(opacity)))
            
        case .font:
            return applyFontModifier(modifier, to: view, deviceSize: deviceSize)
            
        case .fill:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.foregroundStyle(gradient))
            }
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.foregroundStyle(color.opacity(opacity)))
        case .tint:
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.tint(color.opacity(opacity)))
            
        case .cornerRadius:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.cornerRadius(radius))

        case .shadow:
            return applyShadowModifier(modifier, to: view)
            
        case .opacity:
            let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            return AnyView(view.opacity(opacity))
            
        case .rotation:
            let angle = modifier.getDouble(key: "angle", defaultValue: 0)
            return AnyView(view.rotationEffect(.degrees(angle)))
            
        case .offset:
            return applyOffsetModifier(modifier, to: view)

        case .blur:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.blur(radius: radius))
            
        case .overlay:
            return applyOverlayModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            
        case .border:
            let width = modifier.getCGFloat(key: "width", defaultValue: 1)
            let color = modifier.getColor(key: "color", defaultValue: .primary)
            return AnyView(view.border(color, width: width))
            
        case .stroke:
            let lineWidth = modifier.getCGFloat(key: "lineWidth", defaultValue: 1)
            let color = modifier.getColor(key: "color", defaultValue: .primary)
            return AnyView(
                view.overlay(
                    strokeShapeView(for: component, color: color, lineWidth: lineWidth)
                )
            )
            
        case .clipShape:
            return applyClipShapeModifier(modifier, to: view)
            
        case .mask:
            return applyMaskModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            
        case .textAlignment:
            let alignment = modifier.properties["alignment"] as? String ?? "leading"
            let textAlignment = multilineTextAlignmentFromString(alignment)
            return AnyView(view.multilineTextAlignment(textAlignment))

        case .glassEffect:
            if isScreenshotCapture, component.type == .shape {
                let shapeName = normalizedGlassShapeName(from: modifier)
                let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)
                return AnyView(screenshotGlassShapeFallback(baseView: view, shapeName: shapeName, radius: radius))
            }

            if #available(iOS 26.0, macOS 26.0, *) {
                let hasExplicitTextColor = component.modifiers.contains { mod in
                    mod.type == .fill || mod.type == .foregroundColor || mod.type == .tint
                }
                let baseView: AnyView
                if component.type == .text && !hasExplicitTextColor {
                    let canvasPrimaryColor: Color = (colorScheme == .dark) ? .white : .black
                    baseView = AnyView(view.foregroundStyle(canvasPrimaryColor))
                } else {
                    baseView = view
                }

                let shapeName = normalizedGlassShapeName(from: modifier)
                switch shapeName {
                case "Circle":
                    return AnyView(baseView.glassEffect(.regular, in: Circle()))
                case "Capsule":
                    return AnyView(baseView.glassEffect(.regular, in: Capsule()))
                case "RoundedRectangle":
                    let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)
                    return AnyView(baseView.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius)))
                case "Ellipse":
                    return AnyView(baseView.glassEffect(.regular, in: Ellipse()))
                case "Rectangle":
                    return AnyView(baseView.glassEffect(.regular, in: Rectangle()))
                default:
                    return AnyView(baseView.glassEffect())
                }
            }
            return view
        }
    }

    private func screenshotGlassShapeFallback(baseView: AnyView, shapeName: String, radius: CGFloat) -> some View {
        let fillColor = Color.white.opacity(0.16)
        let strokeColor = Color.white.opacity(0.35)

        switch shapeName {
        case "Circle":
            return AnyView(
                baseView
                    .background(Circle().fill(fillColor))
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            )
        case "Capsule":
            return AnyView(
                baseView
                    .background(Capsule().fill(fillColor))
                    .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
            )
        case "RoundedRectangle":
            return AnyView(
                baseView
                    .background(RoundedRectangle(cornerRadius: radius).fill(fillColor))
                    .overlay(RoundedRectangle(cornerRadius: radius).stroke(strokeColor, lineWidth: 1))
            )
        case "Ellipse":
            return AnyView(
                baseView
                    .background(Ellipse().fill(fillColor))
                    .overlay(Ellipse().stroke(strokeColor, lineWidth: 1))
            )
        default:
            return AnyView(
                baseView
                    .background(Rectangle().fill(fillColor))
                    .overlay(Rectangle().stroke(strokeColor, lineWidth: 1))
            )
        }
    }

    private func applyFrameModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?) -> AnyView {
        let values = frameModifierValues(from: modifier)
        guard values.widthType != "Default" || values.heightType != "Default" else {
            return view
        }

        let limits = frameDeviceLimits(deviceSize: deviceSize)
        var modifiedView = view
        modifiedView = applyFrameWidth(values: values, limits: limits, component: component, to: modifiedView)
        modifiedView = applyFrameHeight(values: values, limits: limits, to: modifiedView)
        return modifiedView
    }
    
    private func frameModifierValues(from modifier: ComponentModifier) -> (widthType: String, heightType: String, width: CGFloat, height: CGFloat) {
        (
            widthType: normalizedFrameType(modifier.properties["widthType"] as? String),
            heightType: normalizedFrameType(modifier.properties["heightType"] as? String),
            width: modifier.getCGFloat(key: "width", defaultValue: 100),
            height: modifier.getCGFloat(key: "height", defaultValue: 100)
        )
    }

    private func normalizedFrameType(_ value: String?) -> String {
        ["Default", "Full", "Custom"].contains(value ?? "") ? (value ?? "Default") : "Default"
    }
    
    private func frameDeviceLimits(deviceSize: CGSize?) -> (maxWidth: CGFloat, maxHeight: CGFloat, isContentAdaptive: Bool) {
        let width = deviceSize?.width ?? 1000
        let height = deviceSize?.height ?? 1000
        let isContentAdaptive = deviceSize == nil || (width == 0 && height == 0)
        return (maxWidth: width, maxHeight: height, isContentAdaptive: isContentAdaptive)
    }
    
    private func applyFrameWidth(
        values: (widthType: String, heightType: String, width: CGFloat, height: CGFloat),
        limits: (maxWidth: CGFloat, maxHeight: CGFloat, isContentAdaptive: Bool),
        component: UIComponent,
        to view: AnyView
    ) -> AnyView {
        let alignment = horizontalFrameAlignment(for: component)
        switch values.widthType {
        case "Full":
            let maxWidth = limits.isContentAdaptive ? CGFloat.infinity : limits.maxWidth
            return AnyView(view.frame(maxWidth: maxWidth, alignment: alignment))
        case "Custom":
            let width = limits.isContentAdaptive ? values.width : min(values.width, limits.maxWidth)
            return AnyView(view.frame(width: width, alignment: alignment))
        default:
            return view
        }
    }

    private func horizontalFrameAlignment(for component: UIComponent) -> Alignment {
        let rawAlignment = (component.getProperty(key: "alignment") as? String ?? "").lowercased()
        switch rawAlignment {
        case "leading":
            return .leading
        case "trailing":
            return .trailing
        case "center":
            return .center
        default:
            break
        }

        if component.type == .text,
           let modifier = component.modifiers.first(where: { $0.type == .textAlignment }) {
            let rawTextAlignment = (modifier.properties["alignment"] as? String ?? "leading").lowercased()
            switch rawTextAlignment {
            case "center":
                return .center
            case "trailing":
                return .trailing
            default:
                return .leading
            }
        }
        return .center
    }
    
    private func applyFrameHeight(
        values: (widthType: String, heightType: String, width: CGFloat, height: CGFloat),
        limits: (maxWidth: CGFloat, maxHeight: CGFloat, isContentAdaptive: Bool),
        to view: AnyView
    ) -> AnyView {
        switch values.heightType {
        case "Full":
            let maxHeight = limits.isContentAdaptive ? CGFloat.infinity : limits.maxHeight
            return AnyView(view.frame(maxHeight: maxHeight))
        case "Custom":
            let height = limits.isContentAdaptive ? values.height : min(values.height, limits.maxHeight)
            return AnyView(view.frame(height: height))
        default:
            return view
        }
    }
    
    private func applyPaddingModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let amount = modifier.getCGFloat(key: "amount", defaultValue: 0)
        let location = modifier.properties["location"] as? String ?? "all"

        switch location {
        case "all":
            return AnyView(view.padding(amount))
        case "leading":
            return AnyView(view.padding(.leading, amount))
        case "trailing":
            return AnyView(view.padding(.trailing, amount))
        case "top":
            return AnyView(view.padding(.top, amount))
        case "bottom":
            return AnyView(view.padding(.bottom, amount))
        case "horizontal":
            return AnyView(view.padding(.horizontal, amount))
        case "vertical":
            return AnyView(view.padding(.vertical, amount))
        default:
            return AnyView(view.padding(amount))
        }
    }

    private func applyBackgroundModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        guard let attachedView = attachedComponentView(for: modifier, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds) else {
            return AnyView(view)
        }
        return AnyView(view.background(attachedView))
    }

    private func applyOverlayModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        guard let attachedView = attachedComponentView(for: modifier, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds) else {
            return view
        }
        let alignment = alignmentFromString(modifier.properties["alignment"] as? String ?? "center")
        return AnyView(view.overlay(attachedView, alignment: alignment))
    }

    private func applyMaskModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        if let attachedView = attachedComponentView(for: modifier, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds) {
            return AnyView(view.mask(attachedView))
        }

        let shapeName = modifier.properties["shape"] as? String ?? "Rectangle"
        switch shapeName {
        case "Circle":
            return AnyView(view.mask(Circle()))
        case "Capsule":
            return AnyView(view.mask(Capsule()))
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return AnyView(view.mask(RoundedRectangle(cornerRadius: radius)))
        default:
            return AnyView(view.mask(Rectangle()))
        }
    }

    private func attachedComponentView(for modifier: ComponentModifier, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView? {
        guard let parentComponent = component.getParentComponentForModifier(modifier.id) else { return nil }

        let renderer = ComponentRenderer(
            component: parentComponent,
            deviceSize: deviceSize,
            colorScheme: colorScheme,
            onTap: { additive in
                onSelectChild?(parentComponent, additive)
            },
            onSelectChild: onSelectChild,
            selectedComponentIds: selectedComponentIds
        )
        return AnyView(renderer)
    }

    private func applyFontModifier(_ modifier: ComponentModifier, to view: AnyView, deviceSize: CGSize?) -> AnyView {
        let size = modifier.properties["fontSize"]
        let weight = modifier.properties["fontWeight"] as? String ?? "regular"
        let design = modifier.properties["fontDesign"] as? String
        let fontWeight = fontWeightFromString(weight)
        let fontDesign = fontDesignFromString(design)

        if let sizeStr = size as? String, let customSize = Double(sizeStr) {
            let effectiveSize = max(1.0, customSize)
            let font = Font.system(size: effectiveSize, weight: fontWeight, design: fontDesign)
            return AnyView(view.font(font))
        }

        let namedSize = (size as? String) ?? "body"
        let font = createIOSFont(for: namedSize, weight: fontWeight, design: fontDesign, deviceSize: deviceSize)
        return AnyView(view.font(font))
    }

    private func applyShadowModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
        let x = getModifierCGFloat(modifier, primaryKey: "offsetX", fallbackKey: "x", defaultValue: 0)
        let y = getModifierCGFloat(modifier, primaryKey: "offsetY", fallbackKey: "y", defaultValue: 0)

        var color = modifier.getColor(key: "color", defaultValue: .black)
        if let opacity = modifier.properties["opacity"] as? Double {
            color = color.opacity(opacity)
        }

        return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
    }

    private func applyOffsetModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let x = getModifierCGFloat(modifier, primaryKey: "offsetX", fallbackKey: "x", defaultValue: 0)
        let y = getModifierCGFloat(modifier, primaryKey: "offsetY", fallbackKey: "y", defaultValue: 0)
        return AnyView(view.offset(x: x, y: y))
    }

    private func applyClipShapeModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        let shapeName = normalizedClipShapeName(from: modifier)
        switch shapeName {
        case "Circle":
            return AnyView(view.clipShape(Circle()))
        case "Capsule":
            return AnyView(view.clipShape(Capsule()))
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
        case "Ellipse":
            return AnyView(view.clipShape(Ellipse()))
        default:
            return AnyView(view.clipShape(Rectangle()))
        }
    }

    private func normalizedClipShapeName(from modifier: ComponentModifier) -> String {
        let rawShape = (modifier.properties["shape"] as? String)
            ?? (modifier.properties["shapeType"] as? String)
            ?? "Rectangle"
        if rawShape.lowercased() == "roundedrectangle" {
            return "RoundedRectangle"
        }
        return rawShape.prefix(1).uppercased() + rawShape.dropFirst()
    }


    private func normalizedGlassShapeName(from modifier: ComponentModifier) -> String {
        guard let rawShape = (modifier.properties["shape"] as? String) ?? (modifier.properties["shapeType"] as? String),
              !rawShape.isEmpty else {
            return ""
        }

        if rawShape.lowercased() == "roundedrectangle" {
            return "RoundedRectangle"
        }
        return rawShape.prefix(1).uppercased() + rawShape.dropFirst()
    }

    private func multilineTextAlignmentFromString(_ alignment: String) -> TextAlignment {
        switch alignment {
        case "leading":
            return .leading
        case "center":
            return .center
        case "trailing":
            return .trailing
        default:
            return .leading
        }
    }

    private func getModifierCGFloat(_ modifier: ComponentModifier, primaryKey: String, fallbackKey: String, defaultValue: CGFloat) -> CGFloat {
        if let value = modifier.properties[primaryKey] as? CGFloat {
            return value
        }
        if let value = modifier.properties[primaryKey] as? Double {
            return CGFloat(value)
        }
        return modifier.getCGFloat(key: fallbackKey, defaultValue: defaultValue)
    }
    
}

fileprivate func fontWeightFromString(_ weight: String) -> Font.Weight {
    switch weight {
    case "ultraLight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .regular
    }
}

fileprivate func alignmentFromString(_ alignment: String) -> Alignment {
    switch alignment {
    case "topLeading": return .topLeading
    case "top": return .top
    case "topTrailing": return .topTrailing
    case "leading": return .leading
    case "center": return .center
    case "trailing": return .trailing
    case "bottomLeading": return .bottomLeading
    case "bottom": return .bottom
    case "bottomTrailing": return .bottomTrailing
    default: return .center
    }
}

fileprivate func horizontalAlignmentFromString(_ alignment: String) -> HorizontalAlignment {
    switch alignment {
    case "leading": return .leading
    case "trailing": return .trailing
    case "center": return .center
    default: return .center
    }
}

fileprivate func verticalAlignmentFromString(_ alignment: String) -> VerticalAlignment {
    switch alignment {
    case "top": return .top
    case "bottom": return .bottom
    case "center": return .center
    case "firstTextBaseline": return .firstTextBaseline
    case "lastTextBaseline": return .lastTextBaseline
    default: return .center
    }
}

fileprivate func createIOSFont(for fontSize: String, weight: Font.Weight, design: Font.Design, deviceSize: CGSize?) -> Font {
    let deviceWidth = deviceSize?.width ?? 393 // Default to iPhone
    let isiPad = deviceWidth >= 700 && deviceWidth < 1200 // iPad range: 834-1024
    let isMac = deviceWidth >= 1200 // Mac: 1280+
    
    let size: CGFloat
    switch fontSize {
    case "largeTitle":
        if isMac { size = 40 } // macOS Large Title: 40pt
        else if isiPad { size = 40 } // iPad Large Title: 40pt
        else { size = 34 } // iOS Large Title: 34pt
    case "title":
        if isMac { size = 32 } // macOS Title 1: 32pt
        else if isiPad { size = 34 } // iPad Title 1: 34pt
        else { size = 28 } // iOS Title 1: 28pt
    case "title2":
        if isMac { size = 24 } // macOS Title 2: 24pt
        else if isiPad { size = 28 } // iPad Title 2: 28pt
        else { size = 22 } // iOS Title 2: 22pt
    case "title3":
        if isMac { size = 20 } // macOS Title 3: 20pt
        else if isiPad { size = 22 } // iPad Title 3: 22pt
        else { size = 20 } // iOS Title 3: 20pt
    case "headline":
        size = isMac ? 18 : 17 // macOS: 18pt, iOS/iPad: 17pt (default semibold, but overridable)
        return .system(size: size, weight: weight, design: design)
    case "body":
        size = isMac ? 15 : 17 // macOS: 15pt, iOS/iPad: 17pt
    case "callout":
        size = isMac ? 14 : 16 // macOS: 14pt, iOS/iPad: 16pt
    case "subheadline":
        size = isMac ? 13 : 15 // macOS: 13pt, iOS/iPad: 15pt
    case "footnote":
        size = isMac ? 12 : 13 // macOS: 12pt, iOS/iPad: 13pt
    case "caption":
        size = isMac ? 11 : 12 // macOS: 11pt, iOS/iPad: 12pt
    case "caption2":
        size = isMac ? 10 : 11 // macOS: 10pt, iOS/iPad: 11pt
    default:
        size = isMac ? 15 : 17 // Default to body
    }
    
    return .system(size: size, weight: weight, design: design)
}

struct RemoteImageComponentView: View {
    let url: URL
    let resizable: Bool
    let aspectRatio: String
    let deviceSize: CGSize?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.25))
                    .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
            case .failure(_):
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.22))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.7))
                    )
                    .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
            case .success(let image):
                let base = resizable ? image.resizable() : image
                Group {
                    if aspectRatio == "fit" {
                        base.aspectRatio(contentMode: .fit)
                            .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                    } else if aspectRatio == "fill" {
                        base.aspectRatio(contentMode: .fill)
                            .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                            .clipped()
                    } else {
                        base.frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                    }
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}

struct ImageComponentView: View {
    let imageName: String
    let resizable: Bool
    let aspectRatio: String
    let deviceSize: CGSize?
    
    var body: some View {
        if !imageName.isEmpty, let platformImage = ImageGalleryManager.shared.loadImage(filename: imageName) {
            #if os(macOS)
            let imageView = Image(nsImage: platformImage)
            #else
            let imageView = Image(uiImage: platformImage)
            #endif
            
            let modifiedImage = resizable ? imageView.resizable() : imageView
            
            Group {
                if aspectRatio == "fit" {
                    modifiedImage.aspectRatio(contentMode: .fit)
                        .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                } else if aspectRatio == "fill" {
                    modifiedImage.aspectRatio(contentMode: .fill)
                        .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                        .clipped()
                } else {
                    modifiedImage
                        .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                }
            }
        } else {
            EmptyView()
        }
    }
}

fileprivate struct CustomSwitchView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Capsule()
            .fill(isOn ? Color.green : Color.gray.opacity(0.5))
            .frame(width: 51, height: 31)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .padding(2)
                    .offset(x: isOn ? 10 : -10)
            )
            .animation(.spring(response: 0.3), value: isOn)
            .onTapGesture {
                withAnimation {
                    isOn.toggle()
                }
            }
    }
}

fileprivate struct CustomSliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let denominator = range.upperBound - range.lowerBound
            let percentage = denominator == 0 ? 0 : (value - range.lowerBound) / denominator
            let thumbX = width * CGFloat(percentage)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: thumbX, height: 4)
                
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .frame(width: 20, height: 20)
                    .offset(x: thumbX - 10)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                let x = gestureValue.location.x
                                let newPercentage = min(max(x / width, 0), 1)
                                self.value = range.lowerBound + (newPercentage * (range.upperBound - range.lowerBound))
                            }
                    )
            }
            .frame(height: 30, alignment: .center)
        }
        .frame(height: 30)
    }
}

fileprivate func fontDesignFromString(_ design: String?) -> Font.Design {
    switch design {
    case "default": return .default
    case "serif": return .serif
    case "rounded": return .rounded
    case "monospaced": return .monospaced
    default: return .default
    }
}

extension View {
    @ViewBuilder
    func applyButtonStyle(_ style: String) -> some View {
        switch style {
        case "bordered":
            self.buttonStyle(.bordered)
        case "borderedProminent":
            self.buttonStyle(.borderedProminent)
        case "borderless":
            self.buttonStyle(.borderless)
        case "plain":
            self.buttonStyle(.plain)
        default:
            self.buttonStyle(.borderedProminent)
        }
    }
}
