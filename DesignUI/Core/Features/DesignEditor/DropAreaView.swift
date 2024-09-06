import SwiftUI
import UniformTypeIdentifiers

struct DraggableComponent: Identifiable {
    let id = UUID()
    let name: String
    let view: AnyView
    let code: String
}

let components: [DraggableComponent] = [
    DraggableComponent(name: "Button", view: AnyView(Button("Click Me") {}), code: "Button(\"Click Me\")"),
    DraggableComponent(name: "Text", view: AnyView(Text("Hello, World!").foregroundStyle(Color.black)), code: "Text(\"Hello, World!\")")
]


struct CustomDropDelegate: DropDelegate {
    @Binding var droppedComponents: [DraggableComponent]
    @Binding var dragLocation: CGPoint
    
    func performDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [UTType.text]) {
            let itemProvider = info.itemProviders(for: [UTType.text]).first
            itemProvider?.loadObject(ofClass: NSString.self) { object, _ in
                if let code = object as? String {
                    let component = components.first { $0.code == code }
                    DispatchQueue.main.async {
                        if let component = component {
                            droppedComponents.append(component)
                        }
                    }
                }
            }
            return true
        }
        return false
    }
    
    func dropEntered(info: DropInfo) {
        // Update dragLocation here if needed for visual feedback
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Update dragLocation here for visual feedback
        dragLocation = info.location
        return DropProposal(operation: .copy)
    }
    
    func dropExited(info: DropInfo) {
        // Optionally, handle when the drag exits the drop target
        dragLocation = .zero
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

struct DropAreaView: View {
    @State private var droppedComponents: [DraggableComponent] = []
    @State private var dragLocation: CGPoint = .zero
    
    // Define the size for the phone canvas
    let phoneWidth: CGFloat = 390 // iPhone 15 Pro width in points
    let phoneHeight: CGFloat = 844 // iPhone 15 Pro height in points
    
    var body: some View {
        VStack {
            // Phone canvas content
            ForEach(droppedComponents) { component in
                component.view
                    .position(x: dragLocation.x, y: dragLocation.y) // Position based on drag location
            }
        }
        .frame(width: phoneWidth, height: phoneHeight) // Frame for phone dimensions
        .background(Color.white)
        .clipShape(PhoneShape()) // Keep phone shape
        .border(Color.black, width: 1)
        .onDrop(of: [UTType.text], delegate: CustomDropDelegate(droppedComponents: $droppedComponents, dragLocation: $dragLocation))
    }
}

struct DesignEditor: View {
    @State private var zoomLevel: CGFloat = 1.0 // Default 100% zoom
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // ScrollView for infinite scrolling
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZoomableCanvas(zoomLevel: $zoomLevel) {
                    VStack {
                        Spacer()
                        
                        // The phone canvas in the center
                        DropAreaView()
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
                Spacer() // Align list to the top
            }
            .frame(maxHeight: .infinity)
            
            // Zoom level dropdown on the top-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button("200%", action: { zoomLevel = 2.0 })
                        Button("150%", action: { zoomLevel = 1.5 })
                        Button("125%", action: { zoomLevel = 1.25 })
                        Button("100%", action: { zoomLevel = 1.0 })
                        Button("75%", action: { zoomLevel = 0.75 })
                        Button("50%", action: { zoomLevel = 0.5 })
                    } label: {
                        Text("Zoom Level")
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
            }
        }
        .padding()
    }
}
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
