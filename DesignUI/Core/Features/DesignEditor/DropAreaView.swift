import SwiftUI
import UniformTypeIdentifiers

// MARK: - Draggable Component
struct DraggableComponent: Identifiable {
    let id = UUID()
    let name: String
    var view: AnyView
    var code: String
    var modifiers: [Modifier] = [] // Track applied modifiers
}

// MARK: - Modifier Struct
struct Modifier {
    let name: String
    var value: CGFloat? = nil // Allow value modification for properties like padding
    let code: (CGFloat?) -> String
    let apply: (AnyView, CGFloat?) -> AnyView
}

// Predefined list of components
let components: [DraggableComponent] = [
    DraggableComponent(
        name: "Button",
        view: AnyView(Button("Click Me") {}),
        code: "Button(\"Click Me\")"
    ),
    DraggableComponent(
        name: "Text",
        view: AnyView(Text("Hello, World!").foregroundColor(.black)),
        code: "Text(\"Hello, World!\")"
    )
]

// Predefined list of possible modifiers
let modifiers: [Modifier] = [
    Modifier(name: "Padding", value: 10, code: { value in ".padding(\(value ?? 0))" }, apply: { view, value in AnyView(view.padding(value ?? 0)) }),
    Modifier(name: "Background Color", code: { _ in ".background(Color.yellow)" }, apply: { view, _ in AnyView(view.background(Color.yellow)) })
]

// MARK: - Custom Drop Delegate
struct CustomDropDelegate: DropDelegate {
    @Binding var droppedComponents: [DraggableComponent]
    @Binding var generatedCode: String
    
    func performDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [UTType.text]) {
            let itemProvider = info.itemProviders(for: [UTType.text]).first
            itemProvider?.loadObject(ofClass: NSString.self) { object, _ in
                if let code = object as? String {
                    let component = components.first { $0.code == code }
                    DispatchQueue.main.async {
                        if let component = component {
                            droppedComponents.append(component)
                            generatedCode = generateSwiftUICode(for: droppedComponents)
                        }
                    }
                }
            }
            return true
        }
        return false
    }
}

// MARK: - Modifier Control Panel
// MARK: - Modifier Control Panel
struct ModifierControlPanel: View {
    @Binding var selectedComponent: DraggableComponent
    @Binding var allComponents: [DraggableComponent] // Pass all components here
    @Binding var generatedCode: String
    
