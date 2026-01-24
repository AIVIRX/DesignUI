//
//  ComponentRenderer.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct ComponentRenderer: View {
    @ObservedObject var component: UIComponent
    let deviceSize: CGSize?
    let colorScheme: ColorScheme?
    let onTap: ((Bool) -> Void)?
    let onSelectChild: ((UIComponent, Bool) -> Void)?
    let selectedComponentIds: Set<UUID>
    // Optional CanvasManager for scroll frame reporting
    var canvasManager: CanvasManager? = nil
    
    @State private var isHovered: Bool = false
    @State private var forceRefresh: Int = 0
    @State private var hasAppliedModifiers: Bool = false
    
    init(component: UIComponent, deviceSize: CGSize? = nil, colorScheme: ColorScheme? = nil, onTap: ((Bool) -> Void)? = nil, onSelectChild: ((UIComponent, Bool) -> Void)? = nil, selectedComponentIds: Set<UUID> = [], canvasManager: CanvasManager? = nil) {
        self.component = component
        self.deviceSize = deviceSize
        self.colorScheme = colorScheme
        self.onTap = onTap
        self.onSelectChild = onSelectChild
        self.selectedComponentIds = selectedComponentIds
        self.canvasManager = canvasManager
    }
    
    var body: some View {
        Group {
            switch component.type {
            case .text:
                renderText()
            case .image:
                renderImage()
            case .vstack:
                renderVStack()
            case .hstack:
                renderHStack()
            case .zstack:
                renderZStack()
            case .spacer:
                renderSpacer()
            case .divider:
                renderDivider()
            case .rectangle:
                renderRectangle()
            case .circle:
                renderCircle()
            case .roundedRectangle:
                renderRoundedRectangle()
            case .capsule:
                renderCapsule()
            case .ellipse:
                renderEllipse()
            case .scrollView:
                renderScrollView()
            case .sfSymbol:
                renderSFSymbol()
            case .textField:
                renderTextField()
            case .toggle:
                renderToggle()
            case .slider:
                renderSlider()
            case .linearGradient:
                renderLinearGradient()
            default:
                renderPlaceholder()
            }
        }
        .opacity(component.isVisible ? 1.0 : 0.0)
        .applyModifiers(component.modifiers, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
        .applyOverlayChildren(component.getOverlayChildren(), deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
        .colorScheme(colorScheme ?? .light)
        .contentShape(Rectangle())
        .id(component.id)
        .onAppear {
            hasAppliedModifiers = true
        }
        .overlay(
            // Selection and hover overlays for child components
            Group {
                if selectedComponentIds.contains(component.id) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 2)
                        .allowsHitTesting(false)
                } else if isHovered && onSelectChild != nil && component.children.isEmpty {
                    // Only show hover for leaf components (components without children)
                    // Solid stroke, thinner than selected
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    // Detect Cmd key for additive selection
                    #if os(macOS)
                    let additive = NSEvent.modifierFlags.contains(.command)
                    #else
                    let additive = false
                    #endif
                    onTap?(additive)
                }
        )
    }
    
    private func isContainerComponent(_ type: ComponentType) -> Bool {
        switch type {
        case .vstack, .hstack, .zstack, .scrollView:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Text Renderer
    private func renderText() -> some View {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        // Don't set a default font - let fontSize modifier handle it
        // This allows parent stack's fontSize to propagate to text children
        return Text(text)
    }
    
    // MARK: - Platform Font Helper
    // Returns platform-specific font sizes per Apple Human Interface Guidelines
    // Reference: https://developer.apple.com/design/human-interface-guidelines/typography
    private func iosFont(for fontSize: String, weight: Font.Weight, deviceSize: CGSize? = nil) -> Font {
        return createIOSFont(for: fontSize, weight: weight, deviceSize: deviceSize ?? self.deviceSize)
    }
    
    // MARK: - Image Renderer
    private func renderImage() -> some View {
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        
        // Check for image name (could be URL or local filename)
        var imageName = component.getProperty(key: "imageName") as? String ?? ""
        
        // Fallback: check if imageData contains a filename (for old components without imageName property)
        if imageName.isEmpty {
            let imageData = component.getProperty(key: "imageData") as? String ?? ""
            
            // IF imageData is not empty, check if it's actually a filename
            if !imageData.isEmpty {
                // 1. Check if it looks like a file extension
                if imageData.hasSuffix(".jpg") || imageData.hasSuffix(".jpeg") || imageData.hasSuffix(".png") || imageData.hasSuffix(".gif") || imageData.hasSuffix(".heic") {
                    imageName = imageData
                }
                // 2. Check if it matches a valid local gallery image OR bundled asset
                else if ImageGalleryManager.shared.getAllImageFilenames().contains(imageData) {
                     // It is a valid filename (even without extension, e.g. bundled asset "image1")
                     imageName = imageData
                }
            }
        }
        
        // Priority 0: Check Local Gallery first (if file exists)
        if !imageName.isEmpty && ImageGalleryManager.shared.imageExists(filename: imageName) {
             return AnyView(ImageComponentView(
                imageName: imageName,
                resizable: resizable,
                aspectRatio: aspectRatio,
                deviceSize: deviceSize
             ))
        }
        
        // Priority 1: Check if base64 image data exists (local images legacy / pasted)
        if let imageDataString = component.getProperty(key: "imageData") as? String,
           !imageDataString.isEmpty {
            // Try to decode base64 image data with options to handle invalid data gracefully
            if let imageData = Data(base64Encoded: imageDataString, options: .ignoreUnknownCharacters),
               !imageData.isEmpty {
                // Create image from validated data
                if let image = createImage(from: imageData) {
                    // Use custom image - constrain size to device bounds to prevent canvas expansion
                    let maxWidth = deviceSize?.width ?? 1000
                    let maxHeight = deviceSize?.height ?? 1000
                    
                    #if os(macOS)
                    let imageSize = getImageSize(image)
                    let imageAspectRatio = imageSize.width > 0 && imageSize.height > 0 ? imageSize.width / imageSize.height : nil
                    
                    var view: AnyView = AnyView(Image(nsImage: image)
                        .resizableIfNeeded(resizable))
                    
                    // Apply aspect ratio based on mode
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
                    
                    // Apply aspect ratio based on mode
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
                    #endif
                    
                    view = AnyView(view.frame(maxWidth: maxWidth, maxHeight: maxHeight))
                }
            }
        }
        
        // Fallback to placeholder
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
        // Validate data is not empty
        guard !data.isEmpty else {
            print("⚠️ Image data is empty")
            return nil
        }
        
        // Create image from data
        guard let image = NSImage(data: data) else {
            print("⚠️ Failed to create NSImage from data")
            return nil
        }
        
        // Validate the image is valid and can be used
        guard image.isValid else {
            print("⚠️ NSImage is invalid")
            return nil
        }
        
        return image
    }
    #else
    private func createImage(from data: Data) -> UIImage? {
        // Validate data is not empty
        guard !data.isEmpty else {
            print("⚠️ Image data is empty")
            return nil
        }
        
        // Create image from data
        guard let image = UIImage(data: data) else {
            print("⚠️ Failed to create UIImage from data")
            return nil
        }
        
        // Validate the image has valid size
        guard image.size.width > 0 && image.size.height > 0 else {
            print("⚠️ UIImage has invalid size")
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
    
    // MARK: - Button Renderer
    private func renderButton() -> some View {
        // If button has children, render them inside the button (container approach)
        // If button has children, render them inside the button (container approach)
        // Filter out modifier children (masks, overlays, backgrounds)
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        if !contentChildren.isEmpty {
            return AnyView(
                Button(action: {}) {
                    ForEach(contentChildren, id: \.id) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                            onSelectChild?(child, additive)
                        }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
                    }
                }
                    .buttonStyle(PlainButtonStyle())
            )
        }
        
        // No children: Use default SwiftUI button with label-based initializer and apply properties
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.blue
        
        // Check if there's a frame modifier with full width
        let hasFullWidthFrame = component.modifiers.contains { modifier in
            if modifier.type == .frame {
                let widthType = modifier.properties["widthType"] as? String ?? "Default"
                return widthType == "Full"
            }
            return false
        }
        
        // Detect device type for platform-specific button font size
        let deviceWidth = deviceSize?.width ?? 393
        let isMac = deviceWidth >= 1200
        let buttonFontSize: CGFloat = isMac ? 15 : 17 // macOS: 15pt, iOS/iPad: 17pt
        
        return AnyView(
            Button(action: {}) {
                Text(title)
                    .font(.system(size: buttonFontSize, weight: .regular))
                    .padding(8)
                    .frame(maxWidth: hasFullWidthFrame ? .infinity : nil)
            }
                .background(backgroundColor)
                .buttonStyle(PlainButtonStyle())
        )
    }
    
    // MARK: - VStack Renderer
    private func renderVStack() -> some View {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        
        // Filter out modifier children (masks, overlays, backgrounds)
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = VStack(alignment: horizontalAlignmentFromString(alignment), spacing: spacing) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
                }
            }
        }
        return base
    }
    
    // MARK: - HStack Renderer
    private func renderHStack() -> some View {
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        
        // Filter out modifier children (masks, overlays, backgrounds)
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = HStack(alignment: verticalAlignmentFromString(alignment), spacing: spacing) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
                }
            }
        }
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base)
    }
    
    // MARK: - ZStack Renderer
    private func renderZStack() -> some View {
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        // Filter out modifier children (masks, overlays, backgrounds)
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        let base = ZStack(alignment: alignmentFromString(alignment)) {
            if contentChildren.isEmpty {
                EmptyView()
            } else {
                ForEach(contentChildren, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                        onSelectChild?(child, additive)
                    }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
                }
            }
        }
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base)
    }
    
    // MARK: - Spacer Renderer
    private func renderSpacer() -> some View {
        return Spacer()
    }
    
    // MARK: - Divider Renderer
    private func renderDivider() -> some View {
        return Divider()
    }
    
    // MARK: - Shape Renderers
    private func renderRectangle() -> some View {
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Rectangle()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Rectangle())
        }
    }
    
    private func renderCircle() -> some View {
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Circle()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Circle())
        }
    }
    
    private func renderRoundedRectangle() -> some View {
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
        
        if stroke != Color.clear {
            return AnyView(RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
    
    private func renderCapsule() -> some View {
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Capsule()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Capsule())
        }
    }
    
    private func renderEllipse() -> some View {
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Ellipse()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Ellipse())
        }
    }
    
    // MARK: - Linear Gradient Renderer
    private func renderLinearGradient() -> some View {
        let colors = component.getProperty(key: "colors") as? [String] ?? ["blue", "green"]
        let startPointStr = component.getProperty(key: "startPoint") as? String ?? "top"
        let endPointStr = component.getProperty(key: "endPoint") as? String ?? "bottom"
        
        // Convert strings to Color objects, parsing "colorname:opacity" format
        let gradientColors = colors.map { colorStr -> Color in
            let parts = colorStr.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "blue"
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            return ComponentProperty.colorStringToColor(colorName).opacity(opacity)
        }
        
        // Convert strings to UnitPoints
        let startPoint = unitPointFromString(startPointStr)
        let endPoint = unitPointFromString(endPointStr)
        
        return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: startPoint, endPoint: endPoint)
    }
    
    // MARK: - ScrollView Renderer
    private func renderScrollView() -> some View {
        let axesString = component.getProperty(key: "axes") as? String ?? "vertical"
        let showsIndicators = component.getProperty(key: "showsIndicators") as? Bool ?? true
        
        let axes: Axis.Set = axesString == "horizontal" ? .horizontal : .vertical
        
        // Filter out modifier children (masks, overlays, backgrounds)
        let contentChildren = component.children.filter { $0.modifierId == nil }
        
        return AnyView(
            ScrollView(axes, showsIndicators: showsIndicators) {
                if axes == .horizontal {
                    HStack(spacing: 8) {
                        ForEach(contentChildren, id: \.id) { child in
                            ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                                onSelectChild?(child, additive)
                            }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(contentChildren, id: \.id) { child in
                            ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: { additive in
                                onSelectChild?(child, additive)
                            }, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
                        }
                    }
                }
            }
            #if os(macOS)
            .onHover { isHovering in
                // Simply track if we're hovering over this scrollable component
                canvasManager?.isHoveringScrollable = isHovering
            }
            #endif
        )
    }
    

    // MARK: - SF Symbol Renderer
    // MARK: - SF Symbol Renderer
    private func renderSFSymbol() -> some View {
        let symbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        let isResizable = component.getProperty(key: "resizable") as? Bool ?? false
        // Check if there's a font modifier - if so, don't set default font
        let hasFontModifier = component.modifiers.contains { $0.type == .font }
        // Check if there's a foregroundColor modifier
        let hasForegroundColorModifier = component.modifiers.contains { $0.type == .foregroundColor }
        
        // Determine fallback color (primary can be translucent on macOS, so use explicit black/white)
        let fallbackColor = (colorScheme ?? .light) == .dark ? Color.white : Color.black
        
        if isResizable {
            // Resizable SF Symbol - can be sized with frame modifier
            let baseView = Image(systemName: symbolName)
                .resizable()
                .symbolRenderingMode(.monochrome) // Ensure solid color
            
            if !hasForegroundColorModifier {
                // Apply explicit black/white if no specific color set
                let coloredView = baseView.foregroundStyle(fallbackColor)
                if hasFontModifier {
                    return AnyView(coloredView)
                } else {
                    return AnyView(coloredView.aspectRatio(contentMode: .fit))
                }
            } else {
                // Use base view (color handled by modifiers)
                if hasFontModifier {
                    return AnyView(baseView)
                } else {
                    return AnyView(baseView.aspectRatio(contentMode: .fit))
                }
            }
        } else {
            // Non-resizable SF Symbol - sized by font
            let baseView = Image(systemName: symbolName)
                .symbolRenderingMode(.monochrome) // Ensure solid color
            
            if !hasForegroundColorModifier {
                // Apply explicit black/white if no specific color set
                let coloredView = baseView.foregroundStyle(fallbackColor)
                if hasFontModifier {
                    return AnyView(coloredView)
                } else {
                    let font = iosFont(for: "largeTitle", weight: .regular)
                    return AnyView(coloredView.font(font))
                }
            } else {
                // Use base view (color handled by modifiers)
                if hasFontModifier {
                    return AnyView(baseView)
                } else {
                    let font = iosFont(for: "largeTitle", weight: .regular)
                    return AnyView(baseView.font(font))
                }
            }
        }
    }
    
    // MARK: - Text Field Renderer
    private func renderTextField() -> some View {
        let text = component.getProperty(key: "text") as? String ?? ""
        let placeholder = component.getProperty(key: "placeholder") as? String ?? "Placeholder"
        
        // Display the text field as a visual preview (non-editable)
        // The text value is edited via the properties panel, not by typing directly
        let displayText = text.isEmpty ? placeholder : text
        let isPlaceholder = text.isEmpty
        
        return Text(displayText)
            .foregroundColor(isPlaceholder ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.8)))
            )
            .padding(4)
            .contentShape(Rectangle())
            .onTapGesture {
                // Select this component when tapped - shows properties panel
                onTap?(false)
            }
    }
    
    // MARK: - Toggle/Switch Renderer
    private func renderToggle() -> some View {
        let isOn = component.getProperty(key: "isOn") as? Bool ?? true
        
        let binding = Binding<Bool>(
            get: { isOn },
            set: { newValue in
                self.component.setProperty(key: "isOn", value: newValue)
            }
        )
        
        // iOS-style switch without label (just the toggle control)
        // Use pure SwiftUI custom switch for consistent appearance and screenshot support
        return CustomSwitchView(isOn: binding)
            .padding(4)
    }
    
    // MARK: - Slider Renderer
    private func renderSlider() -> some View {
        let value = component.getProperty(key: "value") as? Double ?? 0.5
        let min = component.getProperty(key: "min") as? Double ?? 0.0
        let max = component.getProperty(key: "max") as? Double ?? 1.0
        
        let binding = Binding<Double>(
            get: { value },
            set: { newValue in
                self.component.setProperty(key: "value", value: newValue)
            }
        )
        
        return CustomSliderView(value: binding, range: min...max)
            .padding(.horizontal)
    }

    
    // MARK: - Placeholder Renderer
    private func renderPlaceholder() -> some View {
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
    
    // MARK: - Helper Functions
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

private extension View {
    func applyOptionalFrame(hasExplicitFrame: Bool, frame: CGRect) -> some View {
        if hasExplicitFrame {
            return AnyView(self.frame(width: frame.width, height: frame.height))
        } else {
            return AnyView(self)
        }
    }
    func applyAspectRatio(mode: String) -> some View {
        switch mode {
        case "fit": 
            return AnyView(self.aspectRatio(contentMode: .fit))
        case "fill": 
            return AnyView(self.aspectRatio(contentMode: .fill))
        case "none":
            return AnyView(self)
        default: 
            return AnyView(self.aspectRatio(contentMode: .fit))
        }
    }
    
    func applyOverlayChildren(_ overlayChildren: [UIComponent], deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> some View {
        var view = AnyView(self)
        
        // Apply overlay children in order, each one overlaying the previous
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
            
            // Determine alignment based on overlay position (default to topTrailing for badges)
            let alignment = Alignment.topTrailing
            view = AnyView(view.overlay(overlayView, alignment: alignment))
        }
        
        return view
    }
    
    func applyModifiers(_ modifiers: [ComponentModifier], component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> some View {
        var view = AnyView(self)
        
        for modifier in modifiers {
            view = AnyView(applyModifier(modifier, to: view, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds))
        }
        
        return view
    }
    
    /// Parse "colorname:opacity" format
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
    
    private func applyModifier(_ modifier: ComponentModifier, to view: AnyView, component: UIComponent, deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent, Bool) -> Void)?, selectedComponentIds: Set<UUID>) -> AnyView {
        switch modifier.type {
        case .frame:
            let widthType = modifier.properties["widthType"] as? String ?? "Default"
            let heightType = modifier.properties["heightType"] as? String ?? "Default"
            let width = modifier.getCGFloat(key: "width", defaultValue: 100)
            let height = modifier.getCGFloat(key: "height", defaultValue: 100)
            
            // Apply frame based on type
            if widthType == "Default" && heightType == "Default" {
                return view // No frame modifier applied
            }
            
            // Build frame modifier dynamically
            var modifiedView = view
            
            // Handle width - constrain to device bounds to prevent canvas expansion
            if widthType == "Full" {
                // Full width should still be constrained to device width
                let maxWidth = deviceSize?.width ?? 1000
                modifiedView = AnyView(modifiedView.frame(maxWidth: maxWidth))
            } else if widthType == "Custom" {
                // Constrain custom width to device width to prevent canvas expansion
                let maxWidth = deviceSize?.width ?? 1000
                let constrainedWidth = min(width, maxWidth)
                modifiedView = AnyView(modifiedView.frame(width: constrainedWidth))
            }
            // If widthType == "Default", don't apply width modifier
            
            // Handle height - constrain to device bounds to prevent canvas expansion
            if heightType == "Full" {
                // Full height should still be constrained to device height
                let maxHeight = deviceSize?.height ?? 1000
                modifiedView = AnyView(modifiedView.frame(maxHeight: maxHeight))
            } else if heightType == "Custom" {
                // Constrain custom height to device height to prevent canvas expansion
                let maxHeight = deviceSize?.height ?? 1000
                let constrainedHeight = min(height, maxHeight)
                modifiedView = AnyView(modifiedView.frame(height: constrainedHeight))
            }
            // If heightType == "Default", don't apply height modifier
            
            return modifiedView
            
        case .padding:
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
            
        case .background:
            // Get parent component for this modifier
            if let parentComponent = component.getParentComponentForModifier(modifier.id) {
                // Render the parent component and its children as background
                let backgroundView = ComponentRenderer(
                    component: parentComponent,
                    deviceSize: deviceSize,
                    colorScheme: colorScheme,
                    onTap: { additive in
                        onSelectChild?(parentComponent, additive)
                    },
                    onSelectChild: onSelectChild,
                    selectedComponentIds: selectedComponentIds
                )
                return AnyView(view.background(backgroundView))
            }
            
            // No component found, return unchanged view
            return AnyView(view)
            
        case .backgroundColor:
            // Handle color/gradient backgrounds
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.background(gradient))
            }
            // Parse unified "colorname:opacity" format
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.background(color.opacity(opacity)))
            
        case .foregroundColor:
            // Parse unified "colorname:opacity" format
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.foregroundStyle(color.opacity(opacity)))
            
        case .font:
            let size = modifier.properties["fontSize"] as? String ?? "body"
            let weight = modifier.properties["fontWeight"] as? String ?? "regular"
            let fontWeight = fontWeightFromString(weight)
            let font = createIOSFont(for: size, weight: fontWeight, deviceSize: deviceSize)
            return AnyView(view.font(font))
            
        case .fill:
            if let gradient = modifier.getGradient(key: "gradient") {
                return AnyView(view.background(gradient))
            }
            // Parse unified "colorname:opacity" format
            let (color, opacity) = parseColorWithOpacity(modifier: modifier)
            return AnyView(view.background(color.opacity(opacity)))
            
        case .cornerRadius:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.cornerRadius(radius))
            
        case .shadow:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            
            // Support both "x"/"y" and "offsetX"/"offsetY" for backward compatibility
            let x: CGFloat
            if let offsetX = modifier.properties["offsetX"] as? CGFloat {
                x = offsetX
            } else if let offsetX = modifier.properties["offsetX"] as? Double {
                x = CGFloat(offsetX)
            } else {
                x = modifier.getCGFloat(key: "x", defaultValue: 0)
            }
            
            let y: CGFloat
            if let offsetY = modifier.properties["offsetY"] as? CGFloat {
                y = offsetY
            } else if let offsetY = modifier.properties["offsetY"] as? Double {
                y = CGFloat(offsetY)
            } else {
                y = modifier.getCGFloat(key: "y", defaultValue: 0)
            }
            
            // Get color, applying opacity if specified
            var color = modifier.getColor(key: "color", defaultValue: .black)
            if let opacity = modifier.properties["opacity"] as? Double {
                color = color.opacity(opacity)
            }
            
            return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
            
        case .opacity:
            let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            return AnyView(view.opacity(opacity))
            
        case .rotation:
            let angle = modifier.getDouble(key: "angle", defaultValue: 0)
            return AnyView(view.rotationEffect(.degrees(angle)))
            
        case .scale:
            // Support both "x"/"y" and "scaleX"/"scaleY" for backward compatibility
            let x: Double
            if let scaleX = modifier.properties["scaleX"] as? Double {
                x = scaleX
            } else {
                x = modifier.getDouble(key: "x", defaultValue: 1.0)
            }
            
            let y: Double
            if let scaleY = modifier.properties["scaleY"] as? Double {
                y = scaleY
            } else {
                y = modifier.getDouble(key: "y", defaultValue: 1.0)
            }
            return AnyView(view.scaleEffect(x: x, y: y))
            
        case .offset:
            // Support both "x"/"y" and "offsetX"/"offsetY" for backward compatibility
            let x: CGFloat
            if let offsetX = modifier.properties["offsetX"] as? CGFloat {
                x = offsetX
            } else if let offsetX = modifier.properties["offsetX"] as? Double {
                x = CGFloat(offsetX)
            } else {
                x = modifier.getCGFloat(key: "x", defaultValue: 0)
            }
            
            let y: CGFloat
            if let offsetY = modifier.properties["offsetY"] as? CGFloat {
                y = offsetY
            } else if let offsetY = modifier.properties["offsetY"] as? Double {
                y = CGFloat(offsetY)
            } else {
                y = modifier.getCGFloat(key: "y", defaultValue: 0)
            }
            return AnyView(view.offset(x: x, y: y))
        case .blur:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.blur(radius: radius))
            
        case .overlay:
            // Get parent component for this modifier
            if let parentComponent = component.getParentComponentForModifier(modifier.id) {
                // Render the parent component and its children as overlay
                let overlayView = ComponentRenderer(
                    component: parentComponent,
                    deviceSize: deviceSize,
                    colorScheme: colorScheme,
                    onTap: { additive in
                        onSelectChild?(parentComponent, additive)
                    },
                    onSelectChild: onSelectChild,
                    selectedComponentIds: selectedComponentIds
                )
                let alignment = alignmentFromString(modifier.properties["alignment"] as? String ?? "center")
                return AnyView(view.overlay(overlayView, alignment: alignment))
            }
            
            return view
            
        case .border:
            let width = modifier.getCGFloat(key: "width", defaultValue: 1)
            let color = modifier.getColor(key: "color", defaultValue: .primary)
            return AnyView(view.border(color, width: width))
            
        case .clipShape:
            // Support both "shape" and "shapeType" for backward compatibility
            var shapeName: String = "Rectangle"
            
            if let shape = modifier.properties["shape"] as? String {
                shapeName = shape
            } else if let shapeType = modifier.properties["shapeType"] as? String {
                shapeName = shapeType
            }
            
            // Normalize shape name (handle lowercase and legacy conventions)
            if shapeName.lowercased() == "roundedrectangle" {
                shapeName = "RoundedRectangle"
            } else {
                shapeName = shapeName.prefix(1).uppercased() + shapeName.dropFirst()
            }
            
            switch shapeName {
            case "Circle": return AnyView(view.clipShape(Circle()))
            case "Capsule": return AnyView(view.clipShape(Capsule()))
            case "RoundedRectangle":
                let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
                return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
            case "Ellipse": return AnyView(view.clipShape(Ellipse()))
            default: return AnyView(view.clipShape(Rectangle()))
            }
            
        case .mask:
            // Get parent component for this modifier
            if let parentComponent = component.getParentComponentForModifier(modifier.id) {
                // Render the parent component and its children as mask
                let maskView = ComponentRenderer(
                    component: parentComponent,
                    deviceSize: deviceSize,
                    colorScheme: colorScheme,
                    onTap: { additive in
                        onSelectChild?(parentComponent, additive)
                    },
                    onSelectChild: onSelectChild,
                    selectedComponentIds: selectedComponentIds
                )
                return AnyView(view.mask(maskView))
            }
            
            // Fallback to shape mask for backward compatibility
            let shapeName = modifier.properties["shape"] as? String ?? "Rectangle"
            switch shapeName {
            case "Circle": return AnyView(view.mask(Circle()))
            case "Capsule": return AnyView(view.mask(Capsule()))
            case "RoundedRectangle":
                let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
                return AnyView(view.mask(RoundedRectangle(cornerRadius: radius)))
            default: return AnyView(view.mask(Rectangle()))
            }
            
        case .textAlignment:
            let alignment = modifier.properties["alignment"] as? String ?? "leading"
            let textAlignment: TextAlignment
            switch alignment {
            case "leading":
                textAlignment = .leading
            case "center":
                textAlignment = .center
            case "trailing":
                textAlignment = .trailing
            default:
                textAlignment = .leading
            }
            return AnyView(view.multilineTextAlignment(textAlignment))
            
        case .aspectRatio:
            // Check for explicit numerical ratio
            if let ratio = modifier.properties["ratio"] as? Double {
                return AnyView(view.aspectRatio(CGFloat(ratio), contentMode: .fit))
            }
            
            // Fallback to legacy string-based mode
            let mode = modifier.properties["aspectRatio"] as? String ?? "fit"
            switch mode {
            case "fit":
                return AnyView(view.aspectRatio(contentMode: .fit))
            case "fill":
                return AnyView(view.aspectRatio(contentMode: .fill))
            default:
                return AnyView(view.aspectRatio(contentMode: .fit))
            }
            
        case .zIndex:
            let index = modifier.getDouble(key: "index", defaultValue: 0)
            return AnyView(view.zIndex(index))
        }
    }
    
}

