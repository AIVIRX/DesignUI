//
//  ToolbarSpacer.swift
//  DesignUI
//
//  Created by Assistant on 10/01/25.
//

import SwiftUI

/// A custom spacer view for toolbars to mimic the `ToolbarSpacer` API
/// or provide similar functionality on older OS versions.
public struct ToolbarSpacer: View {
    let placement: ToolbarItemPlacement?
    let width: CGFloat?
    
    public init(width: CGFloat? = 12, placement: ToolbarItemPlacement? = nil) {
        self.width = width
        self.placement = placement
    }
    
    public var body: some View {
        if let w = width {
            Spacer()
                .frame(width: w)
        } else {
            Spacer()
        }
    }
}
