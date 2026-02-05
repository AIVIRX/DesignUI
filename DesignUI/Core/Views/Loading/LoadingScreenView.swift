//
//  LoadingScreenView.swift
//  DesignUI
//
//  Created by Claude on 12/30/24.
//

import SwiftUI

/// Figma-style loading screen with animated progress bar
struct LoadingScreenView: View {
    @ObservedObject var loadingState: AppLoadingState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var animateGradient = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon / logo area
                logoSection
                
                Spacer()
                
                // Progress section
                progressSection
                    .padding(.horizontal, 60)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.9, green: 0.9, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 20) {
            // App icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseScale)
                
                // Icon background
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.blue.opacity(0.4), radius: 20, x: 0, y: 10)
                
                // Icon symbol
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // App name
            Text("DockUI")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                    
                    // Progress fill
                    Capsule()
                        .fill(progressGradient)
                        .frame(width: max(8, geometry.size.width * loadingState.loadingProgress))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: loadingState.loadingProgress)
                }
            }
            .frame(height: 8)
            .frame(maxWidth: 320)
            
            // Loading message
            Text(loadingState.loadingMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.5))
                .animation(.easeInOut(duration: 0.2), value: loadingState.loadingMessage)
        }
    }
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: animateGradient ? 
                [Color.blue, Color.purple, Color.blue] :
                [Color.purple, Color.blue, Color.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Gradient animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animateGradient = true
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}
