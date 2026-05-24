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

struct ComponentLibraryView: View {
    @Binding var selectedComponent: UIComponent?
    @ObservedObject var canvasManager: CanvasManager
    var mode: ComponentLibraryMode = .add
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Define the custom sort order for prioritization
    private let componentOrder: [ComponentType] = [
        .text, .image, .sfSymbol, // Core Content
        .stack, .scrollView, .spacer, .divider, // Layout
        .shape, // Shapes
        .button, .textField, .toggle, .slider, .progressView, .gauge // Controls
    ]

    private let legacyShapeTypes: [ComponentType] = [
        .rectangle, .circle, .roundedRectangle, .capsule, .ellipse
    ]
    
    private var availableComponents: [ComponentType] {
        let filtered = ComponentType.allCases.filter(shouldIncludeComponent)
        return filtered.sorted { lhs, rhs in
            let lhsPriority = componentSortPriority(lhs)
            let rhsPriority = componentSortPriority(rhs)
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.rawValue < rhs.rawValue
        }
    }

    private func shouldIncludeComponent(_ type: ComponentType) -> Bool {
        guard type != .statusBar else { return false }
        guard type != .vstack && type != .hstack && type != .zstack else { return false }
        guard type != .linearGradient else { return false }
        return !legacyShapeTypes.contains(type)
    }

    private func componentSortPriority(_ type: ComponentType) -> Int {
        componentOrder.firstIndex(of: type) ?? Int.max
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

        if let selected = selectedComponent {
            if canvasManager.canAcceptChildren(selected) {
                // Selected is a container - add as child
                canvasManager.registerUndoAction("Added \(component.type.rawValue) to \(selected.type.rawValue)")
                component.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: .zero)
                selected.addChild(component)
                canvasManager.selectedComponent = component
            } else if let parent = canvasManager.findParentComponent(of: selected.id) {
                // Selected is not a container but has a parent - add as sibling
                canvasManager.registerUndoAction("Added \(component.type.rawValue)")
                component.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: .zero)
                
                // Insert after the selected component
                if let index = parent.children.firstIndex(where: { $0.id == selected.id }) {
                    parent.children.insert(component, at: index + 1)
                } else {
                    parent.addChild(component)
                }
                canvasManager.selectedComponent = component
            } else {
                // Selected is at root level and can't accept children - add to root
                canvasManager.addComponent(component)
            }
        } else {
            // No selection - add to root
            canvasManager.addComponent(component)
        }
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

        let component = makeComponent()
        onAdd(component)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }

    private func makeComponent() -> UIComponent {
        let defaultOrigin = isFirstComponent ? CGPoint(x: 0, y: 0) : CGPoint(x: 100, y: 100)

        let component = UIComponent(
            type: componentType,
            properties: UIComponent.defaultProperties(for: componentType),
            frame: CGRect(origin: defaultOrigin, size: .zero),
            modifiers: []
        )

        if componentType == .button {
            let textChild = UIComponent(
                type: .text,
                properties: [
                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Continue", defaultValue: "Continue")
                ],
                frame: .zero
            )
            component.addChild(textChild)
        }

        return component
    }
}
