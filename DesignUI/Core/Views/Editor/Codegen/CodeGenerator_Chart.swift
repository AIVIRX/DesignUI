import SwiftUI

extension CodeGenerator {
    private static func chartDataDeclarations(config: ChartConfiguration, component: UIComponent, indent: String, nextIndent: String) -> [String] {
        func strings(_ values: [String]) -> String { "[" + values.map { String(reflecting: $0) }.joined(separator: ", ") + "]" }
        let values = "[" + config.samples.map { String($0.value) }.joined(separator: ", ") + "]"
        let categories = strings(config.samples.map(\.label))
        let series = strings(config.samples.map { config.isDonut ? $0.label : ($0.series ?? "Value") })
        let positions = "[" + config.samples.map { String(config.labels.firstIndex(of: $0.label) ?? 0) }.joined(separator: ", ") + "]"
        let highlights = "[" + config.samples.map { $0.highlighted == true ? "true" : "false" }.joined(separator: ", ") + "]"
        let stackedValues = "[" + config.samples.map { String(config.stackedValue(for: $0)) }.joined(separator: ", ") + "]"
        let dimmed = "[" + config.samples.map { $0.highlighted == false ? "0.65" : "1.0" }.joined(separator: ", ") + "]"
        let palette = [chartColorCode(component: component), "Color.teal", "Color.orange", "Color.purple", "Color.pink", "Color.indigo", "Color.mint", "Color.brown"]
        let colors = "[" + config.groups.indices.map { palette[$0 % palette.count] }.joined(separator: ", ") + "]"
        var lines = [
            "\(indent)Group {",
            "\(nextIndent)let chartGroups: [String] = \(strings(config.groups))",
            "\(nextIndent)let chartColors: [Color] = \(colors)",
            "\(nextIndent)let chartValues: [Double] = \(values)",
            "\(nextIndent)let chartSeries: [String] = \(series)"
        ]
        if config.isBar { lines.append("\(nextIndent)let chartCategories: [String] = \(categories)") }
        if !config.isBar && !config.isDonut { lines.append("\(nextIndent)let chartPositions: [Int] = \(positions)") }
        if !config.isDonut && config.samples.contains(where: { $0.highlighted == true }) {
            lines.append("\(nextIndent)let chartHighlights: [Bool] = \(highlights)")
            if config.style == "Stacked Bar" { lines.append("\(nextIndent)let chartStackedValues: [Double] = \(stackedValues)") }
        }
        if config.isDonut { lines.append("\(nextIndent)let chartOpacities: [Double] = \(dimmed)") }
        return lines
    }

