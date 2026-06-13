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
            .font(.headline)
            .bold()
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.black)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        }
    }

    private func handleTap() {
        guard state != .loading else { return }
        action()
    }
}
