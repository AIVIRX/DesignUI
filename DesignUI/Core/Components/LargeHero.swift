//
//  LargeHero.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/8/25.
//

import SwiftUI
import FluidGradient

// MARK: - Large Hero View with Animated Mesh Gradient
struct LargeHero: View {
    var name: String
    var description: String
    var height: Double
    var buttonTitle: String?
    var cornerRadius: Double?
    var onButtonTap: (() -> Void)?
    
    init(name: String, description: String, height: Double, buttonTitle: String? = nil, cornerRadius: Double? = 20, onButtonTap: (() -> Void)? = nil) {
        self.name = name
        self.description = description
        self.height = height
        self.buttonTitle = buttonTitle
        self.cornerRadius = cornerRadius
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Animated Fluid Gradient Background - stretches on overscroll
            FluidGradient(blobs: [.purple, .blue, .cyan],
                          speed: 0.4,
                          blur: 0.75)
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


