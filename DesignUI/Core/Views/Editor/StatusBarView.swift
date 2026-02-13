//
//  StatusBarView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct StatusBarView: View {
    let deviceSize: CGSize
    let colorScheme: ColorScheme?
    
    private var statusBarHeight: CGFloat {
        return 50.0
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(statusBarTextColor)
                .frame(width: 100)
            
            Spacer()
            
            // Right side - Status icons
            HStack(spacing: 5) {
                // Signal strength
                Image(systemName: "cellularbars")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(statusBarTextColor)
                
                // WiFi
                Image(systemName: "wifi")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(statusBarTextColor)
                
                // Battery
                Image(systemName: "battery.75percent")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(statusBarTextColor)
            }
            .frame(width: 100)
        }
        .padding(.horizontal, 15)
        .frame(width: deviceSize.width, height: statusBarHeight)
        .contentShape(Rectangle())
    }
}
