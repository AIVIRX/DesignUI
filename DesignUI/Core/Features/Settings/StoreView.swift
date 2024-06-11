//
//  StoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var store: Store
    
    var body: some View {
        VStack {
            List(store.allRecipes, id: \.self) { recipe in
                Group {
                    if !recipe.isLocked {
                        RecipeRow(recipe: recipe) { }
                    } else {
                        RecipeRow(recipe: recipe) {
                            if let product = store.product(for: recipe.id) {
                                store.purchaseProduct(product)
                            }
                        }
                    }
                }
                .navigationBarItems(trailing: Button("Restore") {
                    store.retorePurchases()
                })
                .onAppear {
                    store.loadStoredPurchases()
                }
            }
            
            if !store.completedPurchases.isEmpty {
                AdView(adUnitID: "nil").frame(width: 320, height: 50)
            } else {
                AdView(adUnitID: AdUnitID.testAds).frame(width: 320, height: 50).padding([.top], 10)
            }
        }
        .navigationTitle("Shop")
    }
}
