//
//  TextAlignmentModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Text Alignment Modifier Editor
struct TextAlignmentModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var alignment: String = "leading"
    
    private let alignments: [(String, String)] = [
        ("leading", "text.alignleft"),
        ("center", "text.aligncenter"),
        ("trailing", "text.alignright")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alignment")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(alignments, id: \.0) { alignValue, iconName in
                    Button(action: {
                        alignment = alignValue
                        var updatedModifier = modifier
                        updatedModifier.properties["alignment"] = alignValue
                        modifier = updatedModifier
                        component.updateModifier(updatedModifier)
                    }) {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(alignment == alignValue ? .white : .primary)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(alignment == alignValue ? Color.blue : Color.gray.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            alignment = modifier.properties["alignment"] as? String ?? "leading"
        }
        .onReceive(component.objectWillChange) { _ in
            // Sync alignment when component updates
            if let currentAlignment = modifier.properties["alignment"] as? String, currentAlignment != alignment {
                alignment = currentAlignment
            }
        }
    }
}