// MARK: - Helper Functions
// MARK: - Helper Functions
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

fileprivate func textAlignmentFromString(_ alignment: String) -> TextAlignment {
    switch alignment {
    case "leading": return .leading
    case "trailing": return .trailing
    case "center": return .center
    default: return .leading
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

// MARK: - Font Helper
fileprivate func createIOSFont(for fontSize: String, weight: Font.Weight, deviceSize: CGSize?) -> Font {
    // Detect device type from deviceSize
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
        return .system(size: size, weight: weight)
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
    
    return .system(size: size, weight: weight)
}

// MARK: - Image Component View
// Encapsulates AsyncImage to provide stable identity and avoid AnyView overhead
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
                } else {
                    modifiedImage
                        .frame(maxWidth: deviceSize?.width, maxHeight: deviceSize?.height)
                }
            }
        } else {
            // Fallback for empty name or failed load
            EmptyView()
        }
    }
}

// MARK: - Custom Views for Consistent Rendering
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
            // Avoid division by zero
            let denominator = range.upperBound - range.lowerBound
            let percentage = denominator == 0 ? 0 : (value - range.lowerBound) / denominator
            let thumbX = width * CGFloat(percentage)
            
            ZStack(alignment: .leading) {
                // Track Background
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                // Active Track
                Capsule()
                    .fill(Color.blue)
                    .frame(width: thumbX, height: 4)
                
                // Thumb
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
