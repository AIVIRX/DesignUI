import SwiftUI

/// Editor-only feedback; never included in the component tree or exported artwork.
struct CanvasGenerationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var startedAt = Date()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.primary.opacity(reduceTransparency ? 0.12 : 0.035)
            if !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    GeometryReader { geometry in
                        let phase = timeline.date.timeIntervalSince(startedAt)
                            .truncatingRemainder(dividingBy: 2.4) / 2.4
                        LinearGradient(
                            colors: [.clear, .accentColor.opacity(0.08), .white.opacity(0.3), .accentColor.opacity(0.08), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.65)
                        .offset(x: geometry.size.width * (phase * 1.65 - 0.65))
                    }
                }
                .accessibilityHidden(true)
            }

            TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
                let seconds = max(0, Int(timeline.date.timeIntervalSince(startedAt)))
                HStack(spacing: 10) {
                    if reduceMotion {
                        Image(systemName: "sparkles")
                    } else {
                        ProgressView().controlSize(.small)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Generating your design")
                            .font(.subheadline.weight(.semibold))
                        Text(seconds >= 25 ? "Still working on your screen…" : "Your canvas will update when it’s ready.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Text("\(seconds)s")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding(20)
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("AI is generating your design")
    }
}
