import SwiftUI

// MARK: - Main Editor View
struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HSplitView {
            // Left Panel - Hierarchy & Components
            LeftPanel(viewModel: viewModel)
                .frame(minWidth: 220, maxWidth: 280)
            
            // Center - Canvas
            CanvasView(viewModel: viewModel)
                .frame(minWidth: 420)
            
            // Right Panel - Inspector
            InspectorPanel(viewModel: viewModel)
                .frame(minWidth: 280, maxWidth: 320)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Undo/Redo
                Button(action: { viewModel.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!viewModel.canUndo)
                
                Button(action: { viewModel.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!viewModel.canRedo)
                
                Divider()
                
                // Component Actions
                Button(action: { viewModel.duplicateSelectedComponent() }) {
                    Image(systemName: "plus.square.on.square")
                }
                .disabled(viewModel.selectedComponent == nil)
                
                Button(action: { viewModel.removeSelectedComponent() }) {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.selectedComponent == nil)
                
                Divider()
                
                // Export
                Button(action: {
                    let json = viewModel.exportToJSON()
                    print(json)
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Design Editor")
        #if os(macOS)
        .navigationSubtitle(viewModel.state.metadata.name)
        #endif
    }
}

// MARK: - Left Panel (Hierarchy + Components)
struct LeftPanel: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var selectedTab: LeftPanelTab = .hierarchy
    
    enum LeftPanelTab: String, CaseIterable {
        case hierarchy = "Hierarchy"
        case components = "Components"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $selectedTab) {
                ForEach(LeftPanelTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)
            
            Divider()
            
            // Content
            switch selectedTab {
            case .hierarchy:
                HierarchyView(viewModel: viewModel)
            case .components:
                ComponentPaletteView(viewModel: viewModel)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Hierarchy View
struct HierarchyView: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.hierarchyNodes, id: \.id) { node in
                    HierarchyNodeView(node: node, viewModel: viewModel, depth: 0)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct HierarchyNodeView: View {
    let node: ComponentNode
    @ObservedObject var viewModel: EditorViewModel
    let depth: Int
    
    @State private var isExpanded: Bool = true
    
    private var isSelected: Bool {
        viewModel.state.selection.isSelected(node.id)
    }
    
    private var isVisible: Bool {
        viewModel.state.layers.isVisible(node.id)
    }
    
    private var isLocked: Bool {
        viewModel.state.layers.isLocked(node.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Node Row
            HStack(spacing: 4) {
                // Expand/Collapse
                if !node.children.isEmpty {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 16)
                }
                
                // Component Icon
                Image(systemName: node.component.type.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 16)
                
                // Name
                Text(node.component.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Visibility Toggle
                Button(action: { viewModel.toggleVisibility(node.id) }) {
                    Image(systemName: isVisible ? "eye" : "eye.slash")
                        .font(.system(size: 10))
                        .foregroundColor(isVisible ? .secondary : .red)
                }
                .buttonStyle(.plain)
                
                // Lock Toggle
                Button(action: { viewModel.toggleLocked(node.id) }) {
                    Image(systemName: isLocked ? "lock" : "lock.open")
                        .font(.system(size: 10))
                        .foregroundColor(isLocked ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, CGFloat(depth * 16) + 8)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.select(node.id)
            }
            
            // Children
            if isExpanded {
                ForEach(node.children, id: \.id) { child in
                    HierarchyNodeView(node: child, viewModel: viewModel, depth: depth + 1)
                }
            }
        }
    }
}

// MARK: - Component Palette View
struct ComponentPaletteView: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(viewModel.componentsByCategory.keys.sorted()), id: \.self) { category in
                    ComponentCategorySection(
                        category: category,
                        types: viewModel.componentsByCategory[category] ?? [],
                        viewModel: viewModel
                    )
                }
            }
            .padding(8)
        }
    }
}

struct ComponentCategorySection: View {
    let category: String
    let types: [DesignComponentType]
    @ObservedObject var viewModel: EditorViewModel
    
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(category)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            // Components Grid
            if isExpanded {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(types, id: \.self) { type in
                        ComponentButton(type: type, viewModel: viewModel)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ComponentButton: View {
    let type: DesignComponentType
    @ObservedObject var viewModel: EditorViewModel
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            viewModel.addComponent(type: type)
        }) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(isHovered ? .white : .primary)
                
                Text(type.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isHovered ? .white : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isHovered ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var scale: CGFloat = 0.75
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Pattern
                CanvasBackground()
                
                // Phone Frame
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        // Canvas Container
                        ZStack {
                            // Canvas Background
                            Rectangle()
                                .fill(Color(hex: viewModel.state.canvas.backgroundColor) ?? .white)
                                .frame(
                                    width: viewModel.state.canvas.width,
                                    height: viewModel.state.canvas.height
                                )
                                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                            
                            // Render Components
                            ForEach(viewModel.state.getRootComponents(), id: \.id) { component in
                                ComponentRenderer(component: component, viewModel: viewModel)
                            }
                        }
                        .scaleEffect(scale)
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                // Zoom Controls
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZoomControls(scale: $scale, viewModel: viewModel)
                            .padding()
                    }
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct CanvasBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 20
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                var x: CGFloat = 0
                while x < width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += gridSize
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y < height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += gridSize
                }
            }
            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        }
    }
}