    var body: some View {
        VStack {
            Text("Modify: \(selectedComponent.name)").font(.headline)
            ForEach(modifiers, id: \.name) { modifier in
                if let value = modifier.value {
                    // Slider for numeric values like padding
                    HStack {
                        Text("\(modifier.name)")
                        Slider(value: Binding(
                            get: {
                                selectedComponent.modifiers.first(where: { $0.name == modifier.name })?.value ?? value
                            },
                            set: { newValue in
                                if let index = selectedComponent.modifiers.firstIndex(where: { $0.name == modifier.name }) {
                                    selectedComponent.modifiers[index].value = newValue
                                } else {
                                    var newModifier = modifier
                                    newModifier.value = newValue
                                    selectedComponent.modifiers.append(newModifier)
                                }
                                applyModifiers(for: selectedComponent, in: $allComponents, generatedCode: $generatedCode)
                            }
                        ), in: 0...50, step: 1)
                    }
                } else {
                    // Button for other properties like background color
                    Button(action: {
                        if selectedComponent.modifiers.contains(where: { $0.name == modifier.name }) {
                            selectedComponent.modifiers.removeAll(where: { $0.name == modifier.name })
                        } else {
                            selectedComponent.modifiers.append(modifier)
                        }
                        applyModifiers(for: selectedComponent, in: $allComponents, generatedCode: $generatedCode)
                    }) {
                        Text(modifier.name)
                            .padding(5)
                            .background(selectedComponent.modifiers.contains(where: { $0.name == modifier.name }) ? Color.green.opacity(0.5) : Color.gray.opacity(0.5))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Drop Area View
struct DropAreaView: View {
    @State private var droppedComponents: [DraggableComponent] = []
    @State private var selectedComponent: DraggableComponent? = nil
    @Binding var generatedCode: String
    
    // Define the size for the phone canvas
    let phoneWidth: CGFloat = 390 // iPhone 15 Pro width in points
    let phoneHeight: CGFloat = 844 // iPhone 15 Pro height in points
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geometry in
                VStack {
                    ZStack {
                        VStack {
                            ForEach($droppedComponents) { $component in
                                VStack {
                                    component.view
                                        .padding(10)
                                        .onTapGesture {
                                            selectedComponent = component // Select the component on tap
                                        }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: phoneWidth, height: phoneHeight)
                    .background(Color.white)
                    .clipShape(PhoneShape())
                    .border(Color.black, width: 1)
                    .onDrop(of: [UTType.text], delegate: CustomDropDelegate(
                        droppedComponents: $droppedComponents,
                        generatedCode: $generatedCode
                    ))
                }
                .frame(width: phoneWidth, height: phoneHeight)
            }
            
            // Safely unwrap selectedComponent and pass it as a binding
            if let selectedComponentBinding = Binding($selectedComponent) {
                ModifierControlPanel(
                    selectedComponent: selectedComponentBinding,
                    allComponents: $droppedComponents,
                    generatedCode: $generatedCode
                )
                .frame(width: 300)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
        }
    }
}


               // MARK: - Code Generation Function
               func generateSwiftUICode(for components: [DraggableComponent]) -> String {
                   var code = "VStack {\n"
                   for component in components {
                       code += "    \(component.code)"
                       for modifier in component.modifiers {
                           code += modifier.code(modifier.value)
                       }
                       code += "\n"
                   }
                   code += "}"
                   return code
               }

               // MARK: - Preview
               struct DesignEditor: View {
                   @State private var zoomLevel: CGFloat = 1.0 // Default 100% zoom
                   @State private var generatedCode: String = "VStack {\n    // Components will appear here\n}" // Initial root VStack
                   
                   var body: some View {
                       ZStack(alignment: .topLeading) {
                           // ScrollView for infinite scrolling
                           ScrollView([.horizontal, .vertical], showsIndicators: true) {
                               ZoomableCanvas(zoomLevel: $zoomLevel) {
                                   VStack {
                                       Spacer()
                                       
                                       // The phone canvas in the center
                                       DropAreaView(generatedCode: $generatedCode)
                                           .frame(width: 390, height: 844) // Phone dimensions
                                       
                                       Spacer()
                                   }
                                   .frame(maxWidth: .infinity, maxHeight: .infinity) // Large scrollable area
                               }
                               .frame(width: 2000, height: 2000) // Set a large scrollable canvas size to allow free movement
                               .background(Color.clear)
                           }
                           .defaultScrollAnchor(.center)
                           
                           // Component list in a fixed position on the top-left
                           VStack {
                               ComponentListView(components: components)
                                   .frame(width: 200) // Adjust width as needed
                                   .background(Color.gray.opacity(0.1))
                                   .cornerRadius(10)
                                   .padding()
                               
                               // Generated code section under the component list
                               VStack(alignment: .leading) {
                                   Text("Generated SwiftUI Code:")
                                       .font(.headline)
                                       .padding(.top)
                                   
                                   TextEditor(text: $generatedCode)
                                       .frame(height: 200) // Set height for the code view
                                       .border(Color.gray, width: 1)
                                       .padding()
                               }
                               .frame(width: 200) // Match width to component list
                               .background(Color.gray.opacity(0.1))
                               .cornerRadius(10)
                               .padding()
                               
                               Spacer() // Align list to the top
                           }
                           .frame(maxHeight: .infinity)
                       }
                       .padding()
                   }
               }

               // MARK: - Zoomable Canvas
               struct ZoomableCanvas<Content: View>: View {
                   @Binding var zoomLevel: CGFloat
                   var content: Content
                   
                   init(zoomLevel: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
                       self._zoomLevel = zoomLevel
                       self.content = content()
                   }
                   
                   var body: some View {
                       GeometryReader { geometry in
                           content
                               .scaleEffect(zoomLevel, anchor: .center) // Apply the selected zoom level
                               .frame(width: geometry.size.width, height: geometry.size.height) // Ensure full-size zoomable area
                               .contentShape(Rectangle()) // Allow gestures to be detected outside of the content area
                       }
                   }
               }

               // MARK: - Phone Shape
               struct PhoneShape: Shape {
                   func path(in rect: CGRect) -> Path {
                       var path = Path()
                       let cornerRadius: CGFloat = 30
                       let notchHeight: CGFloat = 30
                       
                       // Draw the phone outline
                       path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                       
                       // Draw the notch
                       let notchRect = CGRect(x: rect.midX - 30, y: rect.minY, width: 60, height: notchHeight)
                       path.addRoundedRect(in: notchRect, cornerSize: CGSize(width: 10, height: 10))
                       
                       return path
                   }
               }
struct ComponentListView: View {
    let components: [DraggableComponent]

    var body: some View {
        VStack {
            ForEach(components) { component in
                Text(component.name)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .onDrag {
                        NSItemProvider(object: component.code as NSString)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// Function to apply the modifiers and update the code
func applyModifiers(for selectedComponent: DraggableComponent, in components: Binding<[DraggableComponent]>, generatedCode: Binding<String>) {
    if let index = components.wrappedValue.firstIndex(where: { $0.id == selectedComponent.id }) {
        components.wrappedValue[index].view = selectedComponent.modifiers.reduce(AnyView(selectedComponent.view)) { view, modifier in
            return modifier.apply(view, modifier.value)
        }
        // After updating the selected component, regenerate code for all components
        generatedCode.wrappedValue = generateSwiftUICode(for: components.wrappedValue)
    }
}

