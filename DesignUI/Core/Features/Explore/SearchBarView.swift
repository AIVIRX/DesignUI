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
    @State private var isLoading = false
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(colorScheme == .dark ? .gray : .gray)
                
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search \"Template\"")
                            .foregroundStyle(Color.gray)
                            .padding(.horizontal, 8)
                    }
                    TextField("", text: $searchText, onEditingChanged: { focused in
                        isFocused = focused
                        if focused { // Trigger search when the text field is focused
                        }
                    })
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, 8)
                    .submitLabel(.go)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .padding()
                            .offset(x: 10)
                            .foregroundStyle(colorScheme == .dark ? .gray : .gray)
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
                    .fill(colorScheme == .dark ? .black : .white)
                    .shadow(
                        color: colorScheme == .light ? Color.black.opacity(0.1) : Color.white.opacity(0.2) ,
                        radius: 10, x: 0, y: 0)
            )
            .padding()
            // Results list
//            if isFocused || !searchText.isEmpty {
//                if isLoading {
//                    ProgressView("Loading...") // Loading indicator
//                } else if !results.isEmpty {
//                    List(results, id: \.id) { post in
//                        Text(post.title)  // Customize this to show post details
//                            .onTapGesture {
//                                searchText = post.title
//                                isFocused = false
//                            }
//                    }
//                    .frame(maxHeight: 200)
//                } else if !searchText.isEmpty {
//                    Text("No results found")
//                        .foregroundStyle(.gray)
//                        .padding()
//                }
//            }
        }
    }
    
    // Debounced search
    
    
    // Query Firestore for posts containing search text
}


#Preview {
    @Previewable @State var searchText = "lol"
    
    SearchBarView(searchText: $searchText)
}
