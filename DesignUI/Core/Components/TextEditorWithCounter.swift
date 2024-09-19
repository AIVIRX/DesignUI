//
//  TextEditorWithCounter.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/16/24.
//

import SwiftUI

struct TextEditorWithCounter: View {
    let label: String
    @Binding var text: String
    let maxLength: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            
            TextEditor(text: $text)
                .font(Font.system(size: 20, design: .default))
                .controlSize(.large)
                .frame(height: 100)
                .autocorrectionDisabled()
#if os(iOS)
                .textInputAutocapitalization(.none)
#endif
                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
            HStack{
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(text.count > maxLength ? .red : .secondary)
            }
        }
        .onChange(of: text) {
            if text.count > maxLength {
                text = String(text.prefix(maxLength))
            }
        }
    }
}
