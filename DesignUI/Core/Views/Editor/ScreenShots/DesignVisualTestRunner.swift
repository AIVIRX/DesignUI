#if DESIGNUI_VISUAL_TEST && os(macOS)
import AppKit
import SwiftUI

/// An isolated executable build that uses the real editor renderer without starting app services.
@main
enum DesignVisualTestRunner {
    struct Fixture: Decodable {
        let name: String
        let source: String?
        let prompt: String
        let components: [UIComponent]
        let expectedTexts: [String]
        let primaryAction: String?
    }

    @MainActor static func main() throws {
        let args = CommandLine.arguments
        guard args.count == 3 else { fatalError("Usage: visual-runner FIXTURES_DIRECTORY OUTPUT_DIRECTORY") }
        let input = URL(fileURLWithPath: args[1], isDirectory: true)
        let output = URL(fileURLWithPath: args[2], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        _ = NSApplication.shared
        NSApplication.shared.setActivationPolicy(.prohibited)
        let fixtures = try FileManager.default.contentsOfDirectory(at: input, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        var reports: [[String: Any]] = []
        for url in fixtures {
            let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
            for size in [CGSize(width: 375, height: 812), CGSize(width: 430, height: 932)] {
                for scheme in [ColorScheme.light, .dark] {
                    var measurements: [DesignMeasuredNode] = []
                    let view = CanvasScreenshotView(components: fixture.components, deviceSize: size, colorScheme: scheme, statusBarVisible: true, statusBarTopSafeArea: true)
                        .frame(width: size.width, height: size.height)
                        .coordinateSpace(name: "design-quality-canvas")
                        .environment(\.designLayoutProbeEnabled, true)
                        .onPreferenceChange(DesignLayoutMeasurements.self) { measurements = $0 }
                    let host = NSHostingView(rootView: view)
                    host.frame = CGRect(origin: .zero, size: size)
                    let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                    window.contentView = host
                    for _ in 0..<5 {
                        host.layoutSubtreeIfNeeded()
                        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
                    }
                    // AppKit capture preserves Swift Charts' layer-backed rendering.
                    // Give the host a real display pass before caching its contents.
                    window.orderFrontRegardless()
                    host.layoutSubtreeIfNeeded()
                    host.displayIfNeeded()
                    guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("No bitmap for \(fixture.name)") }
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("No PNG for \(fixture.name)") }
                    let filename = "\(url.deletingPathExtension().lastPathComponent)-\(Int(size.width))-\(scheme == .light ? "light" : "dark").png"
                    try png.write(to: output.appendingPathComponent(filename))
                    let texts = measurements.filter { $0.type == "Text" }
                    let visibleTexts = texts.filter { $0.frame.intersects(CGRect(origin: .zero, size: size)) }
                    let missing = fixture.expectedTexts.filter { expected in !texts.contains { $0.text.localizedCaseInsensitiveContains(expected) } }
                    let clipped = texts.filter { $0.frame.minX < -1 || $0.frame.maxX > size.width + 1 || $0.frame.width < 1 || $0.frame.height < 1 }
                    let actionVisible = fixture.primaryAction.map { action in texts.contains { $0.text == action && CGRect(origin: .zero, size: size).contains($0.frame) } } ?? true
                    reports.append(["name": fixture.name, "source": fixture.source ?? "unknown", "image": filename, "renderer": "production macOS SwiftUI at phone viewport", "width": size.width, "height": size.height, "theme": scheme == .light ? "light" : "dark", "measuredNodes": measurements.count, "visibleTextCount": visibleTexts.count, "missingText": missing, "horizontalOverflow": clipped.map(\.text), "primaryActionVisible": actionVisible, "pass": !measurements.isEmpty && missing.isEmpty && clipped.isEmpty && actionVisible])
                    window.contentView = nil
                }
            }
        }
        try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("report.json"))
        print("Rendered \(reports.count) screens. Report: \(output.path)/report.json")
    }
}
#endif
