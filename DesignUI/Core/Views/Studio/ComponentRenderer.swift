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
    let onTap: (() -> Void)?
    let onSelectChild: ((UIComponent) -> Void)?
    let selectedComponent: UIComponent?
    @State private var isHovered: Bool = false
    
    init(component: UIComponent, deviceSize: CGSize? = nil, onTap: (() -> Void)? = nil, onSelectChild: ((UIComponent) -> Void)? = nil, selectedComponent: UIComponent? = nil) {
        self.component = component
        self.deviceSize = deviceSize
        self.onTap = onTap
        self.onSelectChild = onSelectChild
        self.selectedComponent = selectedComponent
    }
    
    var body: some View {
        Group {
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
        .applyModifiers(component.modifiers)
        .contentShape(Rectangle())
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
        case .vstack, .hstack, .zstack, .scrollView, .list, .navigationView, .tabView, .form:
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
        
        let font: Font
        switch fontSize {
        case "largeTitle": font = .largeTitle
        case "title": font = .title
        case "title2": font = .title2
        case "title3": font = .title3
        case "headline": font = .headline
        case "body": font = .body
        case "callout": font = .callout
        case "subheadline": font = .subheadline
        case "footnote": font = .footnote
        case "caption": font = .caption
        case "caption2": font = .caption2
        default: font = .body
        }
        
        return Text(text)
            .font(font.weight(fontWeightFromString(fontWeight)))
            .foregroundColor(foregroundColor)
    }
    
    // MARK: - Image Renderer
    private func renderImage() -> some View {
        let imageName = component.getProperty(key: "imageName") as? String ?? "photo"
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        
        let view: some View = Image(imageName)
            .resizableIfNeeded(resizable)
            .applyAspectRatio(mode: aspectRatio)
        return AnyView(view)
    }
    
    // MARK: - Button Renderer
    private func renderButton() -> some View {
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.blue
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.white
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        
        return Button(action: {}) {
            Text(title)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
    }
    
    // MARK: - VStack Renderer
    private func renderVStack() -> some View {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        let base = VStack(alignment: horizontalAlignmentFromString(alignment)) {
            if component.children.isEmpty {
                EmptyView()
            } else {
                ForEach(component.children, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, onTap: {
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
        let base = HStack(alignment: verticalAlignmentFromString(alignment), spacing: 8) {
            if component.children.isEmpty {
                EmptyView()
            } else {
                ForEach(component.children, id: \.id) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize, onTap: {
                        onSelectChild?(child)
                    }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
                }
            }
        }
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base.frame(maxWidth: .infinity, maxHeight: .infinity))
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
                    ComponentRenderer(component: child, deviceSize: deviceSize, onTap: {
                        onSelectChild?(child)
                    }, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
                }
            }
        }
        return hasExplicitFrame
            ? AnyView(base.frame(width: component.frame.width, height: component.frame.height))
            : AnyView(base.frame(maxWidth: .infinity, maxHeight: .infinity))
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
                                ComponentRenderer(component: child, deviceSize: deviceSize, onTap: {
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
                                ComponentRenderer(component: child, deviceSize: deviceSize, onTap: {
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
        let fontSize = component.getProperty(key: "fontSize") as? String ?? "largeTitle"
        
        let font: Font = {
            switch fontSize {
            case "largeTitle": return .largeTitle
            case "title": return .title
            case "title2": return .title2
            case "title3": return .title3
            case "headline": return .headline
            case "body": return .body
            case "callout": return .callout
            case "subheadline": return .subheadline
            case "footnote": return .footnote
            case "caption": return .caption
            case "caption2": return .caption2
            default: return .largeTitle
            }
        }()
        
        return AnyView(
            Image(systemName: symbolName)
                .font(font)
                .foregroundColor(foregroundColor)
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
    private func fontWeightFromString(_ weight: String) -> Font.Weight {
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
    
    private func alignmentFromString(_ alignment: String) -> Alignment {
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

    private func textAlignmentFromString(_ alignment: String) -> TextAlignment {
        switch alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        case "center": return .center
        default: return .leading
        }
    }

    private func horizontalAlignmentFromString(_ alignment: String) -> HorizontalAlignment {
        switch alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        case "center": return .center
        default: return .center
        }
    }

    private func verticalAlignmentFromString(_ alignment: String) -> VerticalAlignment {
        switch alignment {
        case "top": return .top
        case "bottom": return .bottom
        case "center": return .center
        case "firstTextBaseline": return .firstTextBaseline
        case "lastTextBaseline": return .lastTextBaseline
        default: return .center
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
        case "fit": return AnyView(self.aspectRatio(contentMode: .fit))
        case "fill": return AnyView(self.aspectRatio(contentMode: .fill))
        default: return AnyView(self)
        }
    }
    
    func applyModifiers(_ modifiers: [ComponentModifier]) -> some View {
        var view = AnyView(self)
        
        for modifier in modifiers {
            view = AnyView(applyModifier(modifier, to: view))
        }
        
        return view
    }
    
    private func applyModifier(_ modifier: ComponentModifier, to view: AnyView) -> AnyView {
        switch modifier.type {
        case .frame:
            let widthType = modifier.properties["widthType"] as? String ?? "Default"
            let heightType = modifier.properties["heightType"] as? String ?? "Default"
            let width = modifier.properties["width"] as? CGFloat ?? 100
            let height = modifier.properties["height"] as? CGFloat ?? 100
            
            // Apply frame based on type
            if widthType == "Default" && heightType == "Default" {
                return view // No frame modifier applied
            }
            
            // Build frame modifier dynamically
            var modifiedView = view
            
            // Handle width
            if widthType == "Full" {
                modifiedView = AnyView(modifiedView.frame(maxWidth: .infinity))
            } else if widthType == "Custom" {
                modifiedView = AnyView(modifiedView.frame(width: width))
            }
            // If widthType == "Default", don't apply width modifier
            
            // Handle height
            if heightType == "Full" {
                modifiedView = AnyView(modifiedView.frame(maxHeight: .infinity))
            } else if heightType == "Custom" {
                modifiedView = AnyView(modifiedView.frame(height: height))
            }
            // If heightType == "Default", don't apply height modifier
            
            return modifiedView
            
        case .padding:
            let amount = modifier.properties["amount"] as? CGFloat ?? 0
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
            let color = modifier.properties["color"] as? Color ?? Color.clear
            return AnyView(view.background(color))
            
        case .overlay:
            let overlayType = modifier.properties["type"] as? String ?? "color"
            
            switch overlayType {
            case "color":
                let color = modifier.properties["color"] as? Color ?? Color.clear
                return AnyView(view.overlay(
                    Rectangle()
                        .fill(color)
                ))
                
            case "text":
                let text = modifier.properties["text"] as? String ?? "Overlay"
                let position = modifier.properties["position"] as? String ?? "topTrailing"
                let alignment: Alignment = {
                    switch position {
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
                }()
                return AnyView(view.overlay(
                    Text(text)
                        .font(.caption)
                        .padding(4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4),
                    alignment: alignment
                ))
                
            case "icon":
                let iconName = modifier.properties["iconName"] as? String ?? "star.fill"
                let position = modifier.properties["position"] as? String ?? "topTrailing"
                let alignment: Alignment = {
                    switch position {
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
                }()
                return AnyView(view.overlay(
                    Image(systemName: iconName)
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4),
                    alignment: alignment
                ))
                
            default:
                return view
            }
            
        case .foregroundColor:
            let color = modifier.properties["color"] as? Color ?? Color.primary
            return AnyView(view.foregroundColor(color))
            
        case .font:
            let style = modifier.properties["style"] as? String ?? "body"
            let size = modifier.properties["size"] as? CGFloat ?? 16
            let weight = modifier.properties["weight"] as? String ?? "regular"
            
            let font: Font
            switch style {
            case "largeTitle": font = .largeTitle
            case "title": font = .title
            case "title2": font = .title2
            case "title3": font = .title3
            case "headline": font = .headline
            case "body": font = .body
            case "callout": font = .callout
            case "subheadline": font = .subheadline
            case "footnote": font = .footnote
            case "caption": font = .caption
            case "caption2": font = .caption2
            default: font = .system(size: size, weight: fontWeightFromString(weight))
            }
            
            return AnyView(view.font(font))
            
        case .cornerRadius:
            let radius = modifier.properties["radius"] as? CGFloat ?? 0
            return AnyView(view.cornerRadius(radius))
            
        case .shadow:
            let radius = modifier.properties["radius"] as? CGFloat ?? 0
            let x = modifier.properties["x"] as? CGFloat ?? 0
            let y = modifier.properties["y"] as? CGFloat ?? 0
            let color = modifier.properties["color"] as? Color ?? Color.black
            return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
            
        case .opacity:
            let opacity = modifier.properties["opacity"] as? Double ?? 1.0
            return AnyView(view.opacity(opacity))
            
        case .rotation:
            let angle = modifier.properties["angle"] as? Double ?? 0
            return AnyView(view.rotationEffect(.degrees(angle)))
            
        case .scale:
            let x = modifier.properties["x"] as? Double ?? 1.0
            let y = modifier.properties["y"] as? Double ?? 1.0
            return AnyView(view.scaleEffect(x: x, y: y))
            
        case .offset:
            let x = modifier.properties["x"] as? CGFloat ?? 0
            let y = modifier.properties["y"] as? CGFloat ?? 0
            return AnyView(view.offset(x: x, y: y))
            
        case .blur:
            let radius = modifier.properties["radius"] as? CGFloat ?? 0
            return AnyView(view.blur(radius: radius))
            
            
        default:
            return view
        }
    }
    
    private func fontWeightFromString(_ weight: String) -> Font.Weight {
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
}
