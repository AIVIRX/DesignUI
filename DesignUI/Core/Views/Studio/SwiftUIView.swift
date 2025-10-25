
//
//  SwiftUIView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/21/25.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        ScrollView{
            Text("Hello, World!")
                .foregroundStyle(Color.yellow)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.1)
        }
    }
}

#Preview {
    


    SwiftUIView()
}
