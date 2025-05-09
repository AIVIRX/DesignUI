import SwiftUI

// MARK: - Core Models
struct UIComponent: Identifiable, Codable {
    let id: String
    let type: ComponentType
    var position: CGPoint
    var size: CGSize
    var children: [UIComponent]?
    var textContent: String?
    var backgroundColor: Color?
    var foregroundColor: Color?
    var padding: CGFloat?
    
    init(
        id: String = UUID().uuidString,
        type: ComponentType,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        children: [UIComponent]? = nil,
        textContent: String? = nil,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        padding: CGFloat? = nil
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        self.children = children
        self.textContent = textContent
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.padding = padding
    }
}

enum ComponentType: String, Codable {
    case text
    case rectangle
    case vstack
    case hstack
    case zstack
}

// MARK: - Color Codable Extension
extension Color: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("default", forKey: .colorSpace)
    }
    
    public init(from decoder: Decoder) throws {
        self = .blue // Default color for demo
    }
    
    private enum CodingKeys: String, CodingKey {
        case colorSpace
    }
}

// MARK: - CGPoint and CGSize Codable Extensions
extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

extension CGSize: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
}

// MARK: - Component Renderer
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
            Text(component.textContent ?? "")
                .foregroundColor(component.foregroundColor)
                .padding(component.padding ?? 0)
        case .rectangle:
            Rectangle()
                .fill(component.backgroundColor ?? .clear)
                .padding(component.padding ?? 0)
        case .vstack:
            VStack {
                ForEach(component.children ?? []) { child in
                    ComponentRenderer(component: child)
                }
            }
            .padding(component.padding ?? 0)
            .background(component.backgroundColor)
        case .hstack:
            HStack {
                ForEach(component.children ?? []) { child in
                    ComponentRenderer(component: child)
                }
            }
            .padding(component.padding ?? 0)
            .background(component.backgroundColor)
        case .zstack:
            ZStack {
                ForEach(component.children ?? []) { child in
                    ComponentRenderer(component: child)
                }
            }
            .padding(component.padding ?? 0)
            .background(component.backgroundColor)
        }
    }
}

// MARK: - Editor View Model
class EditorViewModel: ObservableObject {
    @Published var rootComponent: UIComponent
    
    init() {
        // Empty VStack as root to start with
        self.rootComponent = UIComponent(
            type: .vstack,
            position: CGPoint(x: 150, y: 315), // Centered in iPhone frame
            size: CGSize(width: 300, height: 630), // iPhone frame size
            children: [],
            backgroundColor: .clear,
            padding: 0
        )
    }
    
    func saveToJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(rootComponent)
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - Component Sidebar Item
struct ComponentItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Status Bar
struct StatusBarView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // Time
            Text(timeString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Right side status icons
            HStack(spacing: 4) {
                // Cellular bars
                HStack(spacing: 1) {
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < 3 ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 3, height: CGFloat(6 + (i * 2)))
                    }
                }
                
                // WiFi
                Image(systemName: "wifi")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                // Battery
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: 20, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white)
                                .padding(2)
                        )
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 6)
                }
            }
        }
        .frame(width: 280) // Constrain width to fit inside canvas
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
}

// MARK: - Dynamic Island
struct DynamicIslandView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black)
            .frame(width: 120, height: 35)
            .overlay(
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            )
    }
}

// MARK: - iPhone Canvas
struct iPhoneCanvas: View {
    let component: UIComponent
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // iPhone frame
            RoundedRectangle(cornerRadius: 40)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 320, height: 650)
            
            // Status Bar and Dynamic Island
            ZStack {
                // Status Bar
                HStack {
                    // Time
                    Text(timeString)
                        .font(.system(size: 12, weight: .medium))
                    
                    Spacer()
                    
                    // Status Icons
                    HStack(spacing: 4) {
                        // Cellular
                        HStack(spacing: 1) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(i < 3 ? Color.black : Color.black.opacity(0.3))
                                    .frame(width: 3, height: CGFloat(6 + (i * 2)))
                            }
                        }
                        
                        // WiFi
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                        
                        // Battery
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black, lineWidth: 1)
                                .frame(width: 20, height: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.black)
                                        .padding(2)
                                )
                            
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 2, height: 6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Dynamic Island
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(width: 120, height: 35)
                    .overlay(
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                        }
                    )
                    .zIndex(1) // Ensure Dynamic Island appears above status bar
            }
            .position(x: 320/2, y: 20)
            
            // Content
            ComponentRenderer(component: component)
                .frame(width: 300, height: 630)
                .padding(.top, 50)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
}

// MARK: - Main Editor View
struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var showJSON = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left Sidebar
                VStack(spacing: 0) {
                    // Search bar
                    TextField("Search components...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    // Components list
                    ScrollView {
                        VStack(spacing: 0) {
                            ComponentItem(icon: "textformat", title: "Text")
                            ComponentItem(icon: "photo", title: "Image")
                            ComponentItem(icon: "square.fill", title: "Rectangle")
                            ComponentItem(icon: "square.stack.3d.up.fill", title: "Z Stack")
                            ComponentItem(icon: "square.stack.3d.forward.dottedline", title: "V Stack")
                            ComponentItem(icon: "square.stack.3d.down.forward", title: "H Stack")
                            ComponentItem(icon: "slider.horizontal.3", title: "Slider")
                            ComponentItem(icon: "switch.2", title: "Switch")
                            ComponentItem(icon: "button.programmable", title: "Button")
                            ComponentItem(icon: "textfield", title: "Text Field")
                            ComponentItem(icon: "picker", title: "Picker")
                        }
                    }
                }
                .frame(width: 250)
                .background(Color.gray.opacity(0.1))
                
                // Main Canvas
                ZStack {
                    // Background
                    Color.gray.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)
                    
                    // iPhone Canvas
                    iPhoneCanvas(component: viewModel.rootComponent)
                }
                
                // Right Sidebar (Properties)
                VStack {
                    Text("Properties")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                }
                .frame(width: 250)
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("Layout Editor")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Show JSON") {
                        showJSON.toggle()
                    }
                }
            }
            .sheet(isPresented: $showJSON) {
                if let jsonString = try? viewModel.saveToJSON() {
                    ScrollView {
                        Text(jsonString)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EditorView()
} 
