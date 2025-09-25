//
//  CopyClipboard.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/25/25.
//

import SwiftUI

func copyToClipboard(_ text: String) {
#if os(iOS)
    UIPasteboard.general.string = text
#elseif os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
#endif
}
