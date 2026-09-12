import SwiftUI
import Charts

struct DesignChartView: View {
    let configuration: ChartConfiguration
    let mainColor: Color

    private var palette: [Color] {
        let colors: [Color] = [mainColor, .teal, .orange, .purple, .pink, .indigo, .mint, .brown]
        return configuration.groups.indices.map { colors[$0 % colors.count] }
    }

    var body: some View {
        Chart {
            ForEach(configuration.samples) { point in
                marks(for: point)
            }
            if configuration.showGoal && !configuration.isDonut {
                RuleMark(y: .value("Goal", configuration.goalValue))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(configuration.goalLabel).font(.caption2).foregroundStyle(.secondary)
                    }
            }
        }
        .chartForegroundStyleScale(domain: configuration.groups, range: palette)
        .chartXScale(range: .plotDimension(padding: 12))
        .chartLegend(configuration.showLegend && configuration.groups.count > 1 && configuration.style != "Sparkline" ? .visible : .hidden)
        .chartXAxis {
            if configuration.showXAxis && configuration.isBar {
                AxisMarks(values: configuration.labels) { _ in
                    if configuration.showGrid { AxisGridLine() }
                    AxisValueLabel()
                }
            } else if configuration.showXAxis {
                AxisMarks(values: Array(configuration.labels.indices)) { axis in
                    if configuration.showGrid { AxisGridLine() }
                    AxisValueLabel(anchor: .top) {
                        if let index = axis.as(Int.self), configuration.labels.indices.contains(index) {
                            Text(configuration.labels[index])
                        }
                    }
                }
            }
        }
        .chartYAxis {
            if configuration.showYAxis {
                AxisMarks(position: .leading) { axis in
                    if configuration.showGrid { AxisGridLine() }
                    AxisValueLabel {
                        if let value = axis.as(Double.self) {
                            Text(configuration.valuePrefix + value.formatted(.number.notation(.compactName)) + configuration.valueSuffix)
                        }
                    }
                }
            }
        }
    }

    @ChartContentBuilder
    private func marks(for point: ChartSample) -> some ChartContent {
        let index = configuration.labels.firstIndex(of: point.label) ?? 0
        let group = configuration.isDonut ? point.label : (point.series ?? "Value")
        if configuration.isDonut {
            SectorMark(angle: .value("Value", point.value), innerRadius: .ratio(0.65), angularInset: 2)
                .foregroundStyle(by: .value("Category", group))
                .opacity(point.highlighted == false ? 0.65 : 1)
                .cornerRadius(3)
        } else {
            if configuration.hasArea {
                AreaMark(x: .value("Index", index), y: .value("Value", point.value), stacking: .unstacked)
                    .interpolationMethod(.monotone)
                    .foregroundStyle(by: .value("Series", group))
                    .opacity(configuration.areaOpacity)
            }
            if configuration.hasLine {
                LineMark(x: .value("Index", index), y: .value("Value", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(by: .value("Series", group))
                    .lineStyle(StrokeStyle(lineWidth: configuration.lineWidth, lineCap: .round, lineJoin: .round))
            }
            if configuration.isBar {
                if configuration.style == "Stacked Bar" {
                    BarMark(x: .value("Category", point.label), y: .value("Value", point.value), width: .ratio(configuration.barWidthRatio))
                        .foregroundStyle(by: .value("Series", group))
                        .cornerRadius(3)
                } else {
                    BarMark(x: .value("Category", point.label), y: .value("Value", point.value), width: .ratio(configuration.barWidthRatio))
                        .foregroundStyle(by: .value("Series", group))
                        .position(by: .value("Series", group))
                        .cornerRadius(3)
                }
            }
            if point.highlighted == true {
                if configuration.isBar {
                    if configuration.style == "Stacked Bar" {
                        PointMark(x: .value("Category", point.label), y: .value("Value", configuration.stackedValue(for: point)))
                            .foregroundStyle(Color.primary)
                            .symbolSize(70)
                    } else {
                        PointMark(x: .value("Category", point.label), y: .value("Value", point.value))
                            .foregroundStyle(Color.primary)
                            .position(by: .value("Series", group))
                            .symbolSize(70)
                    }
                } else {
                    PointMark(x: .value("Index", index), y: .value("Value", point.value))
                        .foregroundStyle(Color.primary)
                        .symbolSize(70)
                }
            }
        }
    }
}

extension ComponentRenderer {
    func renderChart() -> some View {
        let modifier = component.modifiers.reversed().first { $0.type == .fill || $0.type == .foregroundColor || $0.type == .tint }
        let token = modifier?.properties["color"] as? String ?? "blue"
        let normalized = token.hasPrefix("color:") ? String(token.dropFirst(6)) : token
        return DesignChartView(configuration: ChartConfiguration(component: component), mainColor: ComponentProperty.colorStringToColor(normalized))
    }
}
