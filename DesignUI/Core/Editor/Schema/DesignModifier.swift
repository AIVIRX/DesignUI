import Foundation
import SwiftUI

// MARK: - Design Modifier
/// All supported SwiftUI modifiers with associated values
enum DesignModifier: Identifiable, Codable, Equatable {
    var id: String {
        switch self {
        case .frame(let id, _, _, _, _, _, _, _): return id
        case .padding(let id, _, _, _, _, _, _, _): return id
        case .background(let id, _): return id
        case .foregroundColor(let id, _): return id
        case .foregroundStyle(let id, _): return id
        case .font(let id, _, _, _, _): return id
        case .fontWeight(let id, _): return id
        case .bold(let id): return id
        case .italic(let id): return id
        case .underline(let id, _, _): return id
        case .strikethrough(let id, _, _): return id
        case .cornerRadius(let id, _): return id
        case .clipShape(let id, _): return id
        case .shadow(let id, _, _, _, _): return id
        case .opacity(let id, _): return id
        case .blur(let id, _, _): return id
        case .brightness(let id, _): return id
        case .contrast(let id, _): return id
        case .saturation(let id, _): return id
        case .grayscale(let id, _): return id
        case .colorInvert(let id): return id
        case .colorMultiply(let id, _): return id
        case .border(let id, _, _): return id
        case .overlay(let id, _): return id
        case .mask(let id, _): return id
        case .rotationEffect(let id, _, _): return id
        case .rotation3DEffect(let id, _, _, _, _, _): return id
        case .scaleEffect(let id, _, _, _): return id
        case .offset(let id, _, _): return id
        case .position(let id, _, _): return id
        case .ignoresSafeArea(let id, _, _): return id
        case .disabled(let id, _): return id
        case .hidden(let id): return id
        case .allowsHitTesting(let id, _): return id
        case .contentShape(let id, _): return id
        case .accessibilityLabel(let id, _): return id
        case .accessibilityHint(let id, _): return id
        case .accessibilityHidden(let id, _): return id
        case .accessibilityIdentifier(let id, _): return id
        case .animation(let id, _): return id
        case .transition(let id, _): return id
        case .zIndex(let id, _): return id
        case .layoutPriority(let id, _): return id
        case .aspectRatio(let id, _, _): return id
        case .fixedSize(let id, _, _): return id
        case .lineLimit(let id, _): return id
        case .lineSpacing(let id, _): return id
        case .multilineTextAlignment(let id, _): return id
        case .minimumScaleFactor(let id, _): return id
        case .truncationMode(let id, _): return id
        case .tint(let id, _): return id
        case .accentColor(let id, _): return id
        case .symbolRenderingMode(let id, _): return id
        case .imageScale(let id, _): return id
        case .buttonStyle(let id, _): return id
        case .textFieldStyle(let id, _): return id
        case .toggleStyle(let id, _): return id
        case .listStyle(let id, _): return id
        case .listRowBackground(let id, _): return id
        case .listRowInsets(let id, _, _, _, _): return id
        case .listRowSeparator(let id, _): return id
        case .navigationTitle(let id, _): return id
        case .navigationBarTitleDisplayMode(let id, _): return id
        case .toolbar(let id, _): return id
        case .sheet(let id, _, _): return id
        case .alert(let id, _, _): return id
        case .confirmationDialog(let id, _, _): return id
        case .onTapGesture(let id, _, _): return id
        case .onLongPressGesture(let id, _, _): return id
        }
    }
    
    // MARK: - Layout Modifiers
    case frame(
        id: String,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: String? = nil
    )
    case padding(
        id: String,
        all: CGFloat? = nil,
        horizontal: CGFloat? = nil,
        vertical: CGFloat? = nil,
        top: CGFloat? = nil,
        bottom: CGFloat? = nil,
        leading: CGFloat? = nil,
        trailing: CGFloat? = nil
    )
    
