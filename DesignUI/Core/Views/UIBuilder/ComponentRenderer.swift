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
    
    init(component: UIComponent, deviceSize: CGSize? = nil) {
        self.component = component
        self.deviceSize = deviceSize
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
            default:
                renderPlaceholder()
            }
        }
        .opacity(component.isVisible ? 1.0 : 0.3)
        .applyModifiers(component.modifiers)
    }
    
    // MARK: - Text Renderer
    private func renderText() -> some View {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        let fontSize = component.getProperty(key: "fontSize") as? Double ?? 16.0
        let fontWeight = component.getProperty(key: "fontWeight") as? String ?? "regular"
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.primary
        let alignment = component.getProperty(key: "multilineTextAlignment") as? String ?? "leading"
        
        return Text(text)
            .font(.system(size: fontSize, weight: fontWeightFromString(fontWeight)))
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(textAlignmentFromString(alignment))
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
        // Use default size if component has no explicit frame
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let frameWidth = hasExplicitFrame ? component.frame.width : (deviceSize?.width ?? 200)
        let frameHeight = hasExplicitFrame ? component.frame.height : (deviceSize?.height ?? 150)
        
        return VStack(alignment: .center, spacing: 8) {
            if component.children.isEmpty {
                Text("VStack")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(component.children) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize)
                }
            }
        }
        .frame(width: frameWidth, height: frameHeight)
    }
    
    // MARK: - HStack Renderer
    private func renderHStack() -> some View {
        // Use default size if component has no explicit frame
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let frameWidth = hasExplicitFrame ? component.frame.width : (deviceSize?.width ?? 200)
        let frameHeight = hasExplicitFrame ? component.frame.height : (deviceSize?.height ?? 150)
        
        return HStack(alignment: .center, spacing: 8) {
            if component.children.isEmpty {
                Text("HStack")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(component.children) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize)
                }
            }
        }
        .frame(width: frameWidth, height: frameHeight)
    }
    
    // MARK: - ZStack Renderer
    private func renderZStack() -> some View {
        // Use default size if component has no explicit frame
        let hasExplicitFrame = component.frame.width > 0 && component.frame.height > 0
        let frameWidth = hasExplicitFrame ? component.frame.width : (deviceSize?.width ?? 200)
        let frameHeight = hasExplicitFrame ? component.frame.height : (deviceSize?.height ?? 150)
        
        return ZStack(alignment: .center) {
            if component.children.isEmpty {
                Text("ZStack")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(component.children) { child in
                    ComponentRenderer(component: child, deviceSize: deviceSize)
                }
            }
        }
        .frame(width: frameWidth, height: frameHeight)
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
        
        if stroke != Color.clear {
            return AnyView(Rectangle()
                .stroke(stroke, lineWidth: lineWidth))
        } else {
            return AnyView(Rectangle()
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
        return AnyView(
            VStack(spacing: 8) {
                if component.children.isEmpty {
                    VStack {
                        Image(systemName: "rectangle.stack")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("VStack")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Add components here")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    ForEach(component.children) { child in
                        ComponentRenderer(component: child, deviceSize: deviceSize)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case "leading": return .leading
        case "trailing": return .trailing
        case "top": return .top
        case "bottom": return .bottom
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
            let width = modifier.properties["width"] as? CGFloat ?? 0
            let height = modifier.properties["height"] as? CGFloat ?? 0
            return AnyView(view.frame(width: width, height: height))
            
        case .padding:
            let top = modifier.properties["top"] as? CGFloat ?? 0
            let leading = modifier.properties["leading"] as? CGFloat ?? 0
            let bottom = modifier.properties["bottom"] as? CGFloat ?? 0
            let trailing = modifier.properties["trailing"] as? CGFloat ?? 0
            return AnyView(view.padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)))
            
        case .background:
            let color = modifier.properties["color"] as? Color ?? Color.clear
            return AnyView(view.background(color))
            
        case .overlay:
            let color = modifier.properties["color"] as? Color ?? Color.clear
            return AnyView(view.overlay(
                Rectangle()
                    .fill(color)
            ))
            
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
            
        case .brightness:
            let amount = modifier.properties["amount"] as? Double ?? 0
            return AnyView(view.brightness(amount))
            
        case .contrast:
            let amount = modifier.properties["amount"] as? Double ?? 1
            return AnyView(view.contrast(amount))
            
        case .saturation:
            let amount = modifier.properties["amount"] as? Double ?? 1
            return AnyView(view.saturation(amount))
            
        case .hueRotation:
            let angle = modifier.properties["angle"] as? Double ?? 0
            return AnyView(view.hueRotation(.degrees(angle)))
            
        case .grayscale:
            let amount = modifier.properties["amount"] as? Double ?? 0
            return AnyView(view.grayscale(amount))
            
        case .sepia:
            let amount = modifier.properties["amount"] as? Double ?? 0
            // Sepia effect using hue rotation and saturation
            return AnyView(view.hueRotation(.degrees(30)).saturation(amount))
            
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

#Preview {
    let component = UIComponent(
        type: .text,
        properties: [
            ComponentProperty(key: "text", type: .string, value: "Hello World", defaultValue: "Hello World"),
            ComponentProperty(key: "fontSize", type: .number, value: 18.0, defaultValue: 16.0)
        ],
        frame: CGRect(x: 0, y: 0, width: 200, height: 50)
    )
    
    return ComponentRenderer(component: component, deviceSize: CGSize(width: 393, height: 852))
        .frame(width: 200, height: 50)
}
