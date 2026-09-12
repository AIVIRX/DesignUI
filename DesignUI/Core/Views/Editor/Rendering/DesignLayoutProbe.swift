import SwiftUI

struct DesignMeasuredNode: Equatable {
    let id: UUID
    let type: String
    let text: String
    let frame: CGRect
}

struct DesignLayoutMeasurements: PreferenceKey {
    static var defaultValue: [DesignMeasuredNode] = []
    static func reduce(value: inout [DesignMeasuredNode], nextValue: () -> [DesignMeasuredNode]) { value += nextValue() }
}

private struct DesignLayoutProbeEnabledKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var designLayoutProbeEnabled: Bool {
        get { self[DesignLayoutProbeEnabledKey.self] }
        set { self[DesignLayoutProbeEnabledKey.self] = newValue }
    }
}

struct DesignLayoutProbe: ViewModifier {
    let component: UIComponent
    @Environment(\.designLayoutProbeEnabled) private var enabled

    func body(content: Content) -> some View {
        content.background {
            if enabled && component.modifierId == nil {
                GeometryReader { geometry in
                    Color.clear.preference(key: DesignLayoutMeasurements.self, value: [DesignMeasuredNode(
                        id: component.id, type: component.type.rawValue,
                        text: component.getProperty(key: "text") as? String ?? "",
                        frame: geometry.frame(in: .named("design-quality-canvas"))
                    )])
                }
            }
        }
    }
}
