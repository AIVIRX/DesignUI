
import SwiftUI

extension CodeGenerator {
    // MARK: - Chart Code Generation
    static func generateChartCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let style = component.getProperty(key: "chartStyle") as? String ?? "Line + Area"
        let dataPreset = component.getProperty(key: "dataPreset") as? String ?? "Increasing"
        let pointCount = Int(component.getProperty(key: "pointCount") as? Double ?? 20.0)
        let colorValue = component.getProperty(key: "color")
        let lineWidth = 5.0
        let showXAxis = component.getProperty(key: "showXAxis") as? Bool ?? true
        let showYAxis = component.getProperty(key: "showYAxis") as? Bool ?? true
        
        let colorCode = colorToString(colorValue)
        
        var code = "\(indent)Chart {\n"
        
        // Loop over 0..<pointCount
        let loopHeader = "\(nextIndent)ForEach(0..<\(pointCount), id: \\.self) { index in\n"
        let loopIndent = nextIndent + "    "
        
        // Generate value calculation logic (Increasing/Decreasing use trend + noise for random-looking curves)
        var valueLogic = "\(loopIndent)let progress = Double(index) / \(Double(max(1, pointCount - 1)))\n"
        let noiseExpr = "12 * sin(Double(index) * 0.7) + 8 * sin(Double(index) * 0.23 + 1.5)"
        switch dataPreset {
        case "Decreasing":
            valueLogic += "\(loopIndent)let value = max(0, min(100, 90 - (progress * 80) + \(noiseExpr)))\n"
        case "Stable":
            valueLogic += "\(loopIndent)let value = 50 + 5 * sin(Double(index) * 0.5)\n"
        case "Volatile":
            valueLogic += "\(loopIndent)let value = 50 + 40 * sin(Double(index) * 1.7 + sin(Double(index) * 5.5))\n"
        default: // Increasing
            valueLogic += "\(loopIndent)let value = max(0, min(100, 10 + (progress * 80) + \(noiseExpr)))\n"
        }
        
        // Area Layer
        if style == "Area" || style == "Line + Area" {
            code += loopHeader
            code += valueLogic
            code += "\(loopIndent)AreaMark(\n"
            code += "\(loopIndent)    x: .value(\"Index\", index),\n"
            code += "\(loopIndent)    y: .value(\"Value\", value)\n"
            code += "\(loopIndent))\n"
            code += "\(loopIndent).interpolationMethod(.catmullRom)\n"
            code += "\(loopIndent).foregroundStyle(\(colorCode).opacity(0.5))\n"
            code += "\(nextIndent)}\n\n"
        }
        
        // Line Layer
        if style == "Line" || style == "Line + Area" {
            code += loopHeader
            code += valueLogic
            code += "\(loopIndent)LineMark(\n"
            code += "\(loopIndent)    x: .value(\"Index\", index),\n"
            code += "\(loopIndent)    y: .value(\"Value\", value)\n"
            code += "\(loopIndent))\n"
            code += "\(loopIndent).interpolationMethod(.catmullRom)\n"
            code += "\(loopIndent).foregroundStyle(\(colorCode))\n"
            code += "\(loopIndent).lineStyle(StrokeStyle(lineWidth: \(formatNumber(lineWidth))))\n"
            code += "\(nextIndent)}\n"
        }
        
        if style == "Bar" {
             code += loopHeader
             code += valueLogic
             code += "\(loopIndent)BarMark(\n"
             code += "\(loopIndent)    x: .value(\"Index\", index),\n"
             code += "\(loopIndent)    y: .value(\"Value\", value)\n"
             code += "\(loopIndent))\n"
             code += "\(loopIndent).foregroundStyle(\(colorCode))\n"
             code += "\(loopIndent).cornerRadius(4)\n"
             code += "\(nextIndent)}\n"
        }

        code += "\(indent)}"
        
        // Axes
        if showXAxis {
            code += "\n\(indent).chartXAxis {\n"
            code += "\(nextIndent)AxisMarks(values: .automatic) { _ in\n"
            code += "\(nextIndent)    AxisGridLine()\n"
             code += "\(nextIndent)    AxisTick()\n"
            code += "\(nextIndent)    AxisValueLabel()\n"
            code += "\(nextIndent)}\n"
            code += "\(indent)}"
        } else {
             code += "\n\(indent).chartXAxis(.hidden)"
        }
        
        if showYAxis {
            code += "\n\(indent).chartYAxis {\n"
            code += "\(nextIndent)AxisMarks(position: .leading, values: .automatic) { _ in\n"
            code += "\(nextIndent)    AxisGridLine()\n"
             code += "\(nextIndent)    AxisTick()\n"
            code += "\(nextIndent)    AxisValueLabel()\n"
            code += "\(nextIndent)}\n"
            code += "\(indent)}"
        } else {
             code += "\n\(indent).chartYAxis(.hidden)"
        }
        
        return code
    }
}
