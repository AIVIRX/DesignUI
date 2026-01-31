//
//  AIChatView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/30/26.
//

import SwiftUI

enum AIChatMode {
    case floating   // macOS / iPad Overlay
    case fullScreen // iPhone Tab
}

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @ObservedObject var canvasManager: CanvasManager
    var mode: AIChatMode
    
    // For floating mode dismissal/expansion
    @State private var isExpanded: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        Group {
            if mode == .floating {
                floatingLayout
            } else {
                fullScreenLayout
            }
        }
        .onAppear {
            viewModel.canvasManager = canvasManager
        }
    }
    
    // MARK: - Full Screen Layout (iPhone)
    private var fullScreenLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Design Copilot")
                    .font(.headline)
                Spacer()
                if viewModel.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(Color.systemBackground)
            
            Divider()
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message) {
                                if let component = message.componentPayload {
                                    viewModel.addComponentToCanvas(component)
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask Copilot...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.inputText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding()
            .background(Color.secondarySystemBackground)
        }
        .background(Color.systemGroupedBackground)
    }
    
    // MARK: - Floating Layout (macOS / iPad)
    private var floatingLayout: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Chat Area
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Design Copilot")
                            .font(.headline)
                        Spacer()
                        Button(action: { withAnimation { isExpanded = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Material.regular)
                    
                    Divider()
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message) {
                                        if let component = message.componentPayload {
                                            viewModel.addComponentToCanvas(component)
                                        }
                                    }
                                    .id(message.id)
                                }
                                if viewModel.isProcessing {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                        Text("Thinking...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding()
                        }
                        .frame(height: 300) // Fixed height for floating popover
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let last = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .background(Material.thin)
            }
            
            // Floating Input Bar (Always Visible)
            HStack(spacing: 12) {
                if !isExpanded {
                    Button(action: { withAnimation { isExpanded = true } }) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
                
                TextField("Describe a change or component...", text: $viewModel.inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14)) // Consistent font size
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !isExpanded { withAnimation { isExpanded = true } }
                        viewModel.sendMessage()
                    }
                    .frame(height: 36) // Explicit height for macOS/iPad text field area
                    
                
                if !viewModel.inputText.isEmpty {
                    Button(action: {
                        if !isExpanded { withAnimation { isExpanded = true } }
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12) // Slightly more vertical padding
            .background(Material.regular)
            .cornerRadius(isExpanded ? 0 : 25) // Round fully when collapsed
            .onTapGesture {
                if !isExpanded {
                    withAnimation { isExpanded = true }
                    isInputFocused = true
                }
            }
        }
        .frame(width: 400) // Fixed width for floating panel
        .background(Color.clear)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: AIMessage
    var onAdd: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 12,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 2,
                            topTrailingRadius: 12
                        )
                    )
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.text)
                            .padding(10)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 12,
                                    bottomLeadingRadius: 2,
                                    bottomTrailingRadius: 12,
                                    topTrailingRadius: 12
                                )
                            )
                        
                        // Actionable Component Card
                        if let component = message.componentPayload {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: component.type.icon)
                                    Text(component.type.rawValue)
                                        .font(.caption).bold()
                                    Spacer()
                                }
                                
                                Button(action: {
                                    onAdd?()
                                }) {
                                    HStack {
                                        Text("Add to Canvas")
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .frame(maxWidth: 250)
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Cross-Platform Color Helper
extension Color {
    static var systemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    static var secondarySystemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
    
    static var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
}
