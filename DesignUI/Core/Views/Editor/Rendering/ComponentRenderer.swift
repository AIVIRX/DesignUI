//
//  ComponentRenderer.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Charts


struct ComponentRenderer: View {
    @ObservedObject var component: UIComponent
    let deviceSize: CGSize?
    let colorScheme: ColorScheme?
    let onTap: ((Bool) -> Void)?
    let onSelectChild: ((UIComponent, Bool) -> Void)?
    let selectedComponentIds: Set<UUID>
    let isScreenshotCapture: Bool
    // Optional CanvasManager for scroll frame reporting
    var canvasManager: CanvasManager? = nil
    
    @State private var isHovered: Bool = false
    @State private var hasAppliedModifiers: Bool = false
    
    init(component: UIComponent, deviceSize: CGSize? = nil, colorScheme: ColorScheme? = nil, onTap: ((Bool) -> Void)? = nil, onSelectChild: ((UIComponent, Bool) -> Void)? = nil, selectedComponentIds: Set<UUID> = [], isScreenshotCapture: Bool = false, canvasManager: CanvasManager? = nil) {
        self.component = component
        self.deviceSize = deviceSize
        self.colorScheme = colorScheme
        self.onTap = onTap
        self.onSelectChild = onSelectChild
        self.selectedComponentIds = selectedComponentIds
        self.isScreenshotCapture = isScreenshotCapture
        self.canvasManager = canvasManager
    }
    
