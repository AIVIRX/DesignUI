//
//  SymbolRow.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct SymbolRow: View {
    let symbol: String
    let onCopy: (String) -> Void
    var body: some View {
        HStack {
            Image(systemName: symbol)
                .font(.system(size: 40))
            Text(symbol)
            Spacer()
            Button(action: {
                onCopy(symbol)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
        }
    }
}