    static func generateChartCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let config = ChartConfiguration(component: component)
        let inner = nextIndent + "    "
        var lines = chartDataDeclarations(config: config, component: component, indent: indent, nextIndent: nextIndent)
        lines += ["\(indent)Chart {", "\(nextIndent)ForEach(0..<\(config.samples.count), id: \\.self) { index in"]
        lines += ["\(inner)let value: Double = chartValues[index]", "\(inner)let series: String = chartSeries[index]"]
        if config.isBar { lines.append("\(inner)let category = chartCategories[index]") }
        if !config.isBar && !config.isDonut { lines.append("\(inner)let x = chartPositions[index]") }
        let foreground = "\(inner)    .foregroundStyle(by: .value(\"Series\", series))"
        if config.isDonut {
            lines += ["\(inner)SectorMark(angle: .value(\"Value\", value), innerRadius: .ratio(0.65), angularInset: 2)", foreground, "\(inner)    .opacity(chartOpacities[index])", "\(inner)    .cornerRadius(3)"]
        } else {
            if config.hasArea {
                lines += ["\(inner)AreaMark(x: .value(\"Index\", x), y: .value(\"Value\", value), stacking: .unstacked)", "\(inner)    .interpolationMethod(.monotone)", foreground, "\(inner)    .opacity(\(config.areaOpacity))"]
            }
            if config.hasLine {
                lines += ["\(inner)LineMark(x: .value(\"Index\", x), y: .value(\"Value\", value))", "\(inner)    .interpolationMethod(.monotone)", foreground, "\(inner)    .lineStyle(StrokeStyle(lineWidth: \(config.lineWidth), lineCap: .round, lineJoin: .round))"]
            }
            if config.isBar {
                lines += ["\(inner)BarMark(x: .value(\"Category\", category), y: .value(\"Value\", value), width: .ratio(\(config.barWidthRatio)))", foreground]
                if config.style == "Bar" { lines.append("\(inner)    .position(by: .value(\"Series\", series))") }
                lines.append("\(inner)    .cornerRadius(3)")
            }
            if config.samples.contains(where: { $0.highlighted == true }) {
                let x = config.isBar ? ".value(\"Category\", category)" : ".value(\"Index\", x)"
                let y = config.style == "Stacked Bar" ? "chartStackedValues[index]" : "value"
                lines += ["\(inner)if chartHighlights[index] {", "\(inner)    PointMark(x: \(x), y: .value(\"Value\", \(y)))", "\(inner)        .foregroundStyle(Color.primary)"]
                if config.style == "Bar" { lines.append("\(inner)        .position(by: .value(\"Series\", series))") }
                lines += ["\(inner)        .symbolSize(70)", "\(inner)}"]
            }
        }
        lines.append("\(nextIndent)}")
        lines += chartDecorationCode(config: config, indent: indent, nextIndent: nextIndent)
        return lines.joined(separator: "\n")
    }

    private static func chartDecorationCode(config: ChartConfiguration, indent: String, nextIndent: String) -> [String] {
        let inner = nextIndent + "    "
        let escapedLabels: [String] = config.labels.map { String(reflecting: $0) }
        let labels = "[" + escapedLabels.joined(separator: ", ") + "]"
        var lines: [String] = []
        if config.showGoal && !config.isDonut {
            lines += ["\(nextIndent)RuleMark(y: .value(\"Goal\", \(config.goalValue)))", "\(nextIndent)    .foregroundStyle(Color.secondary)", "\(nextIndent)    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))", "\(nextIndent)    .annotation(position: .top, alignment: .trailing) { Text(\(String(reflecting: config.goalLabel))).font(.caption2).foregroundStyle(.secondary) }"]
        }
        lines.append("\(indent)}")
        lines.append("\(indent).chartForegroundStyleScale(domain: chartGroups, range: chartColors)")
        lines.append("\(indent).chartXScale(range: .plotDimension(padding: 12))")
        let legend = config.showLegend && config.groups.count > 1 && config.style != "Sparkline" ? ".visible" : ".hidden"
        lines.append("\(indent).chartLegend(\(legend))")
        if config.showXAxis {
            let axisValues = config.isBar ? labels : "Array(0..<\(config.labels.count))"
            lines += ["\(indent).chartXAxis {", "\(nextIndent)AxisMarks(values: \(axisValues)) { axis in"]
            if config.showGrid { lines.append("\(inner)AxisGridLine()") }
            if config.isBar { lines.append("\(inner)AxisValueLabel()") }
            else { lines += ["\(inner)AxisValueLabel(anchor: .top) {", "\(inner)    if let index = axis.as(Int.self), (0..<\(config.labels.count)).contains(index) { Text(\(labels)[index]) }", "\(inner)}"] }
            lines += ["\(nextIndent)}", "\(indent)}"]
        } else { lines.append("\(indent).chartXAxis(.hidden)") }
        if config.showYAxis {
            lines += ["\(indent).chartYAxis {", "\(nextIndent)AxisMarks(position: .leading) { axis in"]
            if config.showGrid { lines.append("\(inner)AxisGridLine()") }
            lines += ["\(inner)AxisValueLabel {", "\(inner)    if let value = axis.as(Double.self) { Text(\(String(reflecting: config.valuePrefix)) + value.formatted(.number.notation(.compactName)) + \(String(reflecting: config.valueSuffix))) }", "\(inner)}", "\(nextIndent)}", "\(indent)}"]
        } else { lines.append("\(indent).chartYAxis(.hidden)") }
        lines.append("\(indent)}")
        return lines
    }

    private static func chartColorCode(component: UIComponent) -> String {
        guard let token = chartColorToken(component: component) else {
            return "Color.blue"
        }

        return colorTokenToCode(token)
    }

    private static func chartColorToken(component: UIComponent) -> String? {
        guard let modifier = chartColorModifier(from: component.modifiers) else {
            return nil
        }
        return modifier.properties["color"] as? String
    }

    private static func chartColorModifier(from modifiers: [ComponentModifier]) -> ComponentModifier? {
        for modifier in modifiers.reversed() {
            if isChartColorModifier(modifier) {
                return modifier
            }
        }
        return nil
    }

    private static func isChartColorModifier(_ modifier: ComponentModifier) -> Bool {
        modifier.type == .fill || modifier.type == .foregroundColor || modifier.type == .tint
    }

    private static func colorTokenToCode(_ token: String) -> String {
        colorToString(token)
    }

    private static func normalizeChartStyle(_ style: String) -> String {
        style.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
    }
}
