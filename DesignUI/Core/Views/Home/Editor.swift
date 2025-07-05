import SwiftUI
import UniformTypeIdentifiers

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
    let type: ComponentType
    
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
        .onDrag {
            NSItemProvider(object: type.rawValue as NSString)
        }
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
            HStack(alignment: .bottom, spacing: 1) {
                // Cellular bars
                HStack(alignment: .bottom, spacing: 1) {
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
    var onDropComponent: ((ComponentType, CGPoint) -> Void)? = nil
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // iPhone frame
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 320, height: 650)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.white)
                    )
                
                VStack(spacing: 0) {
                    // Status Bar and Dynamic Island INSIDE the device frame
                    ZStack {
                        // Status Bar
                        HStack {
                            // Time
                            Text(timeString)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                                .onReceive(timer) { _ in
                                    currentTime = Date()
                                }
                            Spacer()
                            // Status Icons
                            HStack(alignment: .bottom, spacing: 1) {
                                // Cellular
                                HStack(alignment: .bottom, spacing: 1) {
                                    ForEach(0..<4) { i in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(i < 3 ? Color.black : Color.black.opacity(0.3))
                                            .frame(width: 3, height: CGFloat(6 + (i * 2)))
                                    }
                                }
                                // WiFi
                                Image(systemName: "wifi")
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
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
                            .zIndex(1)
                            .offset(y: 10)
                    }
                    .frame(height: 40)
                    .padding(.top, 10)
                    // Content Area (between status bar and home indicator)
                    VStack(spacing: 0) {
                        // Render all children of rootComponent (which should be a VStack)
                        ForEach(component.children ?? []) { child in
                            ComponentRenderer(component: child)
                        }
                    }
                    .frame(width: 300, height: 590)
                    .clipped()
                    .background(Color.clear)
                    Spacer(minLength: 0)
                    // Home Indicator (iPhone line at the bottom)
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 120, height: 5)
                        Spacer()
                    }
                    .padding(.bottom, 18)
                }
                .frame(width: 320, height: 650)
            }
            .frame(width: 320, height: 650)
            .onDrop(of: [UTType.text], isTargeted: nil) { providers, location in
                if let provider = providers.first {
                    _ = provider.loadObject(ofClass: NSString.self) { (object, error) in
                        if let typeString = object as? String, let type = ComponentType(rawValue: typeString) {
                            // Convert drop location to local canvas coordinates
                            let local = CGPoint(x: location.x - (geo.size.width - 320)/2 - 10, y: location.y - (geo.size.height - 650)/2 - 10)
                            DispatchQueue.main.async {
                                onDropComponent?(type, local)
                            }
                        }
                    }
                    return true
                }
                return false
            }
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
    
    // Helper for sidebar items
    private let sidebarItems: [(icon: String, title: String, type: ComponentType)] = [
        ("textformat", "Text", .text),
        ("square.fill", "Rectangle", .rectangle),
        ("square.stack.3d.up.fill", "Z Stack", .zstack),
        ("square.stack.3d.forward.dottedline", "V Stack", .vstack),
        ("square.stack.3d.down.forward", "H Stack", .hstack)
        // Add more as needed
    ]
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ZStack(alignment: .center) {
                    Color.gray.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)
                    HStack(spacing: 0) {
                        // Left Sidebar
                        VStack(spacing: 0) {
                            TextField("Search components...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            ScrollView {
                                VStack(spacing: 0) {
                                    let filteredItems = sidebarItems.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
                                    ForEach(filteredItems, id: \.title) { item in
                                        ComponentItem(icon: item.icon, title: item.title, type: item.type)
                                    }
                                }
                            }
                        }
                        .frame(width: 250)
                        .background(Color.gray.opacity(0.1))
                        // Main Canvas (centered vertically)
                        VStack {
                            Spacer()
                            iPhoneCanvas(component: viewModel.rootComponent) { type, point in
                                let childCount = viewModel.rootComponent.children?.count ?? 0
                                let yPosition = CGFloat(20 + 60 * childCount)
                                let newComponent = UIComponent(
                                    type: type,
                                    position: CGPoint(x: 150, y: yPosition),
                                    size: CGSize(width: 100, height: 40),
                                    textContent: type == .text ? "Text" : nil, backgroundColor: type == .rectangle ? .blue : nil
                                )
                                DispatchQueue.main.async {
                                    viewModel.rootComponent.children?.append(newComponent)
                                }
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
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
}
