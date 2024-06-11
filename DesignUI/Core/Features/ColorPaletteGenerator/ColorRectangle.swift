//
//  ColorRectangle.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct ColorRectangle: View {
    var color: Color
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 300, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
    }
}
