//
//  LayoutToolbar.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/23/24.
//

import SwiftUI

struct LayoutToolbar: View {
    @ObservedObject var canvasManager: CanvasManager
    
    var body: some View {
        HStack(spacing: 4) {
            // Alignment Group
            Group {
                LayoutToolbarButton(icon: "align.horizontal.left.fill", tooltip: "Align Left") {
                    canvasManager.alignSelected(.left)
                }
                LayoutToolbarButton(icon: "align.horizontal.center.fill", tooltip: "Align Horizontal Center") {
                    canvasManager.alignSelected(.centerHorizontally)
                }
                LayoutToolbarButton(icon: "align.horizontal.right.fill", tooltip: "Align Right") {
                    canvasManager.alignSelected(.right)
                }
                
                Divider().frame(height: 16).padding(.horizontal, 4)
                
                LayoutToolbarButton(icon: "align.vertical.top.fill", tooltip: "Align Top") {
                    canvasManager.alignSelected(.top)
                }
                LayoutToolbarButton(icon: "align.vertical.center.fill", tooltip: "Align Vertical Center") {
                    canvasManager.alignSelected(.centerVertically)
                }
                LayoutToolbarButton(icon: "align.vertical.bottom.fill", tooltip: "Align Bottom") {
                    canvasManager.alignSelected(.bottom)
                }
            }
            
            Divider().frame(height: 16).padding(.horizontal, 4)
            
            // Distribution Group
            Group {
                LayoutToolbarButton(icon: "distribute.horizontal.fill", tooltip: "Distribute Horizontally") {
                    canvasManager.distributeSelected(.horizontally)
                }
                LayoutToolbarButton(icon: "distribute.vertical.fill", tooltip: "Distribute Vertically") {
                    canvasManager.distributeSelected(.vertically)
                }
            }
            
            Divider().frame(height: 16).padding(.horizontal, 4)
            
            // Grouping Group
            Group {
                LayoutToolbarButton(icon: "rectangle.stack.fill", tooltip: "Group in VStack") {
                    canvasManager.groupSelected(into: .vstack)
                }
                // HStack icon is usually horizontal stacks. Using degrees(90) on vstack icon is a common shortcut
                LayoutToolbarButton(icon: "rectangle.stack.fill", tooltip: "Group in HStack", iconRotation: .degrees(90)) {
                    canvasManager.groupSelected(into: .hstack)
                }
                LayoutToolbarButton(icon: "square.stack.3d.up.fill", tooltip: "Group in ZStack") {
                    canvasManager.groupSelected(into: .zstack)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                #if os(macOS)
                .fill(Color(NSColor.windowBackgroundColor))
                #else
                .fill(Color(UIColor.systemBackground))
                #endif
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct LayoutToolbarButton: View {
    let icon: String
    let tooltip: String
    var iconRotation: Angle = .zero
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .rotationEffect(iconRotation)
                .frame(width: 32, height: 32)
                .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                .foregroundColor(isHovered ? .accentColor : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