    // MARK: - Style Modifiers
    case background(id: String, style: BackgroundStyle)
    case foregroundColor(id: String, color: String)
    case foregroundStyle(id: String, style: ForegroundStyleValue)
    case font(id: String, style: String?, size: CGFloat?, weight: String?, design: String?)
    case fontWeight(id: String, weight: String)
    case bold(id: String)
    case italic(id: String)
    case underline(id: String, active: Bool = true, color: String? = nil)
    case strikethrough(id: String, active: Bool = true, color: String? = nil)
    case cornerRadius(id: String, radius: CGFloat)
    case clipShape(id: String, shape: ShapeType)
    
    // MARK: - Effects Modifiers
    case shadow(id: String, color: String?, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0)
    case opacity(id: String, value: Double)
    case blur(id: String, radius: CGFloat, opaque: Bool = false)
    case brightness(id: String, amount: Double)
    case contrast(id: String, amount: Double)
    case saturation(id: String, amount: Double)
    case grayscale(id: String, amount: Double)
    case colorInvert(id: String)
    case colorMultiply(id: String, color: String)
    
    // MARK: - Border & Overlay Modifiers
    case border(id: String, color: String, width: CGFloat = 1)
    case overlay(id: String, content: OverlayContent)
    case mask(id: String, shape: ShapeType)
    
    // MARK: - Transform Modifiers
    case rotationEffect(id: String, degrees: Double, anchor: String? = nil)
    case rotation3DEffect(id: String, degrees: Double, x: CGFloat = 0, y: CGFloat = 0, z: CGFloat = 1, perspective: CGFloat = 1)
    case scaleEffect(id: String, scale: CGFloat? = nil, x: CGFloat? = nil, y: CGFloat? = nil)
    case offset(id: String, x: CGFloat = 0, y: CGFloat = 0)
    case position(id: String, x: CGFloat, y: CGFloat)
    
    // MARK: - Safe Area Modifiers
    case ignoresSafeArea(id: String, edges: String? = nil, regions: String? = nil)
    
    // MARK: - Interaction Modifiers
    case disabled(id: String, value: Bool)
    case hidden(id: String)
    case allowsHitTesting(id: String, value: Bool)
    case contentShape(id: String, shape: ShapeType)
    
    // MARK: - Accessibility Modifiers
    case accessibilityLabel(id: String, label: String)
    case accessibilityHint(id: String, hint: String)
    case accessibilityHidden(id: String, hidden: Bool)
    case accessibilityIdentifier(id: String, identifier: String)
    
    // MARK: - Animation Modifiers
    case animation(id: String, config: AnimationConfig)
    case transition(id: String, config: TransitionConfig)
    
    // MARK: - Layout Priority Modifiers
    case zIndex(id: String, value: Double)
    case layoutPriority(id: String, value: Double)
    case aspectRatio(id: String, ratio: CGFloat?, contentMode: String?)
    case fixedSize(id: String, horizontal: Bool = true, vertical: Bool = true)
    
    // MARK: - Text Modifiers
    case lineLimit(id: String, limit: Int?)
    case lineSpacing(id: String, spacing: CGFloat)
    case multilineTextAlignment(id: String, alignment: String)
    case minimumScaleFactor(id: String, factor: CGFloat)
    case truncationMode(id: String, mode: String)
    
    // MARK: - Color & Symbol Modifiers
    case tint(id: String, color: String)
    case accentColor(id: String, color: String)
    case symbolRenderingMode(id: String, mode: String)
    case imageScale(id: String, scale: String)
    
    // MARK: - Style Modifiers
    case buttonStyle(id: String, style: String)
    case textFieldStyle(id: String, style: String)
    case toggleStyle(id: String, style: String)
    case listStyle(id: String, style: String)
    case listRowBackground(id: String, color: String?)
    case listRowInsets(id: String, top: CGFloat?, bottom: CGFloat?, leading: CGFloat?, trailing: CGFloat?)
    case listRowSeparator(id: String, visibility: String)
    
