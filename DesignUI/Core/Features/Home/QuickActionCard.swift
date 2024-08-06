//
//  QuickActionCard.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/4/24.
//

import SwiftUI

struct QuickActionCard: View {
    @State private var showPaywall = false
    var body: some View {
        VStack {
            VStack {
                HStack {
                    NavigationLink(destination: SFIconsView()) {
                        VStack{
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 20))
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    ))
                            
                            Text("Symbols")
                                .font(.body)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.horizontal)
                    .buttonStyle(PlainButtonStyle())

//                    NavigationLink(destination: SFIconsView()) {
//                        VStack{
//                            Image(systemName: "square.dashed.inset.fill")
//                                .font(.system(size: 20))
//                                .padding()
//                                .foregroundColor(.white)
//                                .background(
//                                    RoundedRectangle(
//                                        cornerRadius: 10,
//                                        style: .continuous
//                                    ))
//                            
//                            Text("App Icon")
//                                .font(.body)
//                                .foregroundStyle(Color.primary)
//                        }
//                    }
//                    .padding(.horizontal)
//                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: OldStoreView()){
                        VStack{
                            Image(systemName: "cart")
                                .font(.system(size: 20))
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    ))
                            
                            Text("Shop")
                                .font(.body)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.horizontal)
                    .buttonStyle(PlainButtonStyle())

                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(.thinMaterial)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.symbolVariants, .none)
        .accentColor(.none)
    }
}


#Preview {
    QuickActionCard()
}
