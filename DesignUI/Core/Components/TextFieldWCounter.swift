//
//  TextFieldWCounter.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/16/24.
//

import SwiftUI

struct TextFieldWithCounter: View {
    let placeholder: String
    @Binding var text: String
    let maxLength: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text(placeholder)
                .font(.headline)
            TextField(placeholder, text: $text){}
            .font(Font.system(size: 20, design: .default))
            .controlSize(.large)
            .autocorrectionDisabled()
#if os(iOS)
            .textInputAutocapitalization(.none)
#endif
            .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
            HStack {
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(text.count > maxLength ? .red : .secondary)
            }
        }
        .textFieldStyle(.roundedBorder)
        .onChange(of: text) {
            if text.count > maxLength {
                text = String(text.prefix(maxLength))
            }
        }
    }
}
