//
//  TextFieldStyle.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/26/25.
//

import SwiftUI

// Custom Text Field Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity (0.1)))
    }
}
                
