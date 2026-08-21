//
//  CompletionStep.swift
//  FuseAppOnboarding
//
//  Created by George on 04/11/2025.
//

import SwiftUI

struct CompletionStep: View {
    let title: String
    let description: String
    let completionTitle: String
    let completionDescription: String
    let onSubmit: () async -> Void
    let onComplete: () -> Void
    
    @State private var isCompleted = false
    @State private var isInProgress = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                .id(isCompleted)
                .rotationEffect(.degrees(isCompleted ? 0 : isInProgress ? 360 : 0))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(isCompleted ? Color.green : .white.opacity(0.8))
                .transition(.scale)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(isCompleted ? completionTitle : title)
                    .id(isCompleted)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 30).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                
                Text(isCompleted ? completionDescription : description)
                    .id(isCompleted)
                    .foregroundStyle(.white.opacity(0.68))
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 30).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
            .drawingGroup()
        }
        .padding(22)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.linear(duration: 1).speed(0.3).repeatForever(autoreverses: false)) {
                isInProgress = true
            }
            
            Task {
                await onSubmit()
                
                withAnimation(.bouncy(duration: 1)) {
                    isCompleted = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onComplete()
                }
            }
        }
    }
}
