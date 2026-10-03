import Foundation

struct ChartSample: Codable, Identifiable {
    var label: String
    var value: Double
    var series: String? = nil
    var highlighted: Bool? = nil
    var id: String { "\(series ?? "")\u{001F}\(label)" }
}

/// Shared by preview and Swift export so the same data is shown in both.
struct ChartConfiguration {
    let samples: [ChartSample]
    let lineWidth: Double
    let barWidthRatio: Double
    let areaOpacity: Double
    let showGrid: Bool
    let style: String
    let showLegend: Bool
    let showGoal: Bool
    let goalValue: Double
    let goalLabel: String
    let valuePrefix: String
    let valueSuffix: String
    let showXAxis: Bool
    let showYAxis: Bool
    var isDonut: Bool { style == "Donut" }
    var isBar: Bool { style == "Bar" || style == "Stacked Bar" }
    var hasLine: Bool { ["Line", "Line + Area", "Sparkline"].contains(style) }
    var hasArea: Bool { ["Area", "Line + Area"].contains(style) }
    var labels: [String] { samples.reduce(into: []) { if !$0.contains($1.label) { $0.append($1.label) } } }
    var groups: [String] { samples.reduce(into: []) { result, sample in
        let group = isDonut ? sample.label : (sample.series ?? "Value")
        if !result.contains(group) { result.append(group) }
    } }

    func stackedValue(for point: ChartSample) -> Double {
        var total = 0.0
        for sample in samples where sample.label == point.label && (sample.value >= 0) == (point.value >= 0) {
            total += sample.value
            if sample.id == point.id { break }
        }
        return total
    }

    init(component: UIComponent) {
        func number(_ key: String, fallback: Double, range: ClosedRange<Double>) -> Double {
            guard let value = component.getProperty(key: key) as? Double, value.isFinite else { return fallback }
            return min(range.upperBound, max(range.lowerBound, value))
        }
        lineWidth = number("lineWidth", fallback: 2.5, range: 1...8)
        barWidthRatio = number("barWidthRatio", fallback: 0.6, range: 0.2...0.95)
        areaOpacity = number("areaOpacity", fallback: 0.14, range: 0...1)
        showGrid = component.getProperty(key: "showGrid") as? Bool ?? false
        style = component.getProperty(key: "chartStyle") as? String ?? "Line + Area"
        showLegend = component.getProperty(key: "showLegend") as? Bool ?? true
        showGoal = component.getProperty(key: "showGoal") as? Bool ?? false
        goalValue = number("goalValue", fallback: 75, range: -1e12...1e12)
        goalLabel = component.getProperty(key: "goalLabel") as? String ?? "Goal"
        valuePrefix = component.getProperty(key: "valuePrefix") as? String ?? ""
        valueSuffix = component.getProperty(key: "valueSuffix") as? String ?? ""
        showXAxis = style != "Donut" && style != "Sparkline" && (component.getProperty(key: "showXAxis") as? Bool ?? true)
        showYAxis = style != "Donut" && style != "Sparkline" && (component.getProperty(key: "showYAxis") as? Bool ?? true)
        if let json = component.getProperty(key: "dataPoints") as? String,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ChartSample].self, from: data),
           !decoded.isEmpty, decoded.count <= 60,
           decoded.allSatisfy({ $0.value.isFinite && abs($0.value) <= 1e12 && !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }),
           Set(decoded.map(\.id)).count == decoded.count,
           (style != "Donut" || (decoded.allSatisfy({ $0.value >= 0 }) && decoded.contains(where: { $0.value > 0 }) && Set(decoded.map(\.label)).count == decoded.count)) {
            samples = decoded
        } else {
            let count = Int(number("pointCount", fallback: 20, range: 1...60))
            let preset = component.getProperty(key: "dataPreset") as? String ?? "Increasing"
            if preset == "Weekly Activity" {
                samples = zip(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], [42.0, 68, 51, 80, 63, 91, 72]).map { ChartSample(label: $0, value: $1) }
                return
            }
            if preset == "Spending" {
                samples = zip(["Housing", "Food", "Travel", "Shopping", "Other"], [1200.0, 420, 180, 260, 140]).map { ChartSample(label: $0, value: $1) }
                return
            }
            if preset == "Revenue" {
                samples = zip(["Jan", "Feb", "Mar", "Apr", "May", "Jun"], [8200.0, 9400, 8900, 11200, 12400, 14800]).map { ChartSample(label: $0, value: $1) }
                return
            }
            samples = (0..<count).map { index in
                let progress = Double(index) / Double(max(1, count - 1))
                let x = Double(index)
                let noise = 18 * sin(x * 0.9) + 10 * sin(x * 0.37 + 1.2) + 6 * sin(x * 0.17 + 2.4)
                let value: Double
                switch preset {
                case "Decreasing": value = 90 - progress * 80 + noise
                case "Stable": value = 50 + 4 * sin(x * 0.6) + 2 * sin(x * 0.19 + 1.1)
                case "Volatile": value = 50 + 30 * sin(x * 1.1) + 20 * sin(x * 2.3 + 0.7)
                default: value = 10 + progress * 80 + noise
                }
                return ChartSample(label: String(index + 1), value: max(0, min(100, value)))
            }
        }
    }
}
