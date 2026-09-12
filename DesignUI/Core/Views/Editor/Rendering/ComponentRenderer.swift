//
//  ComponentRenderer.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Charts
import MapKit


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
        .modifier(DesignLayoutProbe(component: component))
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
        case .map:
            return AnyView(renderMap())
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
        guard shouldShowSelectionOverlay else { return AnyView(EmptyView()) }

        let style = selectionOverlayStyle

        switch selectionOverlayKind {
        case .circle:
            return selectionStroke(Circle(), color: style.color, lineWidth: style.lineWidth)
        case .capsule:
            return selectionStroke(Capsule(), color: style.color, lineWidth: style.lineWidth)
        case .ellipse:
            return selectionStroke(Ellipse(), color: style.color, lineWidth: style.lineWidth)
        case let .roundedRectangle(radius):
            return selectionStroke(RoundedRectangle(cornerRadius: radius), color: style.color, lineWidth: style.lineWidth)
        }
    }

    private var shouldShowSelectionOverlay: Bool {
        let isSelected = selectedComponentIds.contains(component.id)
        let isHovering = isHovered && onSelectChild != nil && component.children.isEmpty
        return isSelected || isHovering
    }

    private var selectionOverlayStyle: (color: Color, lineWidth: CGFloat) {
        let isSelected = selectedComponentIds.contains(component.id)
        return (
            color: isSelected ? Color.blue : Color.blue.opacity(0.7),
            lineWidth: isSelected ? 2 : 1
        )
    }

    private var selectionOverlayKind: SelectionOverlayKind {
        if let kind = clipShapeOverlayKind() {
            return kind
        }

        if let radiusMod = component.modifiers.first(where: { $0.type == .cornerRadius }) {
            let radius = radiusMod.getCGFloat(key: "radius", defaultValue: 8)
            return .roundedRectangle(radius: radius)
        }

        return intrinsicOverlayKind()
    }

    private func clipShapeOverlayKind() -> SelectionOverlayKind? {
        guard let clipMod = component.modifiers.first(where: { $0.type == .clipShape }),
              let shapeName = clipMod.properties["shape"] as? String else {
            return nil
        }

        switch shapeName {
        case "Circle":
            return .circle
        case "Capsule":
            return .capsule
        case "Ellipse":
            return .ellipse
        case "RoundedRectangle":
            return .roundedRectangle(radius: 8)
        default:
            return nil
        }
    }

    private func intrinsicOverlayKind() -> SelectionOverlayKind {
        switch component.type {
        case .circle:
            return .circle
        case .capsule:
            return .capsule
        case .ellipse:
            return .ellipse
        case .roundedRectangle:
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return .roundedRectangle(radius: radius)
        case .shape:
            return shapeOverlayKind(from: component.getProperty(key: "shapeType") as? String ?? "Rectangle")
        default:
            return .roundedRectangle(radius: 4)
        }
    }

    private func shapeOverlayKind(from shapeType: String) -> SelectionOverlayKind {
        switch shapeType {
        case "Circle":
            return .circle
        case "Capsule":
            return .capsule
        case "Ellipse":
            return .ellipse
        case "Rounded Rectangle":
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return .roundedRectangle(radius: radius)
        default:
            return .roundedRectangle(radius: 0)
        }
    }
    
    private func selectionStroke<S: InsettableShape>(_ shape: S, color: Color, lineWidth: CGFloat) -> AnyView {
        AnyView(shape.strokeBorder(color, lineWidth: lineWidth))
    }
}

private enum SelectionOverlayKind {
    case circle
    case capsule
    case ellipse
    case roundedRectangle(radius: CGFloat)
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
