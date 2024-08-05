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
            // Card
            VStack {
                // Horizontal stack for buttons
                HStack {
                    NavigationLink(destination: SFIconsView()) {
                        VStack{
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 20))
                                .padding()
                                .foregroundColor(.primary)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .fill(.thinMaterial)
                                )
                            
                            Text("Symbols")
                                .font(.body)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: SFIconsView()) {
                        VStack{
                            Image(systemName: "square.dashed.inset.fill")
                                .font(.system(size: 20))
                                .padding()
                                .foregroundColor(.primary)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .fill(.thinMaterial)
                                )
                            
                            Text("App Icon")
                                .font(.body)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button {
                        showPaywall = true
                    } label: {
                        VStack{
                            Image(systemName: "cart")
                                .font(.system(size: 20))
                                .padding()
                                .foregroundColor(.primary)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .fill(.thinMaterial)
                                )
                            
                            Text("Premium")
                                .font(.body)
                                .foregroundStyle(Color.primary)
                        }
                        .sheet(isPresented: $showPaywall){
                            StoreView()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(.thinMaterial)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
    }
}


#Preview {
    QuickActionCard()
}
