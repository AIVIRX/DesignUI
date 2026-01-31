//
//  AIChatViewModel.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/30/26.
//

import SwiftUI
import Combine

struct AIMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    var componentPayload: UIComponent? = nil
    
    static func == (lhs: AIMessage, rhs: AIMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

class AIChatViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isProcessing: Bool = false
    @Published var inputText: String = ""
    
    // Reference to CanvasManager to perform actions
    var canvasManager: CanvasManager?
    
    init() {
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcome = AIMessage(
            text: "Hello! I'm your Design Copilot powered by AI. Ask me to create components like 'a red button' or 'a contact card'.",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcome)
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMsg = AIMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMsg)
        inputText = ""
        isProcessing = true
        
        // Context aware: Send selected component info (simplified) or page name
        var context: [String: String] = [:]
        if let selected = canvasManager?.selectedComponent {
            context["selectedType"] = selected.type.rawValue
            // We could add more properties here
        }
        
        Task {
            do {
                let (chatResponse, component) = try await AIService.shared.generateResponse(prompt: text, context: context)
                
                await MainActor.run {
                    self.isProcessing = false
                    
                    if let component = component {
                        // AI generated a component
                        let msg = AIMessage(
                            text: "I've designed a component for you. Click 'Add to Canvas' to see it.",
                            isUser: false,
                            timestamp: Date(),
                            componentPayload: component
                        )
                        self.messages.append(msg)
                    } else {
                        // Plain chat response
                        let msg = AIMessage(
                            text: chatResponse ?? "I couldn't process that request.",
                            isUser: false,
                            timestamp: Date()
                        )
                        self.messages.append(msg)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.messages.append(AIMessage(
                        text: "Error: \(error.localizedDescription)",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
    
    func addComponentToCanvas(_ component: UIComponent) {
        canvasManager?.addComponent(component)
    }
}
