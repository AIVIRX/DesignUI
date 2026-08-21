//
//  WelcomeScreen.swift
//  FuseAppOnboarding
//
//  Created by George on 05/11/2025.
//

import SwiftUI

struct WelcomeScreen: View {
    let title: String
    let description: String
    let logo: String
    
    let carousel: [Carousel]
    
    let action: () -> Void
    
    var body: some View {
        ZStack {
            ambientBackdrop

            VStack(spacing: 40) {
                heroPanel

                VStack(alignment: .leading, spacing: 24) {
                    titleBlock
                    metricsRow
                    continueButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 84)
            .padding(.bottom, 34)
        }
    }

    private var ambientBackdrop: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white.opacity(0.06))
                .blur(radius: 80)
                .frame(width: 340, height: 340)
                .offset(x: 130, y: -240)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.white.opacity(0.08))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(x: -150, y: 260)
        }
        .ignoresSafeArea()
    }

    private var heroPanel: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                )

            VStack(alignment: .leading, spacing: 18) {
                brandRow

                TextCarousel(items: carousel)
                    .frame(height: 220)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    private var brandRow: some View {
        HStack(spacing: 14) {
            Image(logo)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("DockUI Studio")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)

                Text("SwiftUI generation with structure")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Text("NEW")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white)
                .clipShape(Capsule())
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DESIGN FASTER. SHIP CLEANER.")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.74))

            Text(title)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(description)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: 460, alignment: .leading)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            MetricPill(title: "Prompt", value: "Natural")
            MetricPill(title: "Canvas", value: "Live")
            MetricPill(title: "Export", value: "SwiftUI")
        }
    }

    private var continueButton: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Enter Workspace")
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.black))
            }
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.white, Color.white.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(.white.opacity(0.56))

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
}
