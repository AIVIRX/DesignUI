//
//  ComponentRenderer.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct ComponentRenderer: View {
    @ObservedObject var component: UIComponent
    
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
            default:
                renderPlaceholder()
            }
        }
        .opacity(component.isVisible ? 1.0 : 0.3)
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
        let frameWidth = component.getProperty(key: "frameWidth") as? Double ?? 100.0
        let frameHeight = component.getProperty(key: "frameHeight") as? Double ?? 100.0
        
        var view: some View = Image(imageName)
            .resizableIfNeeded(resizable)
            .applyAspectRatio(mode: aspectRatio)
            .frame(width: frameWidth, height: frameHeight)
        return AnyView(view)
    }
    
    // MARK: - Button Renderer
    private func renderButton() -> some View {
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.blue
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.white
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        let padding = component.getProperty(key: "padding") as? EdgeInsets ?? EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        return Button(action: {}) {
            Text(title)
                .foregroundColor(foregroundColor)
                .padding(padding)
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
    }
    
    // MARK: - VStack Renderer
    private func renderVStack() -> some View {
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        return VStack(alignment: horizontalAlignmentFromString(alignment), spacing: spacing) {
            if component.children.isEmpty {
                Text("VStack")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(component.children) { child in
                    ComponentRenderer(component: child)
                }
            }
        }
    }
    
    // MARK: - HStack Renderer
    private func renderHStack() -> some View {
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        return HStack(alignment: verticalAlignmentFromString(alignment), spacing: spacing) {
            if component.children.isEmpty {
                Text("HStack")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(component.children) { child in
                    ComponentRenderer(component: child)
                }
            }
        }
    }
    
    // MARK: - ZStack Renderer
    private func renderZStack() -> some View {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        return ZStack(alignment: alignmentFromString(alignment)) {
            if component.children.isEmpty {
                Text("ZStack")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(component.children) { child in
                    ComponentRenderer(component: child)
                }
            }
        }
    }
    
    // MARK: - Spacer Renderer
    private func renderSpacer() -> some View {
        let minLength = component.getProperty(key: "minLength") as? Double ?? 0.0
        
        if minLength > 0 {
            return Spacer(minLength: minLength)
        } else {
            return Spacer()
        }
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
    
    return ComponentRenderer(component: component)
        .frame(width: 200, height: 50)
}
