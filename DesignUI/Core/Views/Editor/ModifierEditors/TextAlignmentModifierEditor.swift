//
//  TextAlignmentModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Text Alignment Modifier Editor
// MARK: - Text Alignment Modifier Editor
struct TextAlignmentModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var alignment: String = "leading"
    
    private let alignments: [(name: String, value: String, icon: String)] = [
        ("Leading", "leading", "text.alignleft"),
        ("Center", "center", "text.aligncenter"),
        ("Trailing", "trailing", "text.alignright")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Text Alignment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(alignment.capitalized)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Alignment Picker
                HStack(spacing: 0) {
                    ForEach(alignments, id: \.value) { item in
                        Button(action: {
                            alignment = item.value
                            saveAlignment()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(alignment == item.value ? Color.blue.opacity(0.1) : Color.clear)
                            .foregroundColor(alignment == item.value ? .blue : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        if item.value != alignments.last?.value {
                            Divider()
                                .frame(height: 20)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .frame(maxHeight: 150)
        .onAppear {
            loadAlignment()
        }
        .onChange(of: modifier) { _, _ in
            loadAlignment()
        }
    }
    
    private func loadAlignment() {
        alignment = modifier.properties["alignment"] as? String ?? "leading"
    }
    
    private func saveAlignment() {
        var updatedModifier = modifier
        updatedModifier.properties["alignment"] = alignment
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

