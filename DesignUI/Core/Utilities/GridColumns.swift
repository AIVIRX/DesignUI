//
//  GridColumns.swift
//  DockUI
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

var gridColumns: [GridItem] {
#if os(macOS)
    return [GridItem(.adaptive(minimum: 180), spacing: 16)]
#else
    if UIDevice.current.userInterfaceIdiom == .phone {
        return [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    } else if UIDevice.current.userInterfaceIdiom == .pad {
        return [GridItem(.adaptive(minimum: 180), spacing: 16)]
    } else {
        // Fallback Default
        return [GridItem(.flexible(), spacing: 16)]
    }
#endif
}

var componentGridColumns: [GridItem] {
#if os(macOS)
    return [GridItem(.adaptive(minimum: 300), spacing: 16)]
#else
    return [GridItem(.adaptive(minimum: 300), spacing: 16)]
#endif
    
}
