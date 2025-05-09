import SwiftUI

struct ComponentRenderer: View {
    let component: UIComponent
    
    var body: some View {
        renderComponent(component)
            .position(x: component.position.x, y: component.position.y)
            .frame(width: component.size.width, height: component.size.height)
    }
    
    @ViewBuilder
    private func renderComponent(_ component: UIComponent) -> some View {
        switch component.type {
        case .text:
            renderText(component)
        case .rectangle:
            renderRectangle(component)
        case .vstack:
            renderVStack(component)
        case .hstack:
            renderHStack(component)
        case .zstack:
            renderZStack(component)
        }
    }
    
    private func renderText(_ component: UIComponent) -> some View {
        Text(component.textContent ?? "")
            .foregroundColor(component.style?.foregroundColor)
            .padding(component.style?.padding ?? 0)
    }
    
    private func renderRectangle(_ component: UIComponent) -> some View {
        Rectangle()
            .fill(component.style?.backgroundColor ?? .clear)
            .cornerRadius(component.style?.cornerRadius ?? 0)
            .padding(component.style?.padding ?? 0)
    }
    
    private func renderVStack(_ component: UIComponent) -> some View {
        VStack(alignment: component.style?.alignment?.swiftUIAlignment ?? .center,
               spacing: component.style?.spacing) {
            ForEach(component.children ?? []) { child in
                ComponentRenderer(component: child)
            }
        }
        .padding(component.style?.padding ?? 0)
        .background(component.style?.backgroundColor)
    }
    
    private func renderHStack(_ component: UIComponent) -> some View {
        HStack(spacing: component.style?.spacing) {
            ForEach(component.children ?? []) { child in
                ComponentRenderer(component: child)
            }
        }
        .padding(component.style?.padding ?? 0)
        .background(component.style?.backgroundColor)
    }
    
    private func renderZStack(_ component: UIComponent) -> some View {
        ZStack {
            ForEach(component.children ?? []) { child in
                ComponentRenderer(component: child)
            }
        }
        .padding(component.style?.padding ?? 0)
        .background(component.style?.backgroundColor)
    }
} 