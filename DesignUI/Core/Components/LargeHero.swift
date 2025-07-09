//
//  LargeHero.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/8/25.
//

import SwiftUI

struct LargeHero: View {
    @State private var animate: Bool = false
    var name: String
    var description: String
    var height: Double
    var padding: Double
    var colors: [Color]
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors[0])
                    .blur(radius: 20)
                    .offset(x: animate ? -120 : 10,y :animate ? -100 : 20)
                    .rotation3DEffect(.degrees(animate ? 80 : 20), axis: (x: animate ? 0.4 : 0, y: animate ? 0 : 0.1, z: animate ? 0 : 0.5))
                Rectangle()
                    .fill(colors[1])
                    .blur(radius: 30)
                    .offset(x: animate ? -60 : 20,y: animate ? 5 : 140)
                    .rotation3DEffect(.degrees(animate ? 20 : 50), axis: (x: animate ? 0 : 0, y: animate ? 0.4 : 0.2, z: animate ? 0.9 : 0.3))
                Capsule()
                    .fill(colors[2])
                    .blur(radius: 40)
                    .offset(x: animate ? 60 : 0,y: animate ? -10 : 140)
                    .rotation3DEffect(.degrees(animate ? -30 : 0), axis: (x: animate ? 0.6 : 0.1, y: animate ? 0.2 : 0.3, z: animate ? 0.1 : 0.4))
                RoundedRectangle(cornerRadius: 10)
                    .fill(colors[3])
                    .blur(radius: 60)
                    .offset(x: animate ? -90 : 40,y:animate ? 90 : -20)
                    .rotation3DEffect(.degrees(animate ? -20 : 10), axis: (x: animate ? 0 : 0.2, y: animate ? 0 : 0 , z: animate ? 0.4 : 0))
                Capsule()
                    .fill(colors[4])
                    .blur(radius: 70)
                    .offset(x: animate ? 10 : 170 ,y:animate ? 0 : -150)
                    .opacity(0.4)
                    .rotation3DEffect(.degrees(animate ? 30 : 0), axis: (x: animate ? 0 : 0.1, y: animate ? 0.5 : 0.1, z: animate ? 0.2 : 0.6))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                    Text("Discover the latest tutorials, tips, and stories.")
                        .foregroundColor(.white.opacity(0.92))
                        .font(.body)
                        .shadow(color: Color.black.opacity(0.10), radius: 1, x: 0, y: 1)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: height)
            .clipped()
            .cornerRadius(15)
            .padding(padding)
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
    }
}
