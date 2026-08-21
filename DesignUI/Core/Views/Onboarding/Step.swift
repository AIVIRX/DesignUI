//
//  Step.swift
//  FuseAppOnboarding
//
//  Created by George on 04/11/2025.
//

import SwiftUI

struct Step: View {
    let icon: String
    let iconColour: Color
    let title: String
    let description: String
    
    var isExpanded: Bool
    
    var body: some View {
        let layout = isExpanded
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 24))
        
        layout {
            Group {
                Image(systemName: icon)
                    .font(.system(size: isExpanded ? 30 : 18, weight: .bold, design: .rounded))
                    .bold()
                    .foregroundStyle(isExpanded ? .white : .white.opacity(0.58))
                    .frame(width: isExpanded ? 58 : 40, height: isExpanded ? 58 : 40)
                    .background(
                        RoundedRectangle(cornerRadius: isExpanded ? 18 : 14, style: .continuous)
                            .fill(isExpanded ? iconColour.opacity(0.9) : .white.opacity(0.08))
                    )
                
                Text(title)
                    .font(.system(size: isExpanded ? 38 : 22, weight: .bold, design: .rounded))
                    .bold()
                    .foregroundStyle(.white.opacity(isExpanded ? 1 : 0.58))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .drawingGroup()
            
            if isExpanded {
                Text(description)
                    .foregroundStyle(.white.opacity(0.72))
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 30).combined(with: .opacity),
                            removal: .offset(y: -60).combined(with: .opacity)
                        )
                        .animation(.smooth(duration: 0.2))
                    )
            }
        }
        .padding(isExpanded ? 22 : 0)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(isExpanded ? .white.opacity(0.1) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(isExpanded ? .white.opacity(0.12) : .clear, lineWidth: 1)
        )
    }
}
