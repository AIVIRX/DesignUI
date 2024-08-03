//
//  FeaturesContainerView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/2/24.
//

import SwiftUI

struct FeaturesContainerView: View {
    var body: some View {
        VStack(alignment: .leading) {
            FeaturesView(info: "Remove ads", imageName: "checkmark")
            
            FeaturesView(info: "Access DockUI app logo customization", imageName: "checkmark")
            
            FeaturesView(info: "Unlock verification badge on profile & more!", imageName: "checkmark")
        }
    }
}


#Preview {
    FeaturesContainerView()
}
