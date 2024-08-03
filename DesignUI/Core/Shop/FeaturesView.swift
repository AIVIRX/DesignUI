//
//  FeaturesView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/2/24.
//

import SwiftUI

struct FeaturesView: View {
    var info: String = "Hello World"
    var imageName: String = "car"
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.title3)
                .foregroundColor(.mainColor)
                .frame(height: 50)
                .accessibility(hidden: true)
            
            Text(info)
                .font(.body)
                .padding(.leading,5)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

#Preview {
    FeaturesView()
}
