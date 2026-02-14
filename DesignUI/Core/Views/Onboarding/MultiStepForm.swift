//
//  MultiStepForm.swift
//  FuseAppOnboarding
//
//  Created by George on 04/11/2025.
//

import SwiftUI

enum FieldState {
    case idle
    case loading
    case success
    case error
}

enum StepType {
    case button(title: String, icon: String)
}

public struct FormStep: Identifiable {
    public let id = UUID()
    let icon: String
    let title: String
    let description: String
    
    let type: StepType
    let gradient: (Color, Color, Color)
    
    let onSubmit: (String) async throws -> Void
    var state: FieldState = .idle
    
    var answer: String = ""
}

struct MultiStepForm: View {
    @State var steps: [FormStep]
    @State private var currentStep = 0
    
    let completionStep: CompletionStep
    
    @Binding var gradient: (Color, Color, Color)
    @FocusState.Binding var keyboardShown: Bool
    
    private var hasFinishedForm: Bool {
        currentStep >= steps.count
    }
    
    var body: some View {
        VStack (spacing: 64) {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(steps, id: \.id) { step in
                    Step(
                        icon: step.icon,
                        iconColour: step.gradient.0,
                        title: step.title,
                        description: step.description,
                        isExpanded: !hasFinishedForm && step.id == steps[currentStep].id
                    )
                }
                
                ZStack {
                    if hasFinishedForm {
                        CompletionStep(
                            title: completionStep.title,
                            description: completionStep.description,
                            completionTitle: completionStep.completionTitle,
                            completionDescription: completionStep.completionDescription,
                            onSubmit: completionStep.onSubmit,
                            onComplete: completionStep.onComplete
                        )
                        .transition(.offset(y: 40).combined(with: .opacity))
                    }
                }
                .animation(.default.delay(0.4), value: hasFinishedForm)
            }
            
            if !hasFinishedForm {
                switch steps[currentStep].type {
                case .button(let title, let icon):
                    ContinueButton(
                        title: title,
                        icon: icon,
                        action: submitCurrentStep,
                        state: steps[currentStep].state
                    )
                    .animation(.none, value: currentStep)
                
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hasFinishedForm ? .center : .bottomLeading)
        .padding(42)
    }
    
    private func submitCurrentStep() {
        guard currentStep >= 0 && currentStep < steps.count else { return }
        
        let submitAction = steps[currentStep].onSubmit
        let answer = steps[currentStep].answer
        
        steps[currentStep].state = .loading
        keyboardShown = false
        
        let isLastStep = currentStep == steps.count - 1
        
        Task {
            do {
                try await submitAction(answer)
                
                steps[currentStep].state = .success
                
                if isLastStep {
                    gradient = (.clear, .clear, .clear)
                }
                
                withAnimation(.smooth(duration: 0.5)) {
                    currentStep += 1
                    
                    if !isLastStep {
                        gradient = steps[currentStep].gradient
                    }
                }
            } catch {
                steps[currentStep].state = .error
            }
        }
    }
}
