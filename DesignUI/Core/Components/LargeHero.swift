//
//  LargeHero.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/8/25.
//

import SwiftUI

// MARK: - Modern Color Palettes
struct HeroColorPalette {
    let name: String
    let colors: [Color]
    let gradient: LinearGradient
    
    static let palettes: [HeroColorPalette] = [
        HeroColorPalette(
            name: "Sunset",
            colors: [
                Color(red: 1.0, green: 0.4, blue: 0.4),    // Coral
                Color(red: 1.0, green: 0.6, blue: 0.2),    // Orange
                Color(red: 1.0, green: 0.8, blue: 0.4),    // Light Orange
                Color(red: 1.0, green: 0.3, blue: 0.6),    // Pink
                Color(red: 0.9, green: 0.2, blue: 0.8)     // Magenta
            ],
            gradient: LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroColorPalette(
            name: "Ocean",
            colors: [
                Color(red: 0.2, green: 0.6, blue: 1.0),    // Blue
                Color(red: 0.0, green: 0.8, blue: 0.9),    // Cyan
                Color(red: 0.4, green: 0.9, blue: 1.0),    // Light Blue
                Color(red: 0.1, green: 0.7, blue: 0.8),    // Teal
                Color(red: 0.3, green: 0.5, blue: 0.9)     // Deep Blue
            ],
            gradient: LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroColorPalette(
            name: "Forest",
            colors: [
                Color(red: 0.2, green: 0.8, blue: 0.4),    // Green
                Color(red: 0.4, green: 0.9, blue: 0.6),    // Light Green
                Color(red: 0.1, green: 0.7, blue: 0.3),    // Dark Green
                Color(red: 0.6, green: 0.9, blue: 0.5),    // Mint
                Color(red: 0.3, green: 0.6, blue: 0.4)     // Forest Green
            ],
            gradient: LinearGradient(
                colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroColorPalette(
            name: "Purple",
            colors: [
                Color(red: 0.6, green: 0.3, blue: 0.9),    // Purple
                Color(red: 0.8, green: 0.4, blue: 1.0),    // Light Purple
                Color(red: 0.9, green: 0.2, blue: 0.8),    // Magenta
                Color(red: 0.7, green: 0.5, blue: 1.0),    // Lavender
                Color(red: 0.5, green: 0.2, blue: 0.8)     // Deep Purple
            ],
            gradient: LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroColorPalette(
            name: "Water",
            colors: [
                Color(red: 0.2, green: 0.6, blue: 1.0),    // Blue
                Color(red: 0.0, green: 0.8, blue: 0.9),    // Cyan
                Color(red: 0.4, green: 0.9, blue: 1.0),    // Light Blue
                Color(red: 0.1, green: 0.7, blue: 0.8),    // Teal
                Color(red: 0.3, green: 0.5, blue: 0.9)     // Deep Blue
            ],
            gradient: LinearGradient(
                colors: [Color.cyan.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroColorPalette(
            name: "Warm",
            colors: [
                Color(red: 1.0, green: 0.7, blue: 0.3),    // Warm Orange
                Color(red: 1.0, green: 0.8, blue: 0.4),    // Peach
                Color(red: 0.9, green: 0.6, blue: 0.2),    // Amber
                Color(red: 1.0, green: 0.9, blue: 0.5),    // Cream
                Color(red: 0.8, green: 0.5, blue: 0.1)     // Golden
            ],
            gradient: LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]
    
    static func random() -> HeroColorPalette {
        return palettes.randomElement() ?? palettes[0]
    }
}

struct LargeHero: View {
    @State private var animate: Bool = false
    @State private var selectedPalette: HeroColorPalette
    @State private var animationPhase: Double = 0
    
    var name: String
    var description: String
    var height: Double
    var padding: Double
    
    init(name: String, description: String, height: Double, padding: Double) {
        self.name = name
        self.description = description
        self.height = height
        self.padding = padding
        self._selectedPalette = State(initialValue: HeroColorPalette.random())
    }
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Background gradient overlay
                selectedPalette.gradient
                    .opacity(0.6)
                    .blendMode(.overlay)
              
                
                Rectangle()
                    .fill(selectedPalette.colors[1])
                    .blur(radius: 30)
                    .offset(x: animate ? -60 : 20, y: animate ? 5 : 140)
                    .rotation3DEffect(
                        .degrees(animate ? 20 : 50), 
                        axis: (x: animate ? 0 : 0, y: animate ? 0.4 : 0.2, z: animate ? 0.9 : 0.3)
                    )
                    .opacity(0.7)
                
                Capsule()
                    .fill(selectedPalette.colors[2])
                    .blur(radius: 40)
                    .offset(x: animate ? 60 : 0, y: animate ? -10 : 140)
                    .rotation3DEffect(
                        .degrees(animate ? -30 : 0), 
                        axis: (x: animate ? 0.6 : 0.1, y: animate ? 0.2 : 0.3, z: animate ? 0.1 : 0.4)
                    )
                    .opacity(0.6)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedPalette.colors[3])
                    .blur(radius: 60)
                    .offset(x: animate ? -90 : 40, y: animate ? 90 : -20)
                    .rotation3DEffect(
                        .degrees(animate ? -20 : 10), 
                        axis: (x: animate ? 0 : 0.2, y: animate ? 0 : 0, z: animate ? 0.4 : 0)
                    )
                    .opacity(0.5)
                
                Capsule()
                    .fill(selectedPalette.colors[4])
                    .blur(radius: 70)
                    .offset(x: animate ? 10 : 170, y: animate ? 0 : -150)
                    .opacity(0.4)
                    .rotation3DEffect(
                        .degrees(animate ? 30 : 0), 
                        axis: (x: animate ? 0 : 0.1, y: animate ? 0.5 : 0.1, z: animate ? 0.2 : 0.6)
                    )
                
                // Content with modern styling
                VStack(alignment: .leading, spacing: 12) {
                    Text(name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .scaleEffect(animate ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)
                    
                    Text(description)
                        .foregroundColor(.white.opacity(0.95))
                        .font(.system(size: 16, weight: .medium))
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(animate ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: height)
            .clipped()
            .cornerRadius(15)
            .padding(padding)
            .onAppear {
                // Staggered animations for more dynamic effect
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
                
                // Randomize colors every 10 seconds
                Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 2)) {
                        selectedPalette = HeroColorPalette.random()
                    }
                }
            }
        }
    }
}
