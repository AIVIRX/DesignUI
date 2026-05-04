import SwiftUI

struct AICommandBar: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var isGenerating: Bool
    var onGenerate: (String) async -> Void
    var selectedLabel: String?
    var quotaRemaining: Int
    var requiresSignIn: Bool = false
    @State private var prompt: String = ""
    
    private let maxCharacters = 600
    
    private var characterCount: Int {
        prompt.count
    }
    
    private var isOverLimit: Bool {
        characterCount > maxCharacters
    }

    private var canSend: Bool {
        !prompt.isEmpty && !isGenerating && !isOverLimit
    }
    
    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            HStack(spacing: 10) {
                promptField
                contextBadge
                sendButton
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect()
            .overlay(borderOverlay)
            .clipShape(Capsule(style: .continuous))
        } else {
            HStack(spacing: 10) {
                promptField
                contextBadge
                sendButton
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(barBackground)
            .overlay(borderOverlay)
            .clipShape(Capsule(style: .continuous))
        }
    }

    private var promptField: some View {
        HStack {
            TextField("Ask AI to perform edits...", text: $prompt)
                .textFieldStyle(.plain)
                .tint(.primary)
                .foregroundColor(.primary)
                .onChange(of: prompt) { _, newValue in
                    if newValue.count > maxCharacters {
                        prompt = String(newValue.prefix(maxCharacters))
                    }
                }
                .onSubmit { generate() }
        }
    }

    @ViewBuilder
    private var contextBadge: some View {
        if requiresSignIn {
            Text("Sign in")
                .font(.system(size: 11, weight: .semibold))
                .tint(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.red.opacity(0.14)))
        } else if let selectedLabel, !selectedLabel.isEmpty {
            Text(selectedLabel)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .tint(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.secondary.opacity(0.16)))
        } else {
            Text("\(quotaRemaining) left")
                .font(.system(size: 11, weight: .semibold))
                .tint(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.secondary.opacity(0.16)))
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        #if os(macOS)
        Button(action: generate) {
            if isGenerating {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 28, height: 28)
        .background(Circle().fill(prompt.isEmpty ? Color.gray : Color.blue))
        .clipShape(Circle())
        .buttonStyle(.plain)
        .disabled(!canSend)
        #else
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(action: generate) {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .tint(.primary)
                        .padding(5)
                }
            }
            .buttonStyle(.glass)
            .disabled(!canSend)
        } else {
            Button(action: generate) {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .tint(.primary)
                        .padding(6)
                        .background(Circle().fill(prompt.isEmpty ? Color.gray : Color.blue))
                }
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        #endif
    }

    @ViewBuilder
    private var barBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private var borderOverlay: some View {
        Group {
            if isOverLimit {
                Capsule(style: .continuous)
                    .stroke(Color.red.opacity(0.85), lineWidth: 1.6)
            }
        }
    }
    
    private func generate() {
        guard canSend else { return }
        
        isGenerating = true
        let currentPrompt = prompt
        prompt = ""
        
        Task {
            await onGenerate(currentPrompt)
        }
    }
}

struct RainbowGlowCapsuleBackground: View {
    var cornerRadius: CGFloat

    private var glowGradient: AngularGradient {
        AngularGradient(
            colors: [
                Color(red: 1.00, green: 0.28, blue: 0.45),
                Color(red: 1.00, green: 0.58, blue: 0.20),
                Color(red: 0.99, green: 0.83, blue: 0.28),
                Color(red: 0.42, green: 0.92, blue: 0.49),
                Color(red: 0.27, green: 0.78, blue: 1.00),
                Color(red: 0.52, green: 0.42, blue: 1.00),
                Color(red: 0.90, green: 0.33, blue: 1.00),
                Color(red: 1.00, green: 0.28, blue: 0.45)
            ],
            center: .center
        )
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.black.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(glowGradient, lineWidth: 1.3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(glowGradient, lineWidth: 4.5)
                    .blur(radius: 6)
                    .opacity(0.85)
            )
            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}
