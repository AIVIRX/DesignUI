//
//  SFIconsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import AlertToast

struct SFIconsView: View {
    @State private var searchText = ""
    @State private var showToast = false
    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return symbols
        } else {
            return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .padding()
                    .bold()
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                
                List(filteredSymbols, id: \.self) { symbol in
                    SymbolRow(symbol: symbol, onCopy: { copiedSymbol in
                        copyToClipboard(copiedSymbol)
                        showToast = true
                    })
                }
                .listStyle(PlainListStyle())
            }
            .padding(5)
            .toast(isPresenting: $showToast) {
                AlertToast(displayMode: .hud, type: .regular, title: "Copied")
            }
        }
    }
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}
