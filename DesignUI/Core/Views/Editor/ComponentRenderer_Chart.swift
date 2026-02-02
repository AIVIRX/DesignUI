
import SwiftUI
import Charts

// Helper for Chart Data
private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

extension ComponentRenderer {
    
    /// Resolves a chart gradient color from getProperty: may be stored as String (color name) or Color (decoded).
    private func resolveChartColor(_ value: Any?, defaultName: String) -> Color {
        if let color = value as? Color { return color }
        let name = value as? String ?? defaultName
        return ComponentProperty.colorStringToColor(name)
    }
    
    @ViewBuilder
    func renderChart() -> some View {
        let style = component.getProperty(key: "chartStyle") as? String ?? "Line + Area"
        let dataPreset = component.getProperty(key: "dataPreset") as? String ?? "Increasing"
        let pointCount = Int(component.getProperty(key: "pointCount") as? Double ?? 20.0)
        let lineWidth = 5.0
        let showXAxis = component.getProperty(key: "showXAxis") as? Bool ?? true
        let showYAxis = component.getProperty(key: "showYAxis") as? Bool ?? true
        
        // Resolve color: property can be stored as String (from UI picker) or Color (from decode)
        let mainColor = resolveChartColor(component.getProperty(key: "color"), defaultName: "blue")
        
        // Generate data based on preset and count
        let data: [ChartDataPoint] = (0..<pointCount).map { i in
            let progress = Double(i) / Double(max(1, pointCount - 1))
            var value: Double = 50
            // Deterministic noise for random-looking curves (same formula, different phases)
            let noise = { (i: Int) in 12 * sin(Double(i) * 0.7) + 8 * sin(Double(i) * 0.23 + 1.5) }
            
            switch dataPreset {
            case "Decreasing":
                value = 90 - (progress * 80) + noise(i) // trend down with variation
            case "Stable":
                value = 50 + 5 * sin(Double(i) * 0.5)
            case "Volatile":
                value = 50 + 40 * sin(Double(i) * 1.7 + sin(Double(i) * 5.5))
            default: // Increasing
                value = 10 + (progress * 80) + noise(i) // trend up with variation
            }
            value = max(0, min(100, value))
            
            return ChartDataPoint(label: "\(i + 1)", value: value)
        }
        

        
        Chart {
            ForEach(data) { point in
                if style == "Line" || style == "Line + Area" {
                    LineMark(
                        x: .value("Index", Int(point.label) ?? 0), 
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(mainColor)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                }
                
                if style == "Area" || style == "Line + Area" {
                    AreaMark(
                        x: .value("Index", Int(point.label) ?? 0),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(mainColor.opacity(0.5))
                }
                
                if style == "Bar" {
                    BarMark(
                        x: .value("Index", Int(point.label) ?? 0),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(mainColor)
                    .cornerRadius(4)
                }
            }
        }
        .chartXAxis {
            if showXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    // Show every Nth label if dense? Charts does this automatically.
                    AxisValueLabel()
                }
            }
        }
        .chartYAxis {
            if showYAxis {
                AxisMarks(position: .leading, values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
    }
}