    var body: some View {
        renderedComponent
        .opacity(component.isVisible ? 1.0 : 0.0)
        .applyModifiers(component.modifiers, component: component, deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, isScreenshotCapture: isScreenshotCapture)
        .applyOverlayChildren(component.getOverlayChildren(), deviceSize: deviceSize, colorScheme: colorScheme, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
        .colorScheme(colorScheme ?? .light)
        .applyInteractionContentShapeIfNeeded(component: component)
        .id(component.id)
        .onAppear {
            hasAppliedModifiers = true
        }
        .overlay(renderSelectionOverlay())
        .onHover { hovering in
            isHovered = hovering
        }
        .gesture(tapSelectionGesture)
    }
    
    private var renderedComponent: AnyView {
        switch component.type {
        case .text:
            return AnyView(renderText())
        case .image:
            return AnyView(renderImage())
        case .stack:
            return AnyView(renderStack())
        case .vstack:
            return AnyView(renderVStack())
        case .hstack:
            return AnyView(renderHStack())
        case .zstack:
            return AnyView(renderZStack())
        case .spacer:
            return AnyView(renderSpacer())
        case .divider:
            return AnyView(renderDivider())
        case .rectangle:
            return AnyView(renderRectangle())
        case .circle:
            return AnyView(renderCircle())
        case .roundedRectangle:
            return AnyView(renderRoundedRectangle())
        case .capsule:
            return AnyView(renderCapsule())
        case .ellipse:
            return AnyView(renderEllipse())
        case .scrollView:
            return AnyView(renderScrollView())
        case .sfSymbol:
            return AnyView(renderSFSymbol())
        case .textField:
            return AnyView(renderTextField())
        case .toggle:
            return AnyView(renderToggle())
        case .slider:
            return AnyView(renderSlider())
        case .progressView:
            return AnyView(renderProgressView())
        case .linearGradient:
            return AnyView(renderLinearGradient())
        case .chart:
            return AnyView(renderChart())
        case .shape:
            return AnyView(renderShape())
        case .button:
            return AnyView(renderButton())
        case .gauge:
            return AnyView(renderGauge())
        default:
            return AnyView(renderPlaceholder())
        }
    }
    
    private var tapSelectionGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                onTap?(isAdditiveSelection)
            }
    }
    
    private var isAdditiveSelection: Bool {
        #if os(macOS)
        return NSEvent.modifierFlags.contains(.command)
        #else
        return false
        #endif
    }
    
    private func renderSelectionOverlay() -> some View {
        let isSelected = selectedComponentIds.contains(component.id)
        let isHovering = isHovered && onSelectChild != nil && component.children.isEmpty
        
        guard isSelected || isHovering else { return AnyView(EmptyView()) }
        
        let color = isSelected ? Color.blue : Color.blue.opacity(0.7)
        let lineWidth: CGFloat = isSelected ? 2 : 1
        
        // 1. Check modifiers first (ClipShape has highest priority for shape)
        if let clipMod = component.modifiers.first(where: { $0.type == .clipShape }),
           let shapeName = clipMod.properties["shape"] as? String {
            if shapeName == "Circle" { return selectionStroke(Circle(), color: color, lineWidth: lineWidth) }
            if shapeName == "Capsule" { return selectionStroke(Capsule(), color: color, lineWidth: lineWidth) }
            if shapeName == "Ellipse" { return selectionStroke(Ellipse(), color: color, lineWidth: lineWidth) }
            if shapeName == "RoundedRectangle" {
                // Try to get radius from clip shape properties, otherwise default
                // Note: clipShape modifier usually doesn't store radius in "shape" string, 
                // but if we had a more complex storage (which we don't for clipShape currently in Modifier.swift details),
                // we'd use it. For now, clipShape usually just takes a shape name. 
                // A dedicated RoundedRectangle clip might strictly need a corner radius param if supported.
                // Assuming standard default if not specified.
                return selectionStroke(RoundedRectangle(cornerRadius: 8), color: color, lineWidth: lineWidth)
            }
        }
        
        // 2. Check for CornerRadius modifier
        if let radiusMod = component.modifiers.first(where: { $0.type == .cornerRadius }) {
            let radius = radiusMod.getCGFloat(key: "radius", defaultValue: 8)
            return selectionStroke(RoundedRectangle(cornerRadius: radius), color: color, lineWidth: lineWidth)
        }
        
        // 3. Check Component Type & Intrinsic Properties
        switch component.type {
        case .circle:
            return selectionStroke(Circle(), color: color, lineWidth: lineWidth)
        case .capsule:
            return selectionStroke(Capsule(), color: color, lineWidth: lineWidth)
        case .ellipse:
            return selectionStroke(Ellipse(), color: color, lineWidth: lineWidth)
        case .roundedRectangle:
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return selectionStroke(RoundedRectangle(cornerRadius: radius), color: color, lineWidth: lineWidth)
        case .shape:
            let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"
            switch shapeType {
            case "Circle":
                return selectionStroke(Circle(), color: color, lineWidth: lineWidth)
            case "Capsule":
                return selectionStroke(Capsule(), color: color, lineWidth: lineWidth)
            case "Ellipse":
                return selectionStroke(Ellipse(), color: color, lineWidth: lineWidth)
            case "Rounded Rectangle":
                let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
                return selectionStroke(RoundedRectangle(cornerRadius: radius), color: color, lineWidth: lineWidth)
            default:
                return selectionStroke(RoundedRectangle(cornerRadius: 0), color: color, lineWidth: lineWidth)
            }
        default:
            // Standard rectangular bounds for everything else
            return selectionStroke(RoundedRectangle(cornerRadius: 4), color: color, lineWidth: lineWidth)
        }
    }
    
    private func selectionStroke<S: InsettableShape>(_ shape: S, color: Color, lineWidth: CGFloat) -> AnyView {
        AnyView(shape.stroke(color, lineWidth: lineWidth))
    }
}

private extension View {
    @ViewBuilder
    func applyInteractionContentShapeIfNeeded(component: UIComponent) -> some View {
        // Container-like layers with transparent space (Stack/ScrollView/Spacer) should not
        // force a full-rect hit target, otherwise they block interaction with content beneath.
        let shouldSkipForcedRectHitShape =
            component.isOverlay ||
            component.type == .stack ||
            component.type == .vstack ||
            component.type == .hstack ||
            component.type == .zstack ||
            component.type == .scrollView ||
            component.type == .spacer

        if shouldSkipForcedRectHitShape {
            self
        } else {
            self.contentShape(Rectangle())
        }
    }
}
