//
//  LargeHero.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/8/25.
//

import SwiftUI

// MARK: - Ocean Colors (Hardcoded)

struct LargeHero: View {
    @State private var animate: Bool = false
    @State private var animationPhase: Double = 0
    
    var name: String
    var description: String
    var height: Double
    var padding: Double
    
    // Hardcoded Ocean colors
    private let oceanColors = [
        Color(red: 0.2, green: 0.6, blue: 1.0),    // Blue
        Color(red: 0.0, green: 0.8, blue: 0.9),    // Cyan
        Color(red: 0.4, green: 0.9, blue: 1.0),    // Light Blue
        Color(red: 0.1, green: 0.7, blue: 0.8),    // Teal
        Color(red: 0.3, green: 0.5, blue: 0.9)     // Deep Blue
    ]
    
    private let oceanGradient = LinearGradient(
        colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    init(name: String, description: String, height: Double, padding: Double) {
        self.name = name
        self.description = description
        self.height = height
        self.padding = padding
    }
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Background gradient overlay
                oceanGradient
                    .opacity(0.6)
                    .blendMode(.overlay)
              
                
                Rectangle()
                    .fill(oceanColors[1])
                    .blur(radius: 30)
                    .offset(x: animate ? -60 : 20, y: animate ? 5 : 140)
                    .rotation3DEffect(
                        .degrees(animate ? 20 : 50), 
                        axis: (x: animate ? 0 : 0, y: animate ? 0.4 : 0.2, z: animate ? 0.9 : 0.3)
                    )
                    .opacity(0.7)
                
                Capsule()
                    .fill(oceanColors[2])
                    .blur(radius: 40)
                    .offset(x: animate ? 60 : 0, y: animate ? -10 : 140)
                    .rotation3DEffect(
                        .degrees(animate ? -30 : 0), 
                        axis: (x: animate ? 0.6 : 0.1, y: animate ? 0.2 : 0.3, z: animate ? 0.1 : 0.4)
                    )
                    .opacity(0.6)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(oceanColors[3])
                    .blur(radius: 60)
                    .offset(x: animate ? -90 : 40, y: animate ? 90 : -20)
                    .rotation3DEffect(
                        .degrees(animate ? -20 : 10), 
                        axis: (x: animate ? 0 : 0.2, y: animate ? 0 : 0, z: animate ? 0.4 : 0)
                    )
                    .opacity(0.5)
                
                Capsule()
                    .fill(oceanColors[4])
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
            }
        }
    }
}
