import SwiftUI

// MARK: - Component Types and Instances

enum ComponentType: String, Identifiable, CaseIterable {
    case text = "Text"
    case image = "Image"
    case button = "Button"
    case vstack = "VStack"
    case hstack = "HStack"
    
    var id: String { self.rawValue }
}

struct ComponentInstance: Identifiable {
    let id: String = UUID().uuidString
    let type: ComponentType
    // Text properties
    var textValue: String? = nil
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderlined: Bool = false
    var textCornerRadius: Double = 12
    // Button properties
    var buttonLabel: String? = nil
    var isProminent: Bool = true
    var buttonCornerRadius: Double = 12
    var buttonHeight: Double = 44 // Default height
    // Image properties
    var imageName: String? = "photo"
    var imageColor: Color = .accentColor
    var imageHeight: Double = 80
    // Nesting
    var children: [ComponentInstance] = []
    // Advanced text properties
    var textTransform: TextTransform = .default
    var fontName: String = "System"
    var fontWeight: Font.Weight = .regular
    var fontSize: Double = 17
    var textColor: Color = .primary
    var textAlignment: TextAlignment = .leading
    var lineLimit: Int? = nil
    var letterSpacing: Double = 0
    var lineSpacing: Double = 0
    var textBackground: Color = .clear
    var fontStyle: String = "Body" // Default
}

// Helper to check if a component is a container
extension ComponentInstance {
    var isContainer: Bool {
        type == .vstack || type == .hstack
    }
}

// MARK: - Studio Home

