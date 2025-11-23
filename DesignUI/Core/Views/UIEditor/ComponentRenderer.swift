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
    let onTap: (() -> Void)?
    let onSelectChild: ((UIComponent) -> Void)?
    let selectedComponent: UIComponent?
    @State private var isHovered: Bool = false
    @State private var forceRefresh: Int = 0
    @State private var hasAppliedModifiers: Bool = false
    
    init(component: UIComponent, deviceSize: CGSize? = nil, colorScheme: ColorScheme? = nil, onTap: (() -> Void)? = nil, onSelectChild: ((UIComponent) -> Void)? = nil, selectedComponent: UIComponent? = nil) {
        self.component = component
        self.deviceSize = deviceSize
        self.colorScheme = colorScheme
        self.onTap = onTap
        self.onSelectChild = onSelectChild
        self.selectedComponent = selectedComponent
    }
    
    var body: some View {
        Group {
            let _ = print("🎨 ComponentRenderer body called for \(component.type.rawValue) with \(component.modifiers.count) modifiers")
            let _ = print("🎨 ComponentRenderer forceRefresh: \(forceRefresh)")
            switch component.type {
            case .text:
                renderText()
            case .image:
                renderImage()
            case .button:
                renderButton()
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
            default:
                renderPlaceholder()
            }
        }
        .opacity(component.isVisible ? 1.0 : 0.0)
        .applyModifiers(component.modifiers, deviceSize: deviceSize)
        .applyOverlayChildren(component.getOverlayChildren(), deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
        .colorScheme(colorScheme ?? .light)
        .contentShape(Rectangle())
        .id("\(component.id)-\(component.modifiers.count)-\(component.modifiers.map { "\($0.type.rawValue)-\($0.properties.count)" }.joined(separator: "-"))-\(forceRefresh)")
        .onChange(of: component.modifiers) { _, _ in
            print("🎨 ComponentRenderer: Modifiers changed for \(component.type.rawValue)")
        }
        .onAppear {
            print("🎨 ComponentRenderer: Appeared for \(component.type.rawValue) with \(component.modifiers.count) modifiers")
            hasAppliedModifiers = true
            print("🎨 ComponentRenderer: hasAppliedModifiers set to true")
            // Force refresh to ensure modifiers are applied
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                forceRefresh += 1
                print("🎨 ComponentRenderer: Force refresh triggered for \(component.type.rawValue)")
            }
            // Also try immediate refresh
            DispatchQueue.main.async {
                forceRefresh += 1
                print("🎨 ComponentRenderer: Immediate force refresh for \(component.type.rawValue)")
            }
        }
        .onChange(of: forceRefresh) { _, _ in
            print("🎨 ComponentRenderer: forceRefresh changed to \(forceRefresh)")
        }
        .overlay(
            // Selection and hover overlays for child components
            Group {
                if selectedComponent?.id == component.id {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 2)
                        .allowsHitTesting(false)
                } else if isHovered && onSelectChild != nil && component.children.isEmpty {
                    // Only show hover for leaf components (components without children)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue.opacity(0.9), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
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
                    // Always allow selection of this component
                    onTap?()
                }
        )
    }
    
    private func isContainerComponent(_ type: ComponentType) -> Bool {
        switch type {
        case .vstack, .hstack, .zstack, .scrollView, .list:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Text Renderer
    private func renderText() -> some View {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        let fontSize = component.getProperty(key: "fontSize") as? String ?? "body"
        let fontWeight = component.getProperty(key: "fontWeight") as? String ?? "regular"
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.primary
        
        // Use iOS-specific font sizes to match simulator
        let font = iosFont(for: fontSize, weight: fontWeightFromString(fontWeight))
        
        return Text(text)
            .font(font)
            .foregroundColor(foregroundColor)
    }
    
    // MARK: - Platform Font Helper
    // Returns platform-specific font sizes per Apple Human Interface Guidelines
    // Reference: https://developer.apple.com/design/human-interface-guidelines/typography
    private func iosFont(for fontSize: String, weight: Font.Weight) -> Font {
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
            size = isMac ? 18 : 17 // macOS: 18pt, iOS/iPad: 17pt (always semibold)
            return .system(size: size, weight: .semibold)
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
    
    // MARK: - Image Renderer
    private func renderImage() -> some View {
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        
        // Check if custom image data exists
        if let imageDataString = component.getProperty(key: "imageData") as? String,
           !imageDataString.isEmpty {
            print("🖼️ Found imageData string, length: \(imageDataString.count)")
            // Try to decode base64 image data with options to handle invalid data gracefully
            if let imageData = Data(base64Encoded: imageDataString, options: .ignoreUnknownCharacters),
               !imageData.isEmpty {
                print("🖼️ Decoded image data, size: \(imageData.count) bytes")
                
                // Create image from validated data
                if let image = createImage(from: imageData) {
                    print("✅ Successfully created image from data")
                    // Use custom image - constrain size to device bounds to prevent canvas expansion
                    let maxWidth = deviceSize?.width ?? 1000
                    let maxHeight = deviceSize?.height ?? 1000
                    #if os(macOS)
                    let view: some View = Image(nsImage: image)
                        .resizableIfNeeded(resizable)
                        .applyAspectRatio(mode: aspectRatio)
                        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    #else
                    let view: some View = Image(uiImage: image)
                        .resizableIfNeeded(resizable)
                        .applyAspectRatio(mode: aspectRatio)
                        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    #endif
                    return AnyView(view)
                } else {
                    print("⚠️ Failed to create image from data")
                }
            } else {
                print("⚠️ Failed to decode base64 string to Data")
            }
        } else {
            print("ℹ️ No imageData found, using system image")
        }
        
        // Fallback to system image
        let imageName = component.getProperty(key: "imageName") as? String ?? "photo"
        let view: some View = Image(systemName: imageName)
            .resizableIfNeeded(resizable)
            .applyAspectRatio(mode: aspectRatio)
        return AnyView(view)
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
    
    // MARK: - Button Renderer
    private func renderButton() -> some View {
        // If button has children, render them inside the button (container approach)
        if !component.children.isEmpty {
            return AnyView(
                Button(action: {}) {
                    ForEach(component.children, id: \.id) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: {
                            onSelectChild?(child)
                        }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
                    }
                }
                    .buttonStyle(PlainButtonStyle())
            )
        }
        
        // No children: Use default SwiftUI button with label-based initializer and apply properties
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.blue
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.white
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        
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
                    .foregroundColor(foregroundColor)
                    .frame(maxWidth: hasFullWidthFrame ? .infinity : nil)
            }
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
        )
    }
    
    // MARK: - VStack Renderer
    private func renderVStack() -> some View {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        let base = VStack(alignment: horizontalAlignmentFromString(alignment), spacing: spacing) {
            if component.children.isEmpty {
                EmptyView()
            } else {
                ForEach(component.children, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: {
                        onSelectChild?(child)
                    }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
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
        let base = HStack(alignment: verticalAlignmentFromString(alignment), spacing: spacing) {
            if component.children.isEmpty {
                EmptyView()
            } else {
                ForEach(component.children, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: {
                        onSelectChild?(child)
                    }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
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
        let base = ZStack(alignment: alignmentFromString(alignment)) {
            if component.children.isEmpty {
                EmptyView()
            } else {
                ForEach(component.children, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: {
                        onSelectChild?(child)
                    }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
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
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 0.0
        
        if stroke != Color.clear {
            return AnyView(RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fill))
        }
    }
    
    private func renderCircle() -> some View {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Circle()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Circle()
                .fill(fill))
        }
    }
    
    private func renderRoundedRectangle() -> some View {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        
        if stroke != Color.clear {
            return AnyView(RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fill))
        }
    }
    
    private func renderCapsule() -> some View {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Capsule()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Capsule()
                .fill(fill))
        }
    }
    
    private func renderEllipse() -> some View {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        if stroke != Color.clear {
            return AnyView(Ellipse()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Ellipse()
                .fill(fill))
        }
    }
    
    // MARK: - ScrollView Renderer
    private func renderScrollView() -> some View {
        let children = component.children
        let axis = component.getProperty(key: "axis") as? String ?? "vertical"
        let showsIndicators = component.getProperty(key: "showsIndicators") as? Bool ?? true
        
        let scrollAxis: Axis.Set = axis == "horizontal" ? .horizontal : .vertical
        
        return AnyView(
            ScrollView(scrollAxis, showsIndicators: showsIndicators) {
                if scrollAxis == .horizontal {
                    HStack(spacing: 8) {
                        if children.isEmpty {
                            EmptyView()
                        } else {
                            ForEach(children, id: \.id) { child in
                                ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: {
                                    onSelectChild?(child)
                                }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        if children.isEmpty {
                            EmptyView()
                        } else {
                            ForEach(children, id: \.id) { child in
                                ComponentRenderer(component: child, deviceSize: deviceSize, colorScheme: colorScheme, onTap: {
                                    onSelectChild?(child)
                                }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
                            }
                        }
                    }
                }
            }
        )
    }
    
    // MARK: - SF Symbol Renderer
    private func renderSFSymbol() -> some View {
        let symbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.primary
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.clear
        let fontSize = component.getProperty(key: "fontSize") as? String ?? "largeTitle"
        
        // Use iOS-specific font sizes to match simulator
        let font = iosFont(for: fontSize, weight: .regular)
        
        return AnyView(
            Image(systemName: symbolName)
                .font(font)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .symbolRenderingMode(.hierarchical)
        )
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
        case "fit": return AnyView(self.aspectRatio(contentMode: .fit))
        case "fill": return AnyView(self.aspectRatio(contentMode: .fill))
        default: return AnyView(self)
        }
    }
    
    func applyOverlayChildren(_ overlayChildren: [UIComponent], deviceSize: CGSize?, colorScheme: ColorScheme?, onSelectChild: ((UIComponent) -> Void)?, selectedComponent: UIComponent?) -> some View {
        var view = AnyView(self)
        
        // Apply overlay children in order, each one overlaying the previous
        for overlayChild in overlayChildren {
            let overlayView = ComponentRenderer(
                component: overlayChild,
                deviceSize: deviceSize,
                colorScheme: colorScheme,
                onTap: {
                    onSelectChild?(overlayChild)
                },
                onSelectChild: onSelectChild,
                selectedComponent: selectedComponent
            )
            
            // Determine alignment based on overlay position (default to topTrailing for badges)
            let alignment = Alignment.topTrailing
            view = AnyView(view.overlay(overlayView, alignment: alignment))
        }
        
        return view
    }
    
    func applyModifiers(_ modifiers: [ComponentModifier], deviceSize: CGSize?) -> some View {
        var view = AnyView(self)
        
        print("🎨 Applying \(modifiers.count) modifiers to component")
        for (index, modifier) in modifiers.enumerated() {
            print("🎨   - Modifier \(index): \(modifier.type.rawValue) with properties: \(modifier.properties)")
            view = AnyView(applyModifier(modifier, to: view, deviceSize: deviceSize))
        }
        
        return view
    }
    
    private func applyModifier(_ modifier: ComponentModifier, to view: AnyView, deviceSize: CGSize?) -> AnyView {
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
            print("📏 Applying padding modifier: amount=\(amount), location=\(location)")
            
            let result: AnyView
            switch location {
            case "all":
                result = AnyView(view.padding(amount))
            case "leading":
                result = AnyView(view.padding(.leading, amount))
            case "trailing":
                result = AnyView(view.padding(.trailing, amount))
            case "top":
                result = AnyView(view.padding(.top, amount))
            case "bottom":
                result = AnyView(view.padding(.bottom, amount))
            case "horizontal":
                result = AnyView(view.padding(.horizontal, amount))
            case "vertical":
                result = AnyView(view.padding(.vertical, amount))
            default:
                result = AnyView(view.padding(amount))
            }
            print("📏 Applied padding: \(location) with amount \(amount)")
            return result
            
        case .background:
            let color = modifier.properties["color"] as? Color ?? Color.clear
            print("🎨 Applying background modifier with color: \(color)")
            return AnyView(view.background(color))
            
        case .foregroundColor:
            let color = modifier.properties["color"] as? Color ?? Color.primary
            return AnyView(view.foregroundColor(color))
            
        case .cornerRadius:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.cornerRadius(radius))
            
        case .shadow:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            let x = modifier.getCGFloat(key: "x", defaultValue: 0)
            let y = modifier.getCGFloat(key: "y", defaultValue: 0)
            let color = modifier.properties["color"] as? Color ?? Color.black
            return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
            
        case .opacity:
            let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            return AnyView(view.opacity(opacity))
            
        case .rotation:
            let angle = modifier.getDouble(key: "angle", defaultValue: 0)
            return AnyView(view.rotationEffect(.degrees(angle)))
            
        case .scale:
            let x = modifier.getDouble(key: "x", defaultValue: 1.0)
            let y = modifier.getDouble(key: "y", defaultValue: 1.0)
            return AnyView(view.scaleEffect(x: x, y: y))
            
        case .offset:
            let x = modifier.getCGFloat(key: "x", defaultValue: 0)
            let y = modifier.getCGFloat(key: "y", defaultValue: 0)
            return AnyView(view.offset(x: x, y: y))
        case .blur:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return AnyView(view.blur(radius: radius))
            
        case .overlay:
            // For overlay, we need to render a component if it exists in properties
            // Since we can't easily store UIComponent in properties directly due to AnyCodable limitations,
            // we might need to handle this differently.
            // Ideally, the overlay component should be a child of the main component but marked as "overlay".
            // But since we are using modifiers, we need to reconstruct the component from the dictionary if possible.
            
            // Simplified approach: Render a placeholder or text for now if we can't fully reconstruct.
            // Better approach: If we have a "component" property that is a dictionary, try to decode it?
            // Or, if we have a "text" property, render a text overlay.
            
            // Let's support a simple text overlay for now to demonstrate functionality
            if let text = modifier.properties["text"] as? String {
                let alignment = alignmentFromString(modifier.properties["alignment"] as? String ?? "center")
                return AnyView(view.overlay(
                    Text(text)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4),
                    alignment: alignment
                ))
            }
            
            // If we have a full component dictionary (future proofing)
            // This part is tricky without a way to decode UIComponent from [String: Any] easily here.
            // We'll stick to the text overlay or a simple shape overlay for this iteration.
            
            return view
            
        case .border:
            let color = modifier.properties["color"] as? Color ?? Color.black
            let width = modifier.getCGFloat(key: "width", defaultValue: 1)
            return AnyView(view.border(color, width: width))
            
        case .clipShape:
            let shapeName = modifier.properties["shape"] as? String ?? "Rectangle"
            switch shapeName {
            case "Circle": return AnyView(view.clipShape(Circle()))
            case "Capsule": return AnyView(view.clipShape(Capsule()))
            case "RoundedRectangle":
                let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
                return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
            default: return AnyView(view.clipShape(Rectangle()))
            }
            
        case .mask:
            // Simplified mask: Mask with another view (e.g. a shape or text)
            // For now, let's support masking with a shape
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
        }
    }
    
}

// MARK: - Helper Functions
fileprivate func fontWeightFromString(_ weight: String) -> Font.Weight {
    switch weight {
    case "bold": return .bold
    case "light": return .light
    case "medium": return .medium
    case "semibold": return .semibold
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

