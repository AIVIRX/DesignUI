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
            .padding(.vertical)
            .padding(.horizontal, 24)
            .background(Color.gray)
            .clipShape(Capsule(style: .continuous))
    }
}
                
