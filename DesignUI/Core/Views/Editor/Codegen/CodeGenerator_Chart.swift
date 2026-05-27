import SwiftUI

extension CodeGenerator {
    static func generateChartCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let config = chartConfig(component: component)
        let loopIndent = nextIndent + "    "
        let loopHeader = "\(nextIndent)ForEach(0..<\(config.pointCount), id: \\.self) { index in\n"
        let valueLogic = chartValueLogic(dataPreset: config.dataPreset, pointCount: config.pointCount, loopIndent: loopIndent)
        let loopFooter = "\(nextIndent)}"

        var lines: [String] = ["\(indent)Chart {"]
        lines.append(contentsOf: chartMarkLayers(config: config, loopHeader: loopHeader, loopFooter: loopFooter, loopIndent: loopIndent, valueLogic: valueLogic))
        lines.append("\(indent)}")
        lines.append(contentsOf: chartAxes(config: config, indent: indent, nextIndent: nextIndent))
        return lines.joined(separator: "\n")
    }

    private static func chartConfig(component: UIComponent) -> (style: String, dataPreset: String, pointCount: Int, colorCode: String, lineWidth: Double, showXAxis: Bool, showYAxis: Bool) {
        let style = component.getProperty(key: "chartStyle") as? String ?? "Line + Area"
        let dataPreset = component.getProperty(key: "dataPreset") as? String ?? "Increasing"
        let pointCount = Int(component.getProperty(key: "pointCount") as? Double ?? 20.0)
        let colorCode = chartColorCode(component: component)
        let showXAxis = component.getProperty(key: "showXAxis") as? Bool ?? true
        let showYAxis = component.getProperty(key: "showYAxis") as? Bool ?? true
        return (style, dataPreset, pointCount, colorCode, 5.0, showXAxis, showYAxis)
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
        var normalized = token
        if normalized.hasPrefix("color:") {
            normalized = String(normalized.dropFirst(6))
        }

        let parts = normalized.split(separator: ":")
        let rawName = parts.first.map(String.init) ?? "blue"
        let opacity = parts.count > 1 ? (Double(parts[1]) ?? 1.0) : 1.0
        let clampedOpacity = max(0, min(1, opacity))

        if rawName.hasPrefix("#") {
            let hex = String(rawName.dropFirst())
            return "Color(hex: \"\(hex)\").opacity(\(formatNumber(clampedOpacity)))"
        }

        switch rawName.lowercased() {
        case "primary":
            return "Color.primary.opacity(\(formatNumber(clampedOpacity)))"
        case "secondary":
            return "Color.secondary.opacity(\(formatNumber(clampedOpacity)))"
        case "clear":
            return "Color.clear.opacity(\(formatNumber(clampedOpacity)))"
        case "black":
            return "Color.black.opacity(\(formatNumber(clampedOpacity)))"
        case "white":
            return "Color.white.opacity(\(formatNumber(clampedOpacity)))"
        case "gray", "grey":
            return "Color.gray.opacity(\(formatNumber(clampedOpacity)))"
        case "red":
            return "Color.red.opacity(\(formatNumber(clampedOpacity)))"
        case "orange":
            return "Color.orange.opacity(\(formatNumber(clampedOpacity)))"
        case "yellow":
            return "Color.yellow.opacity(\(formatNumber(clampedOpacity)))"
        case "green":
            return "Color.green.opacity(\(formatNumber(clampedOpacity)))"
        case "mint":
            return "Color.mint.opacity(\(formatNumber(clampedOpacity)))"
        case "teal":
            return "Color.teal.opacity(\(formatNumber(clampedOpacity)))"
        case "cyan":
            return "Color.cyan.opacity(\(formatNumber(clampedOpacity)))"
        case "blue":
            return "Color.blue.opacity(\(formatNumber(clampedOpacity)))"
        case "indigo":
            return "Color.indigo.opacity(\(formatNumber(clampedOpacity)))"
        case "purple":
            return "Color.purple.opacity(\(formatNumber(clampedOpacity)))"
        case "pink":
            return "Color.pink.opacity(\(formatNumber(clampedOpacity)))"
        case "brown":
            return "Color.brown.opacity(\(formatNumber(clampedOpacity)))"
        default:
            return "Color.blue.opacity(\(formatNumber(clampedOpacity)))"
        }
    }

    private static func chartValueLogic(dataPreset: String, pointCount: Int, loopIndent: String) -> String {
        let denominator = Double(max(1, pointCount - 1))
        let noiseExpr = "12 * sin(Double(index) * 0.7) + 8 * sin(Double(index) * 0.23 + 1.5)"

        let valueLine: String
        switch dataPreset {
        case "Decreasing":
            valueLine = "\(loopIndent)let value = max(0, min(100, 90 - (progress * 80) + \(noiseExpr)))"
        case "Stable":
            valueLine = "\(loopIndent)let value = 50 + 5 * sin(Double(index) * 0.5)"
        case "Volatile":
            valueLine = "\(loopIndent)let value = 50 + 40 * sin(Double(index) * 1.7 + sin(Double(index) * 5.5))"
        default:
            valueLine = "\(loopIndent)let value = max(0, min(100, 10 + (progress * 80) + \(noiseExpr)))"
        }

        return [
            "\(loopIndent)let progress = Double(index) / \(denominator)",
            valueLine
        ].joined(separator: "\n") + "\n"
    }

    private static func chartMarkLayers(config: (style: String, dataPreset: String, pointCount: Int, colorCode: String, lineWidth: Double, showXAxis: Bool, showYAxis: Bool), loopHeader: String, loopFooter: String, loopIndent: String, valueLogic: String) -> [String] {
        var lines: [String] = []
        let normalizedStyle = normalizeChartStyle(config.style)

        if normalizedStyle == "area" || normalizedStyle == "line+area" {
            lines.append(chartAreaLayer(loopHeader: loopHeader, loopFooter: loopFooter, loopIndent: loopIndent, valueLogic: valueLogic, colorCode: config.colorCode))
        }

        if normalizedStyle == "line" || normalizedStyle == "line+area" {
            lines.append(chartLineLayer(loopHeader: loopHeader, loopFooter: loopFooter, loopIndent: loopIndent, valueLogic: valueLogic, colorCode: config.colorCode, lineWidth: config.lineWidth))
        }

        if normalizedStyle.contains("bar") {
            lines.append(
                chartBarLayer(
                    loopHeader: loopHeader,
                    loopFooter: loopFooter,
                    loopIndent: loopIndent,
                    valueLogic: valueLogic,
                    colorCode: config.colorCode,
                    pointCount: config.pointCount
                )
            )
        }

        return lines
    }

    private static func chartAreaLayer(loopHeader: String, loopFooter: String, loopIndent: String, valueLogic: String, colorCode: String) -> String {
        return """
\(loopHeader)\(valueLogic)\(loopIndent)AreaMark(
\(loopIndent)    x: .value("Index", index),
\(loopIndent)    y: .value("Value", value)
\(loopIndent))
\(loopIndent).interpolationMethod(.catmullRom)
\(loopIndent).foregroundStyle(\(colorCode).opacity(0.5))
\(loopFooter)
"""
    }

    private static func chartLineLayer(loopHeader: String, loopFooter: String, loopIndent: String, valueLogic: String, colorCode: String, lineWidth: Double) -> String {
        return """
\(loopHeader)\(valueLogic)\(loopIndent)LineMark(
\(loopIndent)    x: .value("Index", index),
\(loopIndent)    y: .value("Value", value)
\(loopIndent))
\(loopIndent).interpolationMethod(.catmullRom)
\(loopIndent).foregroundStyle(\(colorCode))
\(loopIndent).lineStyle(StrokeStyle(lineWidth: \(formatNumber(lineWidth))))
\(loopFooter)
"""
    }

    private static func chartBarLayer(loopHeader: String, loopFooter: String, loopIndent: String, valueLogic: String, colorCode: String, pointCount: Int) -> String {
        let widthRatio = barWidthRatio(for: pointCount)
        return """
\(loopHeader)\(valueLogic)\(loopIndent)BarMark(
\(loopIndent)    x: .value("Index", "\\(index + 1)"),
\(loopIndent)    y: .value("Value", value),
\(loopIndent)    width: .ratio(\(formatNumber(widthRatio)))
\(loopIndent))
\(loopIndent).foregroundStyle(\(colorCode))
\(loopIndent).cornerRadius(4)
\(loopFooter)
"""
    }

    private static func normalizeChartStyle(_ style: String) -> String {
        style
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    private static func barWidthRatio(for pointCount: Int) -> Double {
        switch max(1, pointCount) {
        case 1...4:
            return 0.94
        case 5...8:
            return 0.88
        case 9...14:
            return 0.80
        default:
            return 0.72
        }
    }

    private static func chartAxes(config: (style: String, dataPreset: String, pointCount: Int, colorCode: String, lineWidth: Double, showXAxis: Bool, showYAxis: Bool), indent: String, nextIndent: String) -> [String] {
        [xAxisCode(show: config.showXAxis, indent: indent, nextIndent: nextIndent),
         yAxisCode(show: config.showYAxis, indent: indent, nextIndent: nextIndent)]
    }

    private static func xAxisCode(show: Bool, indent: String, nextIndent: String) -> String {
        if show {
            return """
\(indent).chartXAxis {
\(nextIndent)AxisMarks(values: .automatic) { _ in
\(nextIndent)    AxisGridLine()
\(nextIndent)    AxisTick()
\(nextIndent)    AxisValueLabel()
\(nextIndent)}
\(indent)}
"""
        }
        return "\(indent).chartXAxis(.hidden)"
    }

    private static func yAxisCode(show: Bool, indent: String, nextIndent: String) -> String {
        if show {
            return """
\(indent).chartYAxis {
\(nextIndent)AxisMarks(position: .leading, values: .automatic) { _ in
\(nextIndent)    AxisGridLine()
\(nextIndent)    AxisTick()
\(nextIndent)    AxisValueLabel()
\(nextIndent)}
\(indent)}
"""
        }
        return "\(indent).chartYAxis(.hidden)"
    }
}
