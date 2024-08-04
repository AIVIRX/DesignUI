//
//  StoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

//
//  StoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct StoreView: View {
    @State private var selectedPackage: Package?
    @State private var purchaseError: Error?
    @State private var cooo = false
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(alignment: .center) {
            ScrollView {
                SubscribtionTitleView()

                FeaturesContainerView()
            }
            .padding()
            .background(colorScheme == .dark ? .black : .white)
            .paywallFooter()
        }
    }
}

struct SubscribtionTitleView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .padding()
                        .font(.title)
                        .foregroundStyle(.gray)
                }
            }
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibility(hidden: true)
            
            Text("Dock UI")
                .customTitleText()
            
            Text("Premium")
                .customTitleText()
                .foregroundColor(.mainColor)
        }
    }
}

#Preview {
    StoreView()
}