struct StudioHome: View {
    @State private var showSidebar: Bool = true
    @State private var showInspector: Bool = true
    @State private var searchText: String = ""
    let components: [ComponentType] = ComponentType.allCases
    @State private var canvasComponents: [ComponentInstance] = []
    @AppStorage("canvasColorScheme") private var canvasColorSchemeRaw: String = "light"
    var canvasColorScheme: ColorScheme {
        canvasColorSchemeRaw == "dark" ? .dark : .light
    }
    @State private var selectedComponentID: String? = nil
    @State private var showColorPicker = false
    @State private var showFontPicker = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Sidebar (Component Palette)
            if showSidebar {
                VStack(alignment: .leading) {
                    Text("Components")
                        .font(.title2)
                        .bold()
                        .padding(.top)
                    TextField("Search components", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical)
                    List {
                        ForEach(components.filter { searchText.isEmpty ? true : $0.rawValue.localizedCaseInsensitiveContains(searchText) }, id: \.self) { component in
                            HStack {
                                Label(component.rawValue, systemImage: "square.grid.2x2")
                                    .padding(.vertical, 4)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let selectedID = selectedComponentID {
                                    // Try to add to selected container
                                    func tryAddToContainer(id: String, component: ComponentInstance, array: inout [ComponentInstance]) -> Bool {
                                        for i in array.indices {
                                            if array[i].id == id && array[i].isContainer {
                                                array[i].children.append(component)
                                                return true
                                            } else if array[i].isContainer {
                                                if tryAddToContainer(id: id, component: component, array: &array[i].children) {
                                                    return true
                                                }
                                            }
                                        }
                                        return false
                                    }
                                    var added = false
                                    if component == .text {
                                        added = tryAddToContainer(id: selectedID, component: ComponentInstance(type: component, textValue: "Sample Text"), array: &canvasComponents)
                                    } else if component == .button {
                                        added = tryAddToContainer(id: selectedID, component: ComponentInstance(type: component, buttonLabel: "Button"), array: &canvasComponents)
                                    } else if component == .image {
                                        added = tryAddToContainer(id: selectedID, component: ComponentInstance(type: component, imageName: "photo", imageColor: .accentColor, imageHeight: 80), array: &canvasComponents)
                                    } else {
                                        added = tryAddToContainer(id: selectedID, component: ComponentInstance(type: component), array: &canvasComponents)
                                    }
                                    if !added {
                                        // Fallback: add to root
                                        if component == .text {
                                            canvasComponents.append(ComponentInstance(type: component, textValue: "Sample Text"))
                                        } else if component == .button {
                                            canvasComponents.append(ComponentInstance(type: component, buttonLabel: "Button"))
                                        } else if component == .image {
                                            canvasComponents.append(ComponentInstance(type: component, imageName: "photo", imageColor: .accentColor, imageHeight: 80))
                                        } else {
                                            canvasComponents.append(ComponentInstance(type: component))
                                        }
                                    }
                                } else {
                                    // No selection: add to root
                                    if component == .text {
                                        canvasComponents.append(ComponentInstance(type: component, textValue: "Sample Text"))
                                    } else if component == .button {
                                        canvasComponents.append(ComponentInstance(type: component, buttonLabel: "Button"))
                                    } else if component == .image {
                                        canvasComponents.append(ComponentInstance(type: component, imageName: "photo", imageColor: .accentColor, imageHeight: 80))
                                    } else {
                                        canvasComponents.append(ComponentInstance(type: component))
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    Spacer()
                }
                .padding()
                .frame(width: 260)
                .background(.ultraThinMaterial)
            }
            
            Spacer(minLength: 0)
            
            // Phone Canvas (Center)
            ZStack {
                // Device frame
                RoundedRectangle(cornerRadius: 48)
                    .fill(canvasColorScheme == .light ? Color.white : Color.black)
                    .shadow(color: Color.black.opacity(0.2), radius: 32, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 48)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                // Canvas content
                ScrollView {
                    VStack(spacing: 24) {
                        PhoneStatusBarView()
                        ForEach(Array(canvasComponents.enumerated()), id: \.element.id) { index, component in
                            renderComponent(component, selectedComponentID: selectedComponentID, onSelect: { selectedComponentID = $0 })
                                .onDrag {
                                    NSItemProvider(object: component.id as NSString)
                                }
                                .onDrop(of: [.text], isTargeted: nil) { providers in
                                    providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                        if let data = data as? Data, let draggedId = String(data: data, encoding: .utf8) {
                                            DispatchQueue.main.async {
                                                if let fromIndex = canvasComponents.firstIndex(where: { $0.id == draggedId }) {
                                                    let item = canvasComponents.remove(at: fromIndex)
                                                    let toIndex = index > fromIndex ? index - 1 : index
                                                    canvasComponents.insert(item, at: toIndex)
                                                }
                                            }
                                        }
                                    }
                                    return true
                                }
                        }
                        .onMove { indices, newOffset in
                            canvasComponents.move(fromOffsets: indices, toOffset: newOffset)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.clear)
                }
                .clipShape(RoundedRectangle(cornerRadius: 48))
                .frame(width: 400, height: 850)
            }
            .frame(width: 400, height: 850)
            
            Spacer(minLength: 0)
            
            // Inspector (Properties Panel)
            if showInspector {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Inspector")
                            .font(.title2)
                            .bold()
                            .padding(.top)
                        Divider()
                        if let selectedID = selectedComponentID,
                           let index = canvasComponents.firstIndex(where: { $0.id == selectedID }) {
                            let selected = canvasComponents[index]
                            Text("Component: \(selected.type.rawValue)")
                                .font(.headline)
                            if selected.type == .text {
                                TextField("Text", text: Binding(
                                    get: { canvasComponents[index].textValue ?? "" },
                                    set: { canvasComponents[index].textValue = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical)
                                Toggle("Bold", isOn: Binding(
                                    get: { canvasComponents[index].isBold },
                                    set: { canvasComponents[index].isBold = $0 }
                                ))
                                Toggle("Italic", isOn: Binding(
                                    get: { canvasComponents[index].isItalic },
                                    set: { canvasComponents[index].isItalic = $0 }
                                ))
                                Toggle("Underlined", isOn: Binding(
                                    get: { canvasComponents[index].isUnderlined },
                                    set: { canvasComponents[index].isUnderlined = $0 }
                                ))
                                HStack {
                                    Text("Corner Radius")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].textCornerRadius },
                                        set: { canvasComponents[index].textCornerRadius = $0 }
                                    ), in: 0...40)
                                    Text("\(Int(canvasComponents[index].textCornerRadius))")
                                        .frame(width: 32)
                                }
                                Picker("Transform", selection: Binding(
                                    get: { canvasComponents[index].textTransform },
                                    set: { canvasComponents[index].textTransform = $0 }
                                )) {
                                    ForEach(TextTransform.allCases, id: \.self) { t in
                                        Text(t.rawValue.capitalized)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical)

                                Button(action: { showFontPicker = true }) {
                                    HStack {
                                        Text("Font")
                                        Spacer()
                                        Text(canvasComponents[index].fontStyle)
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .sheet(isPresented: $showFontPicker) {
                                    SwiftUIFontPicker(selectedFontStyle: Binding(
                                        get: { canvasComponents[index].fontStyle },
                                        set: { newStyle in
                                            canvasComponents[index].fontStyle = newStyle
                                            showFontPicker = false // Auto-dismiss after selection
                                        }
                                    ))
                                }
                                .padding(.vertical, 2)

                                TextField("Font Name", text: Binding(
                                    get: { canvasComponents[index].fontName },
                                    set: { canvasComponents[index].fontName = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 2)

                                Picker("Font Weight", selection: Binding(
                                    get: { canvasComponents[index].fontWeight },
                                    set: { canvasComponents[index].fontWeight = $0 }
                                )) {
                                    ForEach([Font.Weight.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black], id: \.self) { w in
                                        Text(String(describing: w).capitalized)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.vertical, 2)

                                HStack {
                                    Text("Font Size")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].fontSize },
                                        set: { canvasComponents[index].fontSize = $0 }
                                    ), in: 8...64)
                                    Text("\(Int(canvasComponents[index].fontSize))")
                                        .frame(width: 32)
                                }

                                Button(action: { showColorPicker = true }) {
                                    HStack {
                                        Circle().fill(canvasComponents[index].textColor).frame(width: 24, height: 24)
                                        Text("Text Color")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .sheet(isPresented: $showColorPicker) {
                                    SwiftUIColorPicker(selectedColor: Binding(
                                        get: { canvasComponents[index].textColor },
                                        set: { newColor in
                                            canvasComponents[index].textColor = newColor
                                            showColorPicker = false // Auto-dismiss after selection
                                        }
                                    ))
                                }
                                .padding(.vertical, 2)

                                Button(action: {
                                    // This action will be replaced by a custom color picker
                                }) {
                                    HStack {
                                        Circle().fill(canvasComponents[index].textBackground).frame(width: 24, height: 24)
                                        Text("Background")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.vertical, 2)

                                Picker("Alignment", selection: Binding(
                                    get: { canvasComponents[index].textAlignment },
                                    set: { canvasComponents[index].textAlignment = $0 }
                                )) {
                                    Text("Leading").tag(TextAlignment.leading)
                                    Text("Center").tag(TextAlignment.center)
                                    Text("Trailing").tag(TextAlignment.trailing)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 2)

                                HStack {
                                    Text("Line Limit")
                                    Stepper(value: Binding(
                                        get: { canvasComponents[index].lineLimit ?? 0 },
                                        set: { canvasComponents[index].lineLimit = $0 == 0 ? nil : $0 }
                                    ), in: 0...10) {
                                        Text(canvasComponents[index].lineLimit == nil || canvasComponents[index].lineLimit == 0 ? "Unlimited" : "\(canvasComponents[index].lineLimit!)")
                                    }
                                }

                                HStack {
                                    Text("Letter Spacing")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].letterSpacing },
                                        set: { canvasComponents[index].letterSpacing = $0 }
                                    ), in: 0...10)
                                    Text(String(format: "%.1f", canvasComponents[index].letterSpacing))
                                        .frame(width: 32)
                                }
                                HStack {
                                    Text("Line Spacing")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].lineSpacing },
                                        set: { canvasComponents[index].lineSpacing = $0 }
                                    ), in: 0...20)
                                    Text(String(format: "%.1f", canvasComponents[index].lineSpacing))
                                        .frame(width: 32)
                                }
                            } else if selected.type == .button {
                                TextField("Label", text: Binding(
                                    get: { canvasComponents[index].buttonLabel ?? "" },
                                    set: { canvasComponents[index].buttonLabel = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical)
                                Toggle("Prominent", isOn: Binding(
                                    get: { canvasComponents[index].isProminent },
                                    set: { canvasComponents[index].isProminent = $0 }
                                ))
                                HStack {
                                    Text("Corner Radius")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].buttonCornerRadius },
                                        set: { canvasComponents[index].buttonCornerRadius = $0 }
                                    ), in: 0...40)
                                    Text("\(Int(canvasComponents[index].buttonCornerRadius))")
                                        .frame(width: 32)
                                }
                                HStack {
                                    Text("Height")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].buttonHeight },
                                        set: { canvasComponents[index].buttonHeight = $0 }
                                    ), in: 30...100)
                                    Text("\(Int(canvasComponents[index].buttonHeight))")
                                        .frame(width: 32)
                                }
                            } else if selected.type == .image {
                                TextField("SF Symbol", text: Binding(
                                    get: { canvasComponents[index].imageName ?? "" },
                                    set: { canvasComponents[index].imageName = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical)

                                ColorPicker("Color", selection: Binding(
                                    get: { canvasComponents[index].imageColor },
                                    set: { canvasComponents[index].imageColor = $0 }
                                ))

                                HStack {
                                    Text("Height")
                                    Slider(value: Binding(
                                        get: { canvasComponents[index].imageHeight },
                                        set: { canvasComponents[index].imageHeight = $0 }
                                    ), in: 30...200)
                                    Text("\(Int(canvasComponents[index].imageHeight))")
                                        .frame(width: 32)
                                }
                            }
                            Button(role: .destructive) {
                                _ = deleteComponent(withId: selectedID, in: &canvasComponents)
                                selectedComponentID = nil
                            } label: {
                                Label("Delete Component", systemImage: "trash")
                            }
                            .padding(.top)
                        } else {
                            Text("Select a component to edit its properties.")
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                    }
                    .padding()
                }
                .frame(width: 260)
                .background(.ultraThinMaterial)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { showSidebar.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: { showInspector.toggle() }) {
                    Image(systemName: "sidebar.right")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    canvasColorSchemeRaw = (canvasColorScheme == .light) ? "dark" : "light"
                }) {
                    Image(systemName: canvasColorScheme == .light ? "moon.fill" : "sun.max.fill")
                }
                .help("Toggle Canvas Color Scheme")
            }
        }
    }
    
    private func renderComponent(_ component: ComponentInstance, selectedComponentID: String?, onSelect: @escaping (String) -> Void) -> AnyView {
        let isSelected = selectedComponentID == component.id
        return AnyView(
            VStack(spacing: 0) {
                if isSelected {
                    HStack {
                        Button(action: {
                            if let index = canvasComponents.firstIndex(where: { $0.id == component.id }) {
                                if index > 0 {
                                    canvasComponents.swapAt(index, index - 1)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.up")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(canvasComponents.firstIndex(where: { $0.id == component.id }) == 0)

                        Button(action: {
                            if let index = canvasComponents.firstIndex(where: { $0.id == component.id }) {
                                if index < canvasComponents.count - 1 {
                                    canvasComponents.swapAt(index, index + 1)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.down")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(canvasComponents.firstIndex(where: { $0.id == component.id }) == canvasComponents.count - 1)

                        Spacer()
                    }
                    .padding(.bottom, 2)
                }
                Group {
                    switch component.type {
                    case .text:
                        StudioTextView(
                            text: component.textValue ?? "",
                            isBold: component.isBold,
                            isItalic: component.isItalic,
                            isUnderlined: component.isUnderlined,
                            cornerRadius: component.textCornerRadius,
                            textTransform: component.textTransform,
                            fontName: component.fontName,
                            fontWeight: component.fontWeight,
                            fontSize: component.fontSize,
                            textColor: component.textColor,
                            textAlignment: component.textAlignment,
                            lineLimit: component.lineLimit,
                            letterSpacing: component.letterSpacing,
                            lineSpacing: component.lineSpacing,
                            textBackground: component.textBackground,
                            fontStyle: component.fontStyle
                        )
                    case .image:
                        StudioImageView(
                            name: component.imageName ?? "photo",
                            color: component.imageColor,
                            height: component.imageHeight
                        )
                    case .button:
                        StudioButtonView(
                            label: component.buttonLabel ?? "Button",
                            isProminent: component.isProminent,
                            cornerRadius: component.buttonCornerRadius,
                            height: component.buttonHeight,
                            onSelect: { onSelect(component.id) }
                        )
                    case .vstack:
                        VStack(spacing: 12) {
                            if component.children.isEmpty {
                                // Placeholder for empty VStack
                                Text("Empty VStack")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .background(Color.gray.opacity(0.08))
                                    .cornerRadius(8)
                            } else {
                                ForEach(component.children) { child in
                                    renderComponent(child, selectedComponentID: selectedComponentID, onSelect: onSelect)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                        .contentShape(Rectangle()) // Make the whole area clickable
                        .onTapGesture {
                            onSelect(component.id)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                    case .hstack:
                        HStack(spacing: 12) {
                            if component.children.isEmpty {
                                // Placeholder for empty HStack
                                Text("Empty HStack")
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 60, maxHeight: .infinity)
                                    .background(Color.gray.opacity(0.08))
                                    .cornerRadius(8)
                            } else {
                                ForEach(component.children) { child in
                                    renderComponent(child, selectedComponentID: selectedComponentID, onSelect: onSelect)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                        .contentShape(Rectangle()) // Make the whole area clickable
                        .onTapGesture {
                            onSelect(component.id)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .onTapGesture {
                    onSelect(component.id)
                }
            }
        )
    }

    // Helper to find and mutate a component by id (recursive)
    func updateComponent(id: String, update: (inout ComponentInstance) -> Void, in array: inout [ComponentInstance]) {
        for i in array.indices {
            if array[i].id == id {
                update(&array[i])
                return
            } else if array[i].isContainer {
                updateComponent(id: id, update: update, in: &array[i].children)
            }
        }
    }

    // Helper to delete a component by id (recursive)
    private func deleteComponent(withId id: String, in array: inout [ComponentInstance]) -> Bool {
        for i in array.indices {
            if array[i].id == id {
                array.remove(at: i)
                return true
            } else if array[i].isContainer {
                if deleteComponent(withId: id, in: &array[i].children) {
                    return true
                }
            }
        }
        return false
    }

    // Helper to find a component by id (recursive)
    private func findComponent(withId id: String, in array: [ComponentInstance]) -> (component: ComponentInstance, index: Int, parentArray: [ComponentInstance])? {
        for (i, comp) in array.enumerated() {
            if comp.id == id {
                return (comp, i, array)
            } else if comp.isContainer {
                if let found = findComponent(withId: id, in: comp.children) {
                    return found
                }
            }
        }
        return nil
    }

    // Helper to find index path for a component by id (recursive)
    private func findIndexPath(for id: String, in array: [ComponentInstance], currentPath: [Int] = []) -> [Int]? {
        for (i, comp) in array.enumerated() {
            if comp.id == id {
                return currentPath + [i]
            } else if comp.isContainer {
                if let childPath = findIndexPath(for: id, in: comp.children, currentPath: currentPath + [i, -1]) {
                    return childPath
                }
            }
        }
        return nil
    }

    // Helper to remove a component by id (recursive)
    private func removeComponent(withId id: String, in array: inout [ComponentInstance]) -> ComponentInstance? {
        for i in array.indices {
            if array[i].id == id {
                return array.remove(at: i)
            } else if array[i].isContainer {
                if let removed = removeComponent(withId: id, in: &array[i].children) {
                    return removed
                }
            }
        }
        return nil
    }

    // Helper to add a component to a container by id (recursive)
    private func addComponentToContainer(containerId: String, component: ComponentInstance, in array: inout [ComponentInstance]) -> Bool {
        for i in array.indices {
            if array[i].id == containerId && array[i].isContainer {
                array[i].children.append(component)
                return true
            } else if array[i].isContainer {
                if addComponentToContainer(containerId: containerId, component: component, in: &array[i].children) {
                    return true
                }
            }
        }
        return false
    }

    // Helper to handle drop into containers
    private func handleDrop(into containerId: String, providers: [NSItemProvider]) -> Bool {
        providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            if let data = data as? Data, let draggedId = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    // Remove the dragged component from its current location
                    if let draggedComponent = removeComponent(withId: draggedId, in: &canvasComponents) {
                        // Add it to the target container's children
                        let success = addComponentToContainer(containerId: containerId, component: draggedComponent, in: &canvasComponents)
                        if !success {
                            // Handle failure (optional)
                        }
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Component Views

struct StudioTextView: View {
    var text: String
    var isBold: Bool
    var isItalic: Bool
    var isUnderlined: Bool
    var cornerRadius: Double
    var textTransform: TextTransform
    var fontName: String
    var fontWeight: Font.Weight
    var fontSize: Double
    var textColor: Color
    var textAlignment: TextAlignment
    var lineLimit: Int?
    var letterSpacing: Double
    var lineSpacing: Double
    var textBackground: Color
    var fontStyle: String
    var body: some View {
        var displayText = text
        switch textTransform {
        case .uppercase: displayText = text.uppercased()
        case .lowercase: displayText = text.lowercased()
        case .capitalized: displayText = text.capitalized
        default: break
        }
        let font = swiftUIFontStyles.first(where: { $0.name == fontStyle })?.font ?? .body
        let textView = Text(displayText)
            .font(font)
            .foregroundColor(textColor)
            .underline(isUnderlined)
            .kerning(letterSpacing)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(textAlignment)
            .lineLimit(lineLimit)
        return textView
            .padding()
            .frame(maxWidth: .infinity)
            .background(textBackground)
            .cornerRadius(cornerRadius)
    }
}

struct StudioImageView: View {
    var name: String
    var color: Color
    var height: Double
    var body: some View {
        Image(systemName: name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .foregroundColor(color)
            .padding()
            .background(Color.gray.opacity(0.12))
            .cornerRadius(12)
    }
}

struct StudioButtonView: View {
    var label: String
    var isProminent: Bool
    var cornerRadius: Double
    var height: Double
    var onSelect: () -> Void

    var body: some View {
        Group {
            Button(action: {}) {
                Text(label)
                    .frame(maxWidth: .infinity, minHeight: height)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(cornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 4)
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

struct StudioVStackView: View {
    var body: some View {
        VStack {
            Text("VStack")
                .font(.headline)
            Divider()
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
}

struct StudioHStackView: View {
    var body: some View {
        HStack {
            Text("HStack")
                .font(.headline)
            Divider()
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }
} 

struct PhoneStatusBarView: View {
    @State private var time: String = PhoneStatusBarView.currentTimeString()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    static func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack {
            Text(time)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .frame(width: 50, alignment: .leading)
            Spacer()
            Image(systemName: "wifi")
                .font(.system(size: 16, weight: .regular))
            Image(systemName: "battery.100")
                .font(.system(size: 16, weight: .regular))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.top, 12)
        .padding(.bottom, 4)
        .onReceive(timer) { _ in
            time = Self.currentTimeString()
        }
    }
} 

enum TextTransform: String, CaseIterable {
    case `default`, uppercase, lowercase, capitalized
} 

struct SwiftUIColorPicker: View {
    @Binding var selectedColor: Color
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(swiftUIColors, id: \.name) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 28, height: 28)
                        Text(item.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedColor == item.color {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedColor = item.color
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .frame(maxHeight: 350)
    }
}

let swiftUIColors: [(name: String, color: Color)] = [
    ("Primary", .primary),
    ("Secondary", .secondary),
    ("Red", .red),
    ("Orange", .orange),
    ("Yellow", .yellow),
    ("Green", .green),
    ("Mint", .mint),
    ("Teal", .teal),
    ("Cyan", .cyan),
    ("Blue", .blue),
    ("Indigo", .indigo),
    ("Purple", .purple),
    ("Pink", .pink),
    ("Brown", .brown),
    ("Gray", .gray),
    ("Black", .black),
    ("White", .white)
] 

struct SwiftUIFontPicker: View {
    @Binding var selectedFontStyle: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(swiftUIFontStyles, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(item.font)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedFontStyle == item.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFontStyle = item.name
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxHeight: 350)
    }
}

let swiftUIFontStyles: [(name: String, font: Font)] = [
    ("Large Title", .largeTitle),
    ("Title 1", .title),
    ("Title 2", .title2),
    ("Title 3", .title3),
    ("Headline", .headline),
    ("Body", .body),
    ("Callout", .callout),
    ("Subheadline", .subheadline),
    ("Footnote", .footnote),
    ("Caption", .caption),
    ("Caption 2", .caption2)
] 
