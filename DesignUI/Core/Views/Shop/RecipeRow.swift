//
//  RecipeRow.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct RecipeRow: View {
    var recipe: Recipe
    let action: () -> Void
    var body: some View {
        Button(action: action, label: {
            HStack{
                HStack(alignment: .center){
                    ZStack{
                        Image(recipe.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                            .opacity(recipe.isLocked ? 0.8 : 1)
                            .blur(radius: recipe.isLocked ? 3.0 : 0)
                            .padding()
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .opacity(recipe.isLocked ? 1 : 0)
                    }
                    Spacer()
                    VStack(alignment: .center){
                        Text(recipe.title)
                            .font(.title2)
                            .bold()
                        Text(recipe.description)
                            .font(.caption)
#if os(macOS)
                            .font(.title)
#endif
                    }
                    
                    Spacer()
                    
                    if let price = recipe.price, recipe.isLocked{
                        Text(price)
                            .foregroundColor(.white)
                            .padding([.leading, .trailing], 5)
                            .padding([.top, .bottom], 5)
                            .background(Color.black)
                            .cornerRadius(15)
                            .padding()
                    }
                }
            }
#if os(macOS)
            .background(.gray.opacity(0.2))
            .cornerRadius(10)
#endif
            .contentShape(Rectangle())
        })
    }
}
