
import SwiftUI
import Charts

// Helper for Chart Data
private struct ChartDataPoint: Identifiable {
    let id: Int
    let value: Double
}

private struct ComponentChartView: View {
    let data: [ChartDataPoint]
    let showsLine: Bool
    let showsArea: Bool
    let showsBar: Bool
    let lineWidth: Double
    let showXAxis: Bool
    let showYAxis: Bool
    let mainColor: Color

    private func barWidthRatio(for count: Int) -> MarkDimension {
        switch max(1, count) {
        case 1...4:
            return .ratio(0.94)
        case 5...8:
            return .ratio(0.88)
        case 9...14:
            return .ratio(0.80)
        default:
            return .ratio(0.72)
        }
    }

    var body: some View {
        Chart {
            ForEach(data) { point in
                if showsLine {
                    LineMark(
                        x: .value("Index", point.id),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(mainColor)
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                }

                if showsArea {
                    AreaMark(
                        x: .value("Index", point.id),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(mainColor.opacity(0.5))
                }

                if showsBar {
                    BarMark(
                        x: .value("Index", "\(point.id + 1)"),
                        y: .value("Value", point.value),
                        width: barWidthRatio(for: data.count)
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

extension ComponentRenderer {

    /// Resolve chart color from fill-style modifiers so charts follow the fills workflow.
    private func resolveChartColorFromFills(defaultName: String = "blue") -> Color {
        let candidate = component.modifiers
            .reversed()
            .first { modifier in
                modifier.type == .fill || modifier.type == .foregroundColor || modifier.type == .tint
            }

        if let token = candidate?.properties["color"] as? String {
            let normalized = token.hasPrefix("color:") ? String(token.dropFirst(6)) : token
            return ComponentProperty.colorStringToColor(normalized)
        }

        return ComponentProperty.colorStringToColor(defaultName)
    }
    
    @ViewBuilder
    func renderChart() -> some View {
        let style = component.getProperty(key: "chartStyle") as? String ?? "Line + Area"
        let normalizedStyle = style
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        let dataPreset = component.getProperty(key: "dataPreset") as? String ?? "Increasing"
        let pointCount = Int(component.getProperty(key: "pointCount") as? Double ?? 20.0)
        let lineWidth = 5.0
        let showXAxis = component.getProperty(key: "showXAxis") as? Bool ?? true
        let showYAxis = component.getProperty(key: "showYAxis") as? Bool ?? true
        let showsLine = normalizedStyle == "line" || normalizedStyle == "line+area"
        let showsArea = normalizedStyle == "area" || normalizedStyle == "line+area"
        let showsBar = normalizedStyle.contains("bar")

        let mainColor = resolveChartColorFromFills()
        let data = buildChartData(preset: dataPreset, count: pointCount)
        ComponentChartView(
            data: data,
            showsLine: showsLine,
            showsArea: showsArea,
            showsBar: showsBar,
            lineWidth: lineWidth,
            showXAxis: showXAxis,
            showYAxis: showYAxis,
            mainColor: mainColor
        )
    }

    private func buildChartData(preset: String, count: Int) -> [ChartDataPoint] {
        (0..<count).map { i in
            let progress = Double(i) / Double(max(1, count - 1))
            let value = chartValue(for: preset, index: i, progress: progress)
            return ChartDataPoint(id: i, value: value)
        }
    }

    private func chartValue(for preset: String, index: Int, progress: Double) -> Double {
        let value: Double

        switch preset {
        case "Decreasing":
            value = 90 - (progress * 80) + volatility(for: index)
        case "Stable":
            value = 50 + 4 * sin(Double(index) * 0.6) + 2 * sin(Double(index) * 0.19 + 1.1)
        case "Volatile":
            value = 50 + 30 * sin(Double(index) * 1.1) + 20 * sin(Double(index) * 2.3 + 0.7)
        default:
            value = 10 + (progress * 80) + volatility(for: index)
        }

        return max(0, min(100, value))
    }

    private func volatility(for index: Int) -> Double {
        18 * sin(Double(index) * 0.9)
        + 10 * sin(Double(index) * 0.37 + 1.2)
        + 6 * sin(Double(index) * 0.17 + 2.4)
    }
}
