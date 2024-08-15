//
//  OldStoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/5/24.
//

import SwiftUI

struct OldStoreView: View {
    @EnvironmentObject private var store: Store
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    var body: some View {
        VStack{
            List(store.allRecipes, id: \.self) { recipe in
                Group{
                    if !recipe.isLocked {
                        RecipeRow(recipe: recipe){ }
                    } else {
                        RecipeRow(recipe: recipe){
                            if let product = store.product(for: recipe.id){
                                store.purchaseProduct(product)
                            }
                        }
                    }
                }
#if os(iOS)
                .navigationBarItems(trailing: Button("Restore"){
                    store.retorePurchases()
                })
#endif
                .onAppear{
                    store.loadStoredPurchases()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        startAnimation = true
                        opacity = 1.0
                    }
                }
            }
        }
        .background(Color(red: 30/255, green: 30/255, blue: 30/255))
        .navigationTitle("Shop")
        
        
#if os(iOS)
        if !store.completedPurchases.isEmpty{
            
        } else {
            if UIDevice.current.userInterfaceIdiom == .phone {
                AdView(adUnitID: AdUnitID.shopPageAds)
                    .frame(width: 320, height: 50)
                    .padding(3)
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdView(adUnitID: AdUnitID.shopPageAds)
                    .frame(width: 468, height: 60)
                    .padding(3)
            }
        }
#endif
    }
}
