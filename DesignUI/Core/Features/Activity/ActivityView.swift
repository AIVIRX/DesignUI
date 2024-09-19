//
//  ActivityView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/24.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        VStack{
            Image(systemName: "bell.fill")
                .font(.system(size: 50))
                .foregroundStyle(.gray)
                .padding()
            
            Text("Activity")
                .font(.title).bold()
            Text("No activity available.")
                .font(.title3)
        }
        .padding()
    }
}

#Preview {
    ActivityView()
}
