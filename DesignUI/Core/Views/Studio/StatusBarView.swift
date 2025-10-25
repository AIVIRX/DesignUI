//
//  StatusBarView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Status Bar View
struct StatusBarView: View {
    let deviceSize: CGSize
    let isSelected: Bool
    let colorScheme: ColorScheme?
    let onSelect: () -> Void
    
    private var statusBarHeight: CGFloat {
        return 53.0
    }
    
    private var statusBarTextColor: Color {
        if colorScheme == .light {
            return .black
        } else {
            return .white
        }
    }
    
    var body: some View {
        HStack {
            // Left side - Time
            Text("9:41")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(statusBarTextColor)
            
            Spacer()
            
            // Right side - Status icons
            HStack(spacing: 4) {
                // Signal strength
                HStack(spacing: 2) {
                    ForEach(0..<4) { _ in
                        Rectangle()
                            .fill(statusBarTextColor)
                            .frame(width: 3, height: 4)
                    }
                }
                
                // WiFi
                Image(systemName: "wifi")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusBarTextColor)
                
                // Battery
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(statusBarTextColor)
                        .frame(width: 20, height: 10)
                        .overlay(
                            Rectangle()
                                .fill(statusBarTextColor)
                                .frame(width: 2, height: 6)
                                .offset(x: 11)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(width: deviceSize.width, height: statusBarHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
