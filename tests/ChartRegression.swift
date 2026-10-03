// Compile with the production ChartConfiguration, chart renderer and chart code generator.
// Lightweight editor stubs keep this test independent of auth and application services.
import SwiftUI
import AppKit

enum ModifierType { case fill, foregroundColor, tint }
struct ComponentModifier { var type: ModifierType; var properties: [String: Any] }
struct UIComponent {
    var properties: [String: Any]
    var modifiers: [ComponentModifier] = []
    func getProperty(key: String) -> Any? { properties[key] }
}
enum ComponentProperty {
    static func colorStringToColor(_ token: String) -> Color { .blue }
}
struct ComponentRenderer: View {
    let component: UIComponent
    var body: some View { renderChart() }
}
enum CodeGenerator {
    static func formatNumber(_ value: Double) -> String { String(value) }
}

@main
struct ChartRegression {
    @MainActor static func main() throws {
        let component = UIComponent(properties: [
            "chartStyle": "Bar",
            "dataPoints": "[{\"label\":\"Mon\",\"value\":42},{\"label\":\"Tue\",\"value\":68},{\"label\":\"Wed\",\"value\":51},{\"label\":\"Thu\",\"value\":80},{\"label\":\"Fri\",\"value\":63},{\"label\":\"Sat\",\"value\":91},{\"label\":\"Sun\",\"value\":72}]"
        ])
        let config = ChartConfiguration(component: component)
        precondition(config.samples.count == 7 && config.samples[1].label == "Tue" && config.samples[1].value == 68)
        precondition(config.barWidthRatio == 0.6 && config.lineWidth == 2.5 && !config.showGrid)
        let invalid = ChartConfiguration(component: UIComponent(properties: ["dataPoints": "bad", "pointCount": -99.0, "lineWidth": Double.infinity]))
        precondition(invalid.samples.count == 1 && invalid.lineWidth == 2.5)
        let legacy = ChartConfiguration(component: UIComponent(properties: ["pointCount": 7.0, "dataPreset": "Stable"]))
        precondition(legacy.samples.count == 7 && legacy.samples.allSatisfy { $0.value >= 0 && $0.value <= 100 })
        let code = CodeGenerator.generateChartCode(component: component, indent: "", nextIndent: "    ")
        precondition(code.contains("68.0") && code.contains("\"Tue\"") && code.contains(".ratio(0.6)"))
        precondition(!code.contains("AxisGridLine"))
        let comparison = "[{\"label\":\"Jan\",\"value\":42,\"series\":\"Online\"},{\"label\":\"Jan\",\"value\":20,\"series\":\"Retail\"},{\"label\":\"Feb\",\"value\":65,\"series\":\"Online\",\"highlighted\":true},{\"label\":\"Feb\",\"value\":30,\"series\":\"Retail\"}]"
        var exportSource = "import SwiftUI\nimport Charts\n"
        for (index, style) in ["Line + Area", "Line", "Area", "Bar", "Stacked Bar", "Donut", "Sparkline"].enumerated() {
            let sample = UIComponent(properties: ["chartStyle": style, "dataPoints": style == "Donut" ? component.properties["dataPoints"]! : comparison, "showGoal": true, "goalValue": 100.0, "showLegend": true, "valuePrefix": "$", "valueSuffix": "k"])
            let settings = ChartConfiguration(component: sample)
            precondition(settings.samples.count == (style == "Donut" ? 7 : 4))
            if style == "Sparkline" { precondition(!settings.showXAxis && !settings.showYAxis) }
            let source = CodeGenerator.generateChartCode(component: sample, indent: "", nextIndent: "    ")
            if style == "Donut" { precondition(source.contains("SectorMark") && !source.contains("RuleMark")) }
            if style == "Stacked Bar" { precondition(settings.stackedValue(for: settings.samples[1]) == 62) }
            exportSource += "struct ExportedChart\(index): View { var body: some View {\n\(source)\n} }\n"
        }
        try exportSource.write(toFile: "/tmp/designui-chart-export.swift", atomically: true, encoding: .utf8)
        let renderer = ImageRenderer(content: ComponentRenderer(component: component).frame(width: 340, height: 190).padding(24).background(.white).environment(\.colorScheme, .light))
        renderer.scale = 2
        if let image = renderer.cgImage,
           let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
            let bitmap = NSBitmapImageRep(cgImage: image)
            var blueSamples = 0
            for x in stride(from: 0, to: bitmap.pixelsWide, by: 8) {
                for y in stride(from: 0, to: bitmap.pixelsHigh, by: 8) {
                    if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB), color.blueComponent > 0.7 && color.redComponent < 0.2 { blueSamples += 1 }
                }
            }
            precondition(blueSamples > 100, "Chart axes rendered but bar marks are missing")
            try png.write(to: URL(fileURLWithPath: "/tmp/designui-chart-regression.png"))
        } else { fatalError("Chart did not render") }
        let overlay = ImageRenderer(content: Color.white.overlay { CanvasGenerationOverlay() }.frame(width: 390, height: 844).environment(\.colorScheme, .light))
        overlay.scale = 1
        if let image = overlay.cgImage, let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
            try png.write(to: URL(fileURLWithPath: "/tmp/designui-generation-overlay.png"))
        } else { fatalError("Generation overlay did not render") }
        print("Chart data, legacy defaults, export parity and rendering checks passed")
    }
}
