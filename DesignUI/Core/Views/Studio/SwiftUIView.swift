
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SwiftUIView()
}
