//
//  GridConfiguration.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

class GridConfiguration {
    static let shared = GridConfiguration()
    
    private init() {}
    
    var columns: [GridItem] {
        #if os(macOS)
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        #else
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        } else {
            return [GridItem(.adaptive(minimum: 250), spacing: 16)]
        }
        #endif
    }
}
