import SwiftUI

// MARK: - Inspector Panel
struct InspectorPanel: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $viewModel.inspectorTab) {
                ForEach(InspectorTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch viewModel.inspectorTab {
                    case .properties:
                        PropertiesInspector(viewModel: viewModel)
                    case .modifiers:
                        ModifiersInspector(viewModel: viewModel)
                    case .layers:
                        LayersInspector(viewModel: viewModel)
                    }
                }
                .padding(12)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Properties Inspector
struct PropertiesInspector: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        if let component = viewModel.selectedComponent {
            VStack(alignment: .leading, spacing: 16) {
                // Component Info
                InspectorSection(title: "Component") {
                    HStack {
                        Image(systemName: component.type.iconName)
                            .foregroundColor(.secondary)
                        Text(component.type.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    
                    TextField("Name", text: Binding(
                        get: { component.name },
                        set: { newName in
                            if var comp = viewModel.state.components[component.id] {
                                comp.name = newName
                                viewModel.state.updateComponent(comp)
                            }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                
                // Type-specific properties
                switch component.type {
                case .text:
                    TextPropertiesSection(viewModel: viewModel, component: component)
                case .image:
                    ImagePropertiesSection(viewModel: viewModel, component: component)
                case .button:
                    ButtonPropertiesSection(viewModel: viewModel, component: component)
                case .vStack, .hStack:
                    StackPropertiesSection(viewModel: viewModel, component: component)
                case .zStack:
                    ZStackPropertiesSection(viewModel: viewModel, component: component)
                case .spacer:
                    SpacerPropertiesSection(viewModel: viewModel, component: component)
                case .roundedRectangle:
                    RoundedRectanglePropertiesSection(viewModel: viewModel, component: component)
                default:
                    Text("No editable properties")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text("Select a component")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Property Sections
struct TextPropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "Text") {
            TextField("Content", text: Binding(
                get: { component.properties.text ?? "" },
                set: { viewModel.updateText($0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
        
        InspectorSection(title: "Font") {
            HStack {
                Text("Size")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("", value: Binding(
                    get: { component.properties.fontSize ?? 17 },
                    set: { viewModel.updateFontSize($0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            }
            
            HStack {
                Text("Weight")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { component.properties.fontWeight ?? "regular" },
                    set: { viewModel.updateFontWeight($0) }
                )) {
                    ForEach(["ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"], id: \.self) { weight in
                        Text(weight.capitalized).tag(weight)
                    }
                }
                .frame(width: 120)
            }
        }
    }
}

struct ImagePropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "Image") {
            HStack {
                Text("SF Symbol")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("", text: Binding(
                    get: { component.properties.systemName ?? "photo" },
                    set: { newValue in
                        viewModel.updateProperty(\.systemName, value: newValue)
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
            }
            
            HStack {
                Text("Resizable")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { component.properties.resizable ?? true },
                    set: { viewModel.updateProperty(\.resizable, value: $0) }
                ))
            }
        }
    }
}

struct ButtonPropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "Button") {
            TextField("Label", text: Binding(
                get: { component.properties.buttonLabel ?? "Button" },
                set: { viewModel.updateProperty(\.buttonLabel, value: $0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}

struct StackPropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "Stack") {
            HStack {
                Text("Alignment")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { component.properties.alignment ?? "center" },
                    set: { viewModel.updateAlignment($0) }
                )) {
                    if component.type == .vStack || component.type == .lazyVStack {
                        Text("Leading").tag("leading")
                        Text("Center").tag("center")
                        Text("Trailing").tag("trailing")
                    } else {
                        Text("Top").tag("top")
                        Text("Center").tag("center")
                        Text("Bottom").tag("bottom")
                    }
                }
                .frame(width: 120)
            }
            
            HStack {
                Text("Spacing")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("", value: Binding(
                    get: { component.properties.spacing ?? 8 },
                    set: { viewModel.updateSpacing($0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            }
        }
    }
}

struct ZStackPropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "ZStack") {
            HStack {
                Text("Alignment")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { component.properties.alignment ?? "center" },
                    set: { viewModel.updateAlignment($0) }
                )) {
                    ForEach(["topLeading", "top", "topTrailing", "leading", "center", "trailing", "bottomLeading", "bottom", "bottomTrailing"], id: \.self) { alignment in
                        Text(alignment).tag(alignment)
                    }
                }
                .frame(width: 120)
            }
        }
    }
}

struct SpacerPropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "Spacer") {
            HStack {
                Text("Min Length")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("", value: Binding(
                    get: { component.properties.minLength ?? 0 },
                    set: { viewModel.updateProperty(\.minLength, value: $0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            }
        }
    }
}

struct RoundedRectanglePropertiesSection: View {
    @ObservedObject var viewModel: EditorViewModel
    let component: DesignComponent
    
    var body: some View {
        InspectorSection(title: "Shape") {
            HStack {
                Text("Corner Radius")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("", value: Binding(
                    get: { component.properties.cornerRadius ?? 10 },
                    set: { viewModel.updateProperty(\.cornerRadius, value: $0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            }
        }
    }
}

// MARK: - Modifiers Inspector
struct ModifiersInspector: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var showAddModifier = false
    
    var body: some View {
        if let component = viewModel.selectedComponent {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Modifiers")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Button(action: { showAddModifier = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                
                // Modifier List
                if component.modifiers.isEmpty {
                    Text("No modifiers applied")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(component.modifiers.enumerated()), id: \.element.id) { index, modifier in
                        ModifierRow(modifier: modifier, index: index, viewModel: viewModel)
                    }
                }
            }
            .sheet(isPresented: $showAddModifier) {
                AddModifierSheet(viewModel: viewModel)
            }
        } else {
            Text("Select a component to edit modifiers")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct ModifierRow: View {
    let modifier: DesignModifier
    let index: Int
    @ObservedObject var viewModel: EditorViewModel
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: modifier.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(modifier.displayName)
                    .font(.system(size: 12, weight: .medium))
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { viewModel.removeModifier(at: index) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                ModifierEditor(modifier: modifier, index: index, viewModel: viewModel)
            }
        }
        .padding(8)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(6)
    }
}

struct ModifierEditor: View {
    let modifier: DesignModifier
    let index: Int
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch modifier {
            case .padding(_, let all, let horizontal, let vertical, _, _, _, _):
                HStack {
                    Text("All")
                    Spacer()
                    Text("\(Int(all ?? horizontal ?? vertical ?? 0))")
                        .foregroundColor(.secondary)
                }
                
            case .foregroundColor(_, let color):
                HStack {
                    Text("Color")
                    Spacer()
                    ColorPicker("", selection: .constant(Color(hex: color) ?? .primary))
                        .labelsHidden()
                }
                
            case .cornerRadius(_, let radius):
                HStack {
                    Text("Radius")
                    Spacer()
                    Text("\(Int(radius))")
                        .foregroundColor(.secondary)
                }
                
            case .shadow(_, let color, let radius, let x, let y):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Radius: \(Int(radius))")
                        Spacer()
                    }
                    HStack {
                        Text("Offset: (\(Int(x)), \(Int(y)))")
                        Spacer()
                    }
                }
                
            default:
                Text("Edit in code")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(size: 11))
    }
}

struct AddModifierSheet: View {
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.dismiss) var dismiss
    
    let commonModifiers: [(String, () -> DesignModifier)] = [
        ("Padding", { ModifierFactory.padding(16) }),
        ("Background", { ModifierFactory.background(color: "#007AFF") }),
        ("Foreground Color", { ModifierFactory.foregroundColor("#000000") }),
        ("Corner Radius", { ModifierFactory.cornerRadius(12) }),
        ("Shadow", { ModifierFactory.shadow(radius: 8, y: 4) }),
        ("Opacity", { ModifierFactory.opacity(0.5) }),
        ("Frame", { ModifierFactory.frame(width: 100, height: 100) }),
        ("Border", { ModifierFactory.border(color: "#000000", width: 1) })
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Modifier")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()
            
            Divider()
            
            // Modifiers List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(commonModifiers, id: \.0) { name, factory in
                        Button(action: {
                            viewModel.addModifier(factory())
                            dismiss()
                        }) {
                            HStack {
                                Text(name)
                                Spacer()
                                Image(systemName: "plus")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(width: 300, height: 400)
    }
}

// MARK: - Layers Inspector
struct LayersInspector: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layer Order")
                .font(.system(size: 13, weight: .semibold))
            
            ForEach(viewModel.state.layers.order.reversed(), id: \.self) { componentId in
                if let component = viewModel.state.components[componentId] {
                    LayerRow(component: component, viewModel: viewModel)
                }
            }
        }
    }
}

struct LayerRow: View {
    let component: DesignComponent
    @ObservedObject var viewModel: EditorViewModel
    
    private var isSelected: Bool {
        viewModel.state.selection.isSelected(component.id)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: component.type.iconName)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(component.name)
                .font(.system(size: 12))
                .lineLimit(1)
            
            Spacer()
            
            // Move buttons
            Button(action: { viewModel.moveLayer(component.id, direction: 1) }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            
            Button(action: { viewModel.moveLayer(component.id, direction: -1) }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.select(component.id)
        }
    }
}

// MARK: - Inspector Section
struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
    }
}

// MARK: - Editor Toolbar
struct EditorToolbar: ToolbarContent {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some ToolbarContent {
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
                print(json) // In a real app, save to file or clipboard
            }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        
        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }
}