    // MARK: - Navigation Modifiers
    case navigationTitle(id: String, title: String)
    case navigationBarTitleDisplayMode(id: String, mode: String)
    case toolbar(id: String, content: ToolbarContent)
    
    // MARK: - Presentation Modifiers
    case sheet(id: String, isPresented: Bool, content: String?)
    case alert(id: String, title: String, isPresented: Bool)
    case confirmationDialog(id: String, title: String, isPresented: Bool)
    
    // MARK: - Gesture Modifiers
    case onTapGesture(id: String, count: Int = 1, action: DesignAction?)
    case onLongPressGesture(id: String, minimumDuration: Double = 0.5, action: DesignAction?)
    
    // MARK: - Modifier Category
    var category: ModifierCategory {
        switch self {
        case .frame, .padding, .ignoresSafeArea, .aspectRatio, .fixedSize:
            return .layout
        case .background, .foregroundColor, .foregroundStyle, .cornerRadius, .clipShape, .border, .overlay, .mask:
            return .style
        case .font, .fontWeight, .bold, .italic, .underline, .strikethrough, .lineLimit, .lineSpacing, .multilineTextAlignment, .minimumScaleFactor, .truncationMode:
            return .typography
        case .shadow, .opacity, .blur, .brightness, .contrast, .saturation, .grayscale, .colorInvert, .colorMultiply:
            return .effects
        case .rotationEffect, .rotation3DEffect, .scaleEffect, .offset, .position:
            return .transform
        case .disabled, .hidden, .allowsHitTesting, .contentShape, .onTapGesture, .onLongPressGesture:
            return .interaction
        case .accessibilityLabel, .accessibilityHint, .accessibilityHidden, .accessibilityIdentifier:
            return .accessibility
        case .animation, .transition:
            return .animation
        case .zIndex, .layoutPriority:
            return .layoutPriority
        case .tint, .accentColor, .symbolRenderingMode, .imageScale:
            return .appearance
        case .buttonStyle, .textFieldStyle, .toggleStyle, .listStyle, .listRowBackground, .listRowInsets, .listRowSeparator:
            return .componentStyle
        case .navigationTitle, .navigationBarTitleDisplayMode, .toolbar:
            return .navigation
        case .sheet, .alert, .confirmationDialog:
            return .presentation
        }
    }
    
    var displayName: String {
        switch self {
        case .frame: return "Frame"
        case .padding: return "Padding"
        case .background: return "Background"
        case .foregroundColor: return "Foreground Color"
        case .foregroundStyle: return "Foreground Style"
        case .font: return "Font"
        case .fontWeight: return "Font Weight"
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .cornerRadius: return "Corner Radius"
        case .clipShape: return "Clip Shape"
        case .shadow: return "Shadow"
        case .opacity: return "Opacity"
        case .blur: return "Blur"
        case .brightness: return "Brightness"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .grayscale: return "Grayscale"
        case .colorInvert: return "Color Invert"
        case .colorMultiply: return "Color Multiply"
        case .border: return "Border"
        case .overlay: return "Overlay"
        case .mask: return "Mask"
        case .rotationEffect: return "Rotation"
        case .rotation3DEffect: return "3D Rotation"
        case .scaleEffect: return "Scale"
        case .offset: return "Offset"
        case .position: return "Position"
        case .ignoresSafeArea: return "Ignores Safe Area"
        case .disabled: return "Disabled"
        case .hidden: return "Hidden"
        case .allowsHitTesting: return "Allows Hit Testing"
        case .contentShape: return "Content Shape"
        case .accessibilityLabel: return "Accessibility Label"
        case .accessibilityHint: return "Accessibility Hint"
        case .accessibilityHidden: return "Accessibility Hidden"
        case .accessibilityIdentifier: return "Accessibility Identifier"
        case .animation: return "Animation"
        case .transition: return "Transition"
        case .zIndex: return "Z-Index"
        case .layoutPriority: return "Layout Priority"
        case .aspectRatio: return "Aspect Ratio"
        case .fixedSize: return "Fixed Size"
        case .lineLimit: return "Line Limit"
        case .lineSpacing: return "Line Spacing"
        case .multilineTextAlignment: return "Multiline Alignment"
        case .minimumScaleFactor: return "Minimum Scale Factor"
        case .truncationMode: return "Truncation Mode"
        case .tint: return "Tint"
        case .accentColor: return "Accent Color"
        case .symbolRenderingMode: return "Symbol Rendering Mode"
        case .imageScale: return "Image Scale"
        case .buttonStyle: return "Button Style"
        case .textFieldStyle: return "TextField Style"
        case .toggleStyle: return "Toggle Style"
        case .listStyle: return "List Style"
        case .listRowBackground: return "List Row Background"
        case .listRowInsets: return "List Row Insets"
        case .listRowSeparator: return "List Row Separator"
        case .navigationTitle: return "Navigation Title"
        case .navigationBarTitleDisplayMode: return "Title Display Mode"
        case .toolbar: return "Toolbar"
        case .sheet: return "Sheet"
        case .alert: return "Alert"
        case .confirmationDialog: return "Confirmation Dialog"
        case .onTapGesture: return "On Tap Gesture"
        case .onLongPressGesture: return "On Long Press Gesture"
        }
    }
    
