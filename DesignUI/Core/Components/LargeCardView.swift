//
//  LargeCardView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct LargeCardView<Destination: View>: View {
    @State private var animate = false
    var destination: Destination
    var name: String
    var body: some View {
        NavigationLink(destination: destination){
            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.indigo)
                        .blur(radius: 20)
                        .offset(x: animate ? -120 : 10,y :animate ? -100 : 20)
                        .rotation3DEffect(.degrees(animate ? 80 : 20), axis: (x: animate ? 0.4 : 0, y: animate ? 0 : 0.1, z: animate ? 0 : 0.5))
                    Rectangle()
                        .fill(.blue)
                        .blur(radius: 30)
                        .offset(x: animate ? -60 : 20,y: animate ? 5 : 140)
                        .rotation3DEffect(.degrees(animate ? 20 : 50), axis: (x: animate ? 0 : 0, y: animate ? 0.4 : 0.2, z: animate ? 0.9 : 0.3))
                    Capsule()
                        .fill(.mint)
                        .blur(radius: 40)
                        .offset(x: animate ? 60 : 0,y: animate ? -10 : 140)
                        .rotation3DEffect(.degrees(animate ? -30 : 0), axis: (x: animate ? 0.6 : 0.1, y: animate ? 0.2 : 0.3, z: animate ? 0.1 : 0.4))
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.mint)
                        .blur(radius: 60)
                        .offset(x: animate ? -90 : 40,y:animate ? 90 : -20)
                        .rotation3DEffect(.degrees(animate ? -20 : 10), axis: (x: animate ? 0 : 0.2, y: animate ? 0 : 0 , z: animate ? 0.4 : 0))
                    Capsule()
                        .fill(.indigo)
                        .blur(radius: 70)
                        .offset(x: animate ? 10 : 170 ,y:animate ? 0 : -150)
                        .opacity(0.4)
                        .rotation3DEffect(.degrees(animate ? 30 : 0), axis: (x: animate ? 0 : 0.1, y: animate ? 0.5 : 0.1, z: animate ? 0.2 : 0.6))
                    
                    VStack() {
                        HStack{
                            VStack(alignment:.center) {
                                Text(name)
                                    .bold()
                                    .font(.system(size: 30, weight: .heavy))
                            }
                        }.padding()
                    }
                    .foregroundColor(.white)
                    
                }
                .frame(width: 250,height: 100)
                .clipped()
                .cornerRadius(15)
                .padding(.leading, 3)
                .onAppear() {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    }
                }
            }
        }
    }
}

