//
//  LargeHero.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/8/25.
//

import SwiftUI

// MARK: - Stretchy Header Effect
extension View {
    /// Makes the view stretch when the user overscrolls.
    func stretchy() -> some View {
        self.visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)
            let newHeight = currentHeight + positiveOffset
            let scaleFactor = newHeight / currentHeight
            
            return effect.scaleEffect(
                x: scaleFactor,
                y: scaleFactor,
                anchor: .bottom
            )
        }
    }
}

enum MeshGradientTheme: String, CaseIterable {
    case ocean
    case sunset
    case aurora
    case lavender
    case forest
    case ember
    
    var colors: [Color] {
        switch self {
        case .ocean:
            // 4x4 grid = 16 colors
            return [
                .cyan, .blue, .cyan, .mint,
                .blue, .cyan, .mint, .cyan,
                .mint, .blue, .cyan, .blue,
                .cyan, .mint, .blue, .cyan
            ]
        case .sunset:
            return [
                .orange, .pink, .orange, .yellow,
                .pink, .orange, .yellow, .pink,
                .yellow, .pink, .orange, .pink,
                .orange, .yellow, .pink, .orange
            ]
        case .aurora:
            return [
                .green, .mint, .green, .cyan,
                .mint, .green, .cyan, .mint,
                .cyan, .mint, .green, .mint,
                .green, .cyan, .mint, .green
            ]
        case .lavender:
            return [
                .purple, .indigo, .purple, .pink,
                .indigo, .purple, .pink, .indigo,
                .pink, .indigo, .purple, .indigo,
                .purple, .pink, .indigo, .purple
            ]
        case .forest:
            return [
                Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.15, green: 0.4, blue: 0.25), Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.25, green: 0.55, blue: 0.35),
                Color(red: 0.15, green: 0.4, blue: 0.25), Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.25, green: 0.55, blue: 0.35), Color(red: 0.15, green: 0.4, blue: 0.25),
                Color(red: 0.25, green: 0.55, blue: 0.35), Color(red: 0.15, green: 0.4, blue: 0.25), Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.15, green: 0.4, blue: 0.25),
                Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.25, green: 0.55, blue: 0.35), Color(red: 0.15, green: 0.4, blue: 0.25), Color(red: 0.2, green: 0.5, blue: 0.3)
            ]
        case .ember:
            return [
                .red, .orange, .red, .yellow,
                .orange, .red, .yellow, .orange,
                .yellow, .orange, .red, .orange,
                .red, .yellow, .orange, .red
            ]
        }
    }
}

// MARK: - Large Hero View with Animated Mesh Gradient
struct LargeHero: View {
    var name: String
    var description: String
    var height: Double
    var theme: MeshGradientTheme
    var buttonTitle: String?
    var cornerRadius: Double?
    var onButtonTap: (() -> Void)?
    
    init(name: String, description: String, height: Double, theme: MeshGradientTheme = .ocean, buttonTitle: String? = nil, cornerRadius: Double? = 20, onButtonTap: (() -> Void)? = nil) {
        self.name = name
        self.description = description
        self.height = height
        self.theme = theme
        self.buttonTitle = buttonTitle
        self.cornerRadius = cornerRadius
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Animated Mesh Gradient Background - stretches on overscroll
            AnimatedMeshGradientBackground(theme: theme)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? 20))
                .visualEffect { effect, geometry in
                    let currentHeight = geometry.size.height
                    let scrollOffset = geometry.frame(in: .scrollView).minY
                    let positiveOffset = max(0, scrollOffset)
                    let newHeight = currentHeight + positiveOffset
                    let scaleFactor = newHeight / currentHeight
                    
                    return effect.scaleEffect(
                        x: scaleFactor,
                        y: scaleFactor,
                        anchor: .bottom
                    )
                }
            
            // Content overlay - stays fixed at bottom
            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                
                Text(name)
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 16, weight: .medium))
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .lineLimit(3)
                    .frame(maxWidth: 300, alignment: .leading)
                
                // CTA Button - always reserve space for consistent height
                Group {
                    if let buttonTitle = buttonTitle, let onButtonTap = onButtonTap {
                        Button(action: onButtonTap) {
                            Text(buttonTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.25))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Invisible placeholder to maintain consistent height
                        Text("Placeholder")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .opacity(0)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                    .frame(height: 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 1600)
        }
        .frame(height: height)
    }
}

struct AnimatedMeshGradientBackground: View {
    let theme: MeshGradientTheme
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince1970
            
            // Offset values for smooth animation
            let offsetX = Float(sin(time)) * 0.15
            let offsetY = Float(cos(time)) * 0.15
            let offsetX2 = Float(sin(time * 0.8)) * 0.12
            let offsetY2 = Float(cos(time * 1.2)) * 0.12
            
            MeshGradient(
                width: 4,
                height: 4,
                points: [
                    // Row 0 - top edge fixed
                    [0.0, 0.0], [0.33, 0.0], [0.67, 0.0], [1.0, 0.0],
                    
                    // Row 1 - edges fixed, interior animated
                    [0.0, 0.33],
                    [0.25 + offsetX, 0.35 + offsetY],
                    [0.7 + offsetX2, 0.25 + offsetY2],
                    [1.0, 0.33],
                    
                    // Row 2 - edges fixed, interior animated
                    [0.0, 0.67],
                    [0.3 + offsetX2, 0.75 + offsetY],
                    [0.65 + offsetX, 0.7 + offsetY2],
                    [1.0, 0.67],
                    
                    // Row 3 - bottom edge fixed
                    [0.0, 1.0], [0.33, 1.0], [0.67, 1.0], [1.0, 1.0]
                ],
                colors: theme.colors,
                smoothsColors: true
            )
        }
        .ignoresSafeArea()
    }
}