    var iconName: String {
        switch category {
        case .layout: return "rectangle.dashed"
        case .style: return "paintbrush.fill"
        case .typography: return "textformat.size"
        case .effects: return "sparkles"
        case .transform: return "arrow.up.left.and.arrow.down.right.circle"
        case .interaction: return "hand.tap"
        case .accessibility: return "accessibility"
        case .animation: return "wand.and.stars"
        case .layoutPriority: return "square.stack.3d.up"
        case .appearance: return "paintpalette"
        case .componentStyle: return "slider.horizontal.3"
        case .navigation: return "arrow.triangle.turn.up.right.diamond"
        case .presentation: return "rectangle.on.rectangle"
        }
    }
}

// MARK: - Modifier Category
enum ModifierCategory: String, Codable, CaseIterable {
    case layout = "Layout"
    case style = "Style"
    case typography = "Typography"
    case effects = "Effects"
    case transform = "Transform"
    case interaction = "Interaction"
    case accessibility = "Accessibility"
    case animation = "Animation"
    case layoutPriority = "Layout Priority"
    case appearance = "Appearance"
    case componentStyle = "Component Style"
    case navigation = "Navigation"
    case presentation = "Presentation"
}

// MARK: - Supporting Types
struct BackgroundStyle: Codable, Equatable {
    var color: String?
    var gradient: GradientConfig?
    var material: String?
    var ignoresSafeArea: Bool?
}

struct GradientConfig: Codable, Equatable {
    var type: String // "linear", "radial", "angular"
    var colors: [String]
    var startPoint: String?
    var endPoint: String?
    var center: String?
    var startRadius: CGFloat?
    var endRadius: CGFloat?
}

struct ForegroundStyleValue: Codable, Equatable {
    var style: String? // "primary", "secondary", "tertiary"
    var color: String?
    var gradient: GradientConfig?
}

enum ShapeType: Codable, Equatable {
    case circle
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat, style: String?)
    case capsule(style: String?)
    case ellipse
    
    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .rectangle: return "Rectangle"
        case .roundedRectangle: return "Rounded Rectangle"
        case .capsule: return "Capsule"
        case .ellipse: return "Ellipse"
        }
    }
}

struct OverlayContent: Codable, Equatable {
    var type: String // "color", "shape", "component"
    var color: String?
    var shape: ShapeType?
    var componentId: String?
    var strokeColor: String?
    var strokeWidth: CGFloat?
}

