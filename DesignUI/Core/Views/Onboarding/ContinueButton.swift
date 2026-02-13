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
        Button(action: {
            if state != .loading {
                action()
            }
        }) {
            if state == .loading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: icon)
            }
            
            Text(title)
                .font(.headline)
                .bold()
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.black)
        .cornerRadius(.infinity)
    }
}
