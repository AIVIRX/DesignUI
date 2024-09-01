//
//  GridColumn.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/31/24.
//

import SwiftUI

var gridColumns: [GridItem] {
#if os(macOS)
    return [GridItem(.adaptive(minimum: 180), spacing: 16)]
#else
    if UIDevice.current.userInterfaceIdiom == .phone {
        return [
            GridItem(.flexible(), spacing: 16),
        ]
    } else if UIDevice.current.userInterfaceIdiom == .pad {
        return [GridItem(.adaptive(minimum: 180), spacing: 16)]
    } else {
        // Fallback Default
        return [GridItem(.flexible(), spacing: 16)]
    }
#endif
}
