//
//  OnboardingFlow.swift
//  FuseAppOnboarding
//
//  Created by George on 05/11/2025.
//

import SwiftUI

struct OnboardingFlowView: View {
    let title: String
    let description: String
    let logo: String
    var startGradient: (Color, Color, Color)?
    let carousel: [Carousel]
    let form: [FormStep]
    let completion: CompletionStep
    
    @FocusState private var keyboardShown: Bool
    @State private var showGradient = true
    
    @State private var phase = 0
    @State private var gradient: (Color, Color, Color) = (
        Color(red: 0.004, green: 0.373, blue: 1, opacity: 1),
        Color(red: 0, green: 0.875, blue: 1, opacity: 1),
        Color(red: 0.004, green: 0.678, blue: 1, opacity: 1)
    )
    
    var body: some View {
        content
        .background(
            Color(red: 0.07, green: 0.09, blue: 0.14)
        )
        .ignoresSafeArea(.container)
        .onAppear {
            if let startGradient {
                gradient = startGradient
            }
        }
        .onChange(of: keyboardShown) { _, newValue in
            withAnimation(.smooth) {
                showGradient = !newValue
            }
        }
    }

    private var content: some View {
        ZStack {
            gradientBackgroundLayer
            phaseContent
        }
    }

    @ViewBuilder
    private var gradientBackgroundLayer: some View {
        if showGradient {
            animatedGradientBackground
                .transition(.move(edge: .top))
        }
    }

    private var animatedGradientBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    .clear,
                    Color.black.opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            gradientLayer(
                color: gradient.0,
                center: phase > 0 ? .top : .bottom,
                startRadius: phase > 0 ? 0 : 300,
                endRadius: 500,
                delay: 0.65
            )

            gradientLayer(
                color: gradient.1,
                center: phase > 0 ? .top : .bottom,
                startRadius: phase > 0 ? 50 : 200,
                endRadius: 450,
                delay: 0.52
            )

            gradientLayer(
                color: gradient.2,
                center: phase > 0 ? .init(x: 0.5, y: -0.2) : .bottom,
                startRadius: phase > 0 ? 0 : 80,
                endRadius: 350,
                delay: 0.4
            )
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .padding(18)
        }
    }

    private func gradientLayer(
        color: Color,
        center: UnitPoint,
        startRadius: CGFloat,
        endRadius: CGFloat,
        delay: Double
    ) -> some View {
        RadialGradient(
            colors: [color, .clear],
            center: center,
            startRadius: startRadius,
            endRadius: endRadius
        )
        .animation(.smooth.delay(delay), value: phase > 0)
    }

    private var phaseContent: some View {
        VStack {
            welcomePhase
            formPhase
        }
    }

    @ViewBuilder
    private var welcomePhase: some View {
        if phase == 0 {
            WelcomeScreen(
                title: title,
                description: description,
                logo: logo,
                carousel: carousel,
                action: beginFormFlow
            )
            .transition(screenTransition)
        }
    }

    @ViewBuilder
    private var formPhase: some View {
        if phase == 2 {
            MultiStepForm(
                steps: form,
                completionStep: completion,
                gradient: $gradient,
                keyboardShown: $keyboardShown,
            )
            .transition(screenTransition)
        }
    }

    private var screenTransition: AnyTransition {
        .opacity.combined(with: .offset(y: 20))
    }

    private func beginFormFlow() {
        withAnimation(.smooth(duration: 0.7)) {
            phase = 1

            if let formStartGradient = form.first?.gradient {
                gradient = formStartGradient
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.smooth) {
                    phase = 2
                }
            }
        }
    }
}
