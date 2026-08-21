//
//  ContinueButton.swift
//  FuseAppOnboarding
//
//  Created by George on 04/11/2025.
//

import SwiftUI

struct ContinueButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var state: FieldState
    
    var body: some View {
        Button(action: handleTap) {
            buttonContent
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(buttonBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var buttonBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.black.opacity(0.92),
                Color.black.opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var buttonContent: some View {
        HStack(spacing: 10) {
            buttonLeadingView
            Text(title)
        }
    }

    @ViewBuilder
    private var buttonLeadingView: some View {
        if state == .loading {
            ProgressView()
                .tint(.white)
        } else {
            Image(systemName: icon)
                .font(.subheadline.weight(.black))
        }
    }

    private func handleTap() {
        guard state != .loading else { return }
        action()
    }
}