struct ZoomControls: View {
    @Binding var scale: CGFloat
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { scale = max(0.25, scale - 0.25) }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.bordered)
            
            Text("\(Int(scale * 100))%")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .frame(width: 50)
            
            Button(action: { scale = min(2.0, scale + 0.25) }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.bordered)
            
            Divider().frame(height: 20)
            
            Button(action: { viewModel.toggleGrid() }) {
                Image(systemName: viewModel.state.canvas.gridEnabled ? "grid" : "grid.circle")
            }
            .buttonStyle(.bordered)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Component Renderer
struct ComponentRenderer: View {
    let component: DesignComponent
    @ObservedObject var viewModel: EditorViewModel
    
    private var isSelected: Bool {
        viewModel.state.selection.isSelected(component.id)
    }
    
    var body: some View {
        Group {
            renderComponent()
        }
        .overlay(
            isSelected ?
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.accentColor, lineWidth: 2)
                .padding(-2)
            : nil
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.select(component.id)
        }
    }
    
    @ViewBuilder
    private func renderComponent() -> some View {
        switch component.type {
        case .text:
            Text(component.properties.text ?? "Text")
                .font(.system(
                    size: component.properties.fontSize ?? 17,
                    weight: fontWeight(from: component.properties.fontWeight)
                ))
            
        case .image:
            if let systemName = component.properties.systemName {
                Image(systemName: systemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
        case .button:
            Button(component.properties.buttonLabel ?? "Button") {}
            
        case .vStack:
            VStack(
                alignment: horizontalAlignment(from: component.properties.alignment),
                spacing: component.properties.spacing ?? 8
            ) {
                renderChildren()
            }
            
        case .hStack:
            HStack(
                alignment: verticalAlignment(from: component.properties.alignment),
                spacing: component.properties.spacing ?? 8
            ) {
                renderChildren()
            }
            
        case .zStack:
            ZStack {
                renderChildren()
            }
            
        case .spacer:
            Spacer(minLength: component.properties.minLength)
            
        case .divider:
            Divider()
            
        case .rectangle:
            Rectangle()
            
        case .circle:
            Circle()
            
        case .capsule:
            Capsule()
            
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: component.properties.cornerRadius ?? 10)
            
        default:
            Text("[\(component.type.rawValue)]")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func renderChildren() -> some View {
        let children = viewModel.getChildren(of: component.id)
        ForEach(children, id: \.id) { child in
            ComponentRenderer(component: child, viewModel: viewModel)
        }
    }
    
    private func getChildren(of componentId: String) -> [DesignComponent] {
        viewModel.state.getChildren(of: componentId)
    }
    
    private func fontWeight(from string: String?) -> Font.Weight {
        switch string {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    
    private func horizontalAlignment(from string: String?) -> HorizontalAlignment {
        switch string {
        case "leading": return .leading
        case "center": return .center
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    private func verticalAlignment(from string: String?) -> VerticalAlignment {
        switch string {
        case "top": return .top
        case "center": return .center
        case "bottom": return .bottom
        default: return .center
        }
    }
}

// Extension for viewModel convenience
extension EditorViewModel {
    func getChildren(of componentId: String) -> [DesignComponent] {
        state.getChildren(of: componentId)
    }
}

// MARK: - Preview
#Preview {
    EditorView()
        .frame(width: 1200, height: 800)
}
