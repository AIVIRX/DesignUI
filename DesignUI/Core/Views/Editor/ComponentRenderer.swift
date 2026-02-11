//
//  ComponentRenderer.swift
//  DesignUI
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
    // Optional CanvasManager for scroll frame reporting
    var canvasManager: CanvasManager? = nil
    
    @State private var isHovered: Bool = false
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
            case .chart:
                renderChart()
            case .shape:
                renderShape()
            case .button:
                renderButton()
            case .gauge:
                renderGauge()

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
            renderSelectionOverlay()
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
    
    // MARK: - Selection Overlay
    private func renderSelectionOverlay() -> some View {
        let isSelected = selectedComponentIds.contains(component.id)
        let isHovering = isHovered && onSelectChild != nil && component.children.isEmpty
        
        guard isSelected || isHovering else { return AnyView(EmptyView()) }
        
        let color = isSelected ? Color.blue : Color.blue.opacity(0.7)
        let lineWidth: CGFloat = isSelected ? 2 : 1
        
        // 1. Check modifiers first (ClipShape has highest priority for shape)
        if let clipMod = component.modifiers.first(where: { $0.type == .clipShape }),
           let shapeName = clipMod.properties["shape"] as? String {
            if shapeName == "Circle" { return AnyView(Circle().stroke(color, lineWidth: lineWidth)) }
            if shapeName == "Capsule" { return AnyView(Capsule().stroke(color, lineWidth: lineWidth)) }
            if shapeName == "Ellipse" { return AnyView(Ellipse().stroke(color, lineWidth: lineWidth)) }
            if shapeName == "RoundedRectangle" {
                // Try to get radius from clip shape properties, otherwise default
                // Note: clipShape modifier usually doesn't store radius in "shape" string, 
                // but if we had a more complex storage (which we don't for clipShape currently in Modifier.swift details),
                // we'd use it. For now, clipShape usually just takes a shape name. 
                // A dedicated RoundedRectangle clip might strictly need a corner radius param if supported.
                // Assuming standard default if not specified.
                return AnyView(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: lineWidth))
            }
        }
        
        // 2. Check for CornerRadius modifier
        if let radiusMod = component.modifiers.first(where: { $0.type == .cornerRadius }) {
            let radius = radiusMod.getCGFloat(key: "radius", defaultValue: 8)
            return AnyView(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
        }
        
        // 3. Check Component Type & Intrinsic Properties
        switch component.type {
        case .circle:
            return AnyView(Circle().stroke(color, lineWidth: lineWidth))
        case .capsule:
            return AnyView(Capsule().stroke(color, lineWidth: lineWidth))
        case .ellipse:
            return AnyView(Ellipse().stroke(color, lineWidth: lineWidth))
        case .roundedRectangle:
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return AnyView(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
        case .shape:
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
                return AnyView(RoundedRectangle(cornerRadius: 0).stroke(color, lineWidth: lineWidth))
            }
        default:
            // Standard rectangular bounds for everything else
            return AnyView(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: lineWidth))
        }
    }
}
