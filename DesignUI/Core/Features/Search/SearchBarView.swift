//
//  SearchBarView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack{
            Image(systemName: "magnifyingglass")
                .foregroundStyle(colorScheme == .dark ? .black : .white)
            
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text("Search Dock UI")
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 8)
                }
                TextField("", text: $searchText)
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .padding(.horizontal, 8)
                    .submitLabel(.go)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .padding()
                            .offset(x: 10)
                            .foregroundStyle(colorScheme == .dark ? .gray : .white)
                            .opacity(searchText.isEmpty ? 0.0 : 1.0)
                            .onTapGesture {
                                searchText = ""
                            },
                        alignment: .trailing
                    )
            }
        }
        .font(.headline)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(colorScheme == .dark ? .white : .black)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 10, x: 0, y: 0)
        )
        .padding()
    }
}

#Preview {
    @Previewable @State var searchText = "lol"
    
    SearchBarView(searchText: $searchText)
}