struct AnimationConfig: Codable, Equatable {
    var type: String // "default", "linear", "easeIn", "easeOut", "easeInOut", "spring", "bouncy", "smooth"
    var duration: Double?
    var delay: Double?
    var repeatCount: Int?
    var repeatForever: Bool?
    var autoreverses: Bool?
    var springResponse: Double?
    var springDampingFraction: Double?
    var springBlendDuration: Double?
}

struct TransitionConfig: Codable, Equatable {
    var type: String // "opacity", "scale", "slide", "move", "push", "asymmetric"
    var edge: String? // "top", "bottom", "leading", "trailing"
    var insertionType: String?
    var removalType: String?
}

struct ToolbarContent: Codable, Equatable {
    var placement: String // "automatic", "navigationBarLeading", "navigationBarTrailing", "bottomBar", "keyboard"
    var items: [ToolbarItem]
}

struct ToolbarItem: Codable, Equatable {
    var id: String
    var type: String // "button", "text", "image"
    var label: String?
    var systemImage: String?
    var action: DesignAction?
}

// MARK: - Modifier Factory
enum ModifierFactory {
    static func frame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: String? = nil
    ) -> DesignModifier {
        .frame(
            id: UUID().uuidString,
            width: width,
            height: height,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            alignment: alignment
        )
    }
    
    static func padding(_ all: CGFloat) -> DesignModifier {
        .padding(id: UUID().uuidString, all: all)
    }
    
    static func padding(horizontal: CGFloat? = nil, vertical: CGFloat? = nil) -> DesignModifier {
        .padding(id: UUID().uuidString, horizontal: horizontal, vertical: vertical)
    }
    
    static func padding(top: CGFloat? = nil, bottom: CGFloat? = nil, leading: CGFloat? = nil, trailing: CGFloat? = nil) -> DesignModifier {
        .padding(id: UUID().uuidString, top: top, bottom: bottom, leading: leading, trailing: trailing)
    }
    
    static func background(color: String) -> DesignModifier {
        .background(id: UUID().uuidString, style: BackgroundStyle(color: color))
    }
    
    static func background(gradient: GradientConfig) -> DesignModifier {
        .background(id: UUID().uuidString, style: BackgroundStyle(gradient: gradient))
    }
    
    static func foregroundColor(_ color: String) -> DesignModifier {
        .foregroundColor(id: UUID().uuidString, color: color)
    }
    
    static func font(style: String? = nil, size: CGFloat? = nil, weight: String? = nil, design: String? = nil) -> DesignModifier {
        .font(id: UUID().uuidString, style: style, size: size, weight: weight, design: design)
    }
    
    static func cornerRadius(_ radius: CGFloat) -> DesignModifier {
        .cornerRadius(id: UUID().uuidString, radius: radius)
    }
    
    static func shadow(color: String? = nil, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> DesignModifier {
        .shadow(id: UUID().uuidString, color: color, radius: radius, x: x, y: y)
    }
    
    static func opacity(_ value: Double) -> DesignModifier {
        .opacity(id: UUID().uuidString, value: value)
    }
    
    static func clipShape(_ shape: ShapeType) -> DesignModifier {
        .clipShape(id: UUID().uuidString, shape: shape)
    }
    
    static func offset(x: CGFloat = 0, y: CGFloat = 0) -> DesignModifier {
        .offset(id: UUID().uuidString, x: x, y: y)
    }
    
    static func rotationEffect(degrees: Double, anchor: String? = nil) -> DesignModifier {
        .rotationEffect(id: UUID().uuidString, degrees: degrees, anchor: anchor)
    }
    
    static func scaleEffect(_ scale: CGFloat) -> DesignModifier {
        .scaleEffect(id: UUID().uuidString, scale: scale)
    }
    
    static func border(color: String, width: CGFloat = 1) -> DesignModifier {
        .border(id: UUID().uuidString, color: color, width: width)
    }
}
