//
//  UndoToastView.swift
//  DesignUI
//
//  Created by Antigravity on 1/15/26.
//

import SwiftUI

/// A toast view that displays undo/redo action messages
struct UndoToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.black.opacity(0.8))
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VStack {
        UndoToastView(message: "Undo: Deleted Text")
        UndoToastView(message: "Redo: Added VStack")
    }
    .padding()
}
