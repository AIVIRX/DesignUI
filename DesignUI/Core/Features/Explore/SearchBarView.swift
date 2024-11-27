//
//  SearchBarView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI
import Firebase

struct SearchBarView: View {
    @Binding var searchText: String
    @Environment(\.colorScheme) var colorScheme
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
                .font(.system(size: 17, weight: .medium))
            
            // Search TextField
            TextField("Search designs...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            // Clear button
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
