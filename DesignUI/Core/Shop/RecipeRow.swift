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
        HStack{
            HStack(alignment: .center){
                ZStack{
                    Image(recipe.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(9)
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
                        .font(.title)
                        .bold()
                    Text(recipe.description)
                        .font(.caption)
#if os(macOS)
                        .font(.title)
#endif
                }
                Spacer()
                
                if let price = recipe.price, recipe.isLocked{
                    Button(action: action, label: {
                        Text(price)
                            .foregroundColor(.white)
                            .padding([.leading, .trailing])
                            .padding([.top, .bottom], 5)
                            .background(Color.black)
                            .cornerRadius(25)
                    })
                    .padding()
                }
            }
        }
#if os(macOS)
        .background(.gray.opacity(0.2))
        .cornerRadius(9)
#endif
    }
}
