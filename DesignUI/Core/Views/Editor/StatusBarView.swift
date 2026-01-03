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
                .frame(width: 100)
            
            Spacer()
            
            // Right side - Status icons
            HStack(spacing: 5) {
                // Signal strength
                Image(systemName: "cellularbars")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusBarTextColor)
                
                // WiFi
                Image(systemName: "wifi")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusBarTextColor)
                
                // Battery
                Image(systemName: "battery.75percent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusBarTextColor)
            }
            .frame(width: 100)
        }
        .padding(.horizontal, 20)
        .padding(.top, 5)
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
