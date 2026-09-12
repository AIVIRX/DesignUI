import SwiftUI

struct ChartInspectorControls: View {
    @ObservedObject var component: UIComponent
    let canvasManager: CanvasManager
    @State private var draft: Draft?

    private struct Draft: Identifiable {
        let id = UUID()
        let component: UIComponent
        let samples: [ChartSample]
        let isDonut: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Edit chart data…") {
                let configuration = ChartConfiguration(component: component)
                draft = Draft(component: component, samples: configuration.samples, isDonut: configuration.isDonut)
            }
            .buttonStyle(.bordered)
            Toggle("Legend", isOn: boolean("showLegend", default: true))
            Toggle("Grid lines", isOn: boolean("showGrid", default: false))
            Toggle("Goal line", isOn: boolean("showGoal", default: false))
            if component.getProperty(key: "showGoal") as? Bool == true {
                numberField("Goal value", key: "goalValue", fallback: 75, range: -1e12...1e12)
                TextField("Goal label", text: string("goalLabel", default: "Goal"))
            }
            HStack {
                TextField("Prefix ($)", text: string("valuePrefix"))
                TextField("Unit (km)", text: string("valueSuffix"))
            }
            numberField("Line width", key: "lineWidth", fallback: 2.5, range: 1...8)
            numberField("Bar width", key: "barWidthRatio", fallback: 0.6, range: 0.2...0.95)
            numberField("Area opacity", key: "areaOpacity", fallback: 0.14, range: 0...1)
        }
        .font(.subheadline)
        .textFieldStyle(.roundedBorder)
        .sheet(item: $draft) { draft in
            ChartDataEditor(samples: draft.samples, isDonut: draft.isDonut) { samples in
                guard let data = try? JSONEncoder().encode(samples), let json = String(data: data, encoding: .utf8) else { return }
                canvasManager.updateComponentProperty(for: draft.component, key: "dataPoints", value: json)
            }
        }
    }

    private func boolean(_ key: String, default fallback: Bool) -> Binding<Bool> {
        Binding(get: { component.getProperty(key: key) as? Bool ?? fallback }, set: { canvasManager.updateComponentProperty(for: component, key: key, value: $0) })
    }
    private func string(_ key: String, default fallback: String = "") -> Binding<String> {
        Binding(get: { component.getProperty(key: key) as? String ?? fallback }, set: { canvasManager.updateComponentProperty(for: component, key: key, value: $0) })
    }
    private func numberField(_ title: String, key: String, fallback: Double, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: Binding(get: { component.getProperty(key: key) as? Double ?? fallback }, set: { value in
                guard value.isFinite else { return }
                canvasManager.updateComponentProperty(for: component, key: key, value: min(range.upperBound, max(range.lowerBound, value)))
            }), format: .number)
            .multilineTextAlignment(.trailing)
            .frame(width: 85)
        }
    }
}

struct ChartDataEditor: View {
    private struct Row: Identifiable {
        let id = UUID()
        var label: String
        var value: Double
        var series: String
        var highlighted: Bool
    }
    @Environment(\.dismiss) private var dismiss
    @State private var rows: [Row]
    let isDonut: Bool
    let onSave: ([ChartSample]) -> Void

    init(samples: [ChartSample], isDonut: Bool, onSave: @escaping ([ChartSample]) -> Void) {
        _rows = State(initialValue: samples.map { Row(label: $0.label, value: $0.value, series: $0.series ?? "", highlighted: $0.highlighted ?? false) })
        self.isDonut = isDonut
        self.onSave = onSave
    }

    private var samples: [ChartSample] {
        rows.map { row in
            let series = row.series.trimmingCharacters(in: .whitespacesAndNewlines)
            return ChartSample(label: row.label.trimmingCharacters(in: .whitespacesAndNewlines), value: row.value, series: series.isEmpty ? nil : series, highlighted: row.highlighted ? true : nil)
        }
    }
    private var isValid: Bool {
        !rows.isEmpty && rows.count <= 60 && samples.allSatisfy { !$0.label.isEmpty && $0.value.isFinite && abs($0.value) <= 1e12 }
            && Set(samples.map(\.id)).count == samples.count
            && (!isDonut || (samples.allSatisfy { $0.value >= 0 } && samples.contains { $0.value > 0 } && Set(samples.map(\.label)).count == samples.count))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit labels and values. Add a series name to compare groups; star a point to highlight it.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ForEach($rows) { $row in
                        VStack(spacing: 8) {
                            HStack {
                                TextField("Label", text: $row.label)
                                TextField("Value", value: $row.value, format: .number).frame(width: 90)
                                Button { row.highlighted.toggle() } label: {
                                    Image(systemName: row.highlighted ? "star.fill" : "star")
                                }.accessibilityLabel("Highlight \(row.label)")
                                Button(role: .destructive) { rows.removeAll { $0.id == row.id } } label: {
                                    Image(systemName: "minus.circle")
                                }.accessibilityLabel("Remove \(row.label)")
                            }
                            if !isDonut { TextField("Series (optional)", text: $row.series) }
                        }
                        .padding(12)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button("Add data point", systemImage: "plus") { rows.append(Row(label: "", value: 0, series: "", highlighted: false)) }
                        .disabled(rows.count >= 60)
                    if !isValid {
                        Text(isDonut ? "Use distinct labels, nonnegative values and a total above zero." : "Every point needs a label and numeric value. Label and series pairs must be unique.")
                            .font(.caption).foregroundStyle(.red)
                    }
                }.padding(20)
            }
            .textFieldStyle(.roundedBorder)
            .navigationTitle("Chart Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(samples); dismiss() }.disabled(!isValid) }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, idealWidth: 540, minHeight: 480, idealHeight: 640)
        #endif
    }
}
