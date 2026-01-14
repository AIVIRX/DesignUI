//
//  FullScreenToolbarModifier.swift
//  DockUI
//
//  Created by Assistant on 1/14/25.
//

import SwiftUI

#if os(macOS)
/// Modifier to configure toolbar with clear background on macOS 26+
struct FullScreenToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
                .containerBackground(.clear, for: .window)
        } else {
            content
        }
    }
}
#endif
