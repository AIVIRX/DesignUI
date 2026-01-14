//
//  ScrollEdgeEffectHiddenModifier.swift
//  DockUI
//
//  Created by Assistant on 1/14/25.
//

import SwiftUI

#if os(macOS)
/// Modifier to hide scroll edge effects on macOS 26+
struct ScrollEdgeEffectHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.scrollEdgeEffectHidden()
        } else {
            content
        }
    }
}
#endif
