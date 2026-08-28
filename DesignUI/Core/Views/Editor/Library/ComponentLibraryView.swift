//
//  ComponentLibraryView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

enum ComponentLibraryMode {
    case add
    case replace
}

enum ComponentLibraryCatalog {
    static let componentOrder: [ComponentType] = [
        .text, .image, .map, .sfSymbol,
        .stack, .scrollView, .spacer, .divider,
        .shape,
        .button, .textField, .toggle, .slider, .progressView, .gauge
    ]

    private static let legacyShapeTypes: Set<ComponentType> = [
        .rectangle, .circle, .roundedRectangle, .capsule, .ellipse
    ]

    static var availableComponents: [ComponentType] {
        ComponentType.allCases
            .filter { type in
                type != .statusBar &&
                type != .vstack &&
                type != .hstack &&
                type != .zstack &&
                type != .linearGradient &&
                !legacyShapeTypes.contains(type)
            }
            .sorted { lhs, rhs in
                let lhsPriority = componentOrder.firstIndex(of: lhs) ?? Int.max
                let rhsPriority = componentOrder.firstIndex(of: rhs) ?? Int.max
                return lhsPriority == rhsPriority ? lhs.rawValue < rhs.rawValue : lhsPriority < rhsPriority
            }
    }

    static func makeComponent(type: ComponentType, isFirstComponent: Bool) -> UIComponent {
        let defaultOrigin = isFirstComponent ? CGPoint(x: 0, y: 0) : CGPoint(x: 100, y: 100)
        let component = UIComponent(
            type: type,
            properties: UIComponent.defaultProperties(for: type),
            frame: CGRect(origin: defaultOrigin, size: .zero),
            modifiers: []
        )

        if type == .button {
            component.addChild(
                UIComponent(
                    type: .text,
                    properties: [
                        ComponentProperty(
                            key: "text",
                            displayName: "Text",
                            type: .string,
                            value: "Continue",
                            defaultValue: "Continue"
                        )
                    ],
                    frame: .zero
                )
            )
        }

        return component
    }
}

struct ComponentLibraryView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    var mode: ComponentLibraryMode = .add
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var availableComponents: [ComponentType] {
        ComponentLibraryCatalog.availableComponents
    }

    private var gridColumns: [GridItem] {
        horizontalSizeClass == .compact
            ? [GridItem(.flexible(), spacing: 8)]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            componentGrid
        }
        .background(libraryBackground)
        #if os(iOS)
        .environment(\.layoutDirection, .leftToRight)
        #endif
    }

    private var componentGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns) {
                ForEach(availableComponents) { componentType in
                    ComponentLibraryItem(
                        componentType: componentType,
                        isFirstComponent: canvasManager.components.isEmpty,
                        onAdd: { component in
                            addComponent(component)
                        }
                    )
                }
            }
            .padding(12)
        }
    }

    private var libraryBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    private func addComponent(_ component: UIComponent) {
        if mode == .replace {
            guard let selected = selectedComponent else {
                canvasManager.addComponent(component)
                return
            }
            canvasManager.replaceComponent(selected, with: component, registerUndo: true, undoDescription: "Replace Component")
            return
        }

        canvasManager.insertComponent(component, relativeTo: selectedComponent)
    }
}

struct ComponentLibraryItem: View {
    let componentType: ComponentType
    let isFirstComponent: Bool
    let onAdd: (UIComponent) -> Void
    
    @State private var isPressed = false
    @State private var isHovering = false

    private var iconTintColor: Color {
        if isLayoutComponent {
            return .secondary
        }
        return componentType == .text ? .primary : .accentColor
    }

    private var isLayoutComponent: Bool {
        switch componentType {
        case .stack, .vstack, .hstack, .zstack, .scrollView, .spacer, .divider, .rectangle, .circle, .roundedRectangle, .capsule, .ellipse:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            thumbnailContainer

            Text(componentType.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
             Image(systemName: "plus.circle.fill")
                .foregroundColor(isHovering ? .accentColor : .clear)
                .scaleEffect(isHovering ? 1.0 : 0.5)
                .opacity(isHovering ? 1.0 : 0.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)

        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPressed ? Color.accentColor.opacity(0.15) : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
        )
        .contentShape(Rectangle()) // Ensure entire row is tappable
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { isHovering = $0 }
        .onTapGesture {
            handleTap()
        }
    }

    private var thumbnailContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 44, height: 44)
            assetOrFallbackIcon
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var assetOrFallbackIcon: some View {
        #if os(iOS)
        if let uiImage = UIImage(named: componentType.assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        } else {
            fallbackIcon
        }
        #else
        if let nsImage = NSImage(named: componentType.assetName) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        } else {
            fallbackIcon
        }
        #endif
    }

    private var fallbackIcon: some View {
        Image(systemName: componentType.icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(iconTintColor)
    }

    private func handleTap() {
        isPressed = true

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif

        let component = ComponentLibraryCatalog.makeComponent(
            type: componentType,
            isFirstComponent: isFirstComponent
        )
        onAdd(component)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }

}
