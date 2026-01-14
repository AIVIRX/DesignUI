//
//  TransparentToolbarModifier.swift
//  DockUI
//
//  Created by Assistant on 1/14/25.
//

import SwiftUI

#if os(macOS)
import AppKit

/// Makes the window toolbar background transparent using NSWindow
struct TransparentToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
    }
}

/// Helper to access and configure the NSWindow
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Make titlebar transparent
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .visible
                
                // Set the toolbar to blend with content
                window.isOpaque = false
                window.backgroundColor = .clear
                
                // Remove the toolbar separator
                if let toolbar = window.toolbar {
                    toolbar.showsBaselineSeparator = false
                }
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Re-apply settings in case window changed
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.titlebarAppearsTransparent = true
                if let toolbar = window.toolbar {
                    toolbar.showsBaselineSeparator = false
                }
            }
        }
    }
}

extension View {
    func transparentToolbar() -> some View {
        self.modifier(TransparentToolbarModifier())
    }
}
#endif
