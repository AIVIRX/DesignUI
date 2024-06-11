//
//  ColorPaletteGeneratorView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct ColorPaletteGeneratorView: View {
    @State private var color1 = Color.red
    @State private var color2 = Color.green
    @State private var color3 = Color.blue
    
    var body: some View {
        VStack {
            ColorRectangle(color: color1)
                .overlay{
                    VStack{
                        Text("RGB-1: \(color1.rgbString)").bold()
                            .shadow(color: .black, radius: 1)
                        Text("RGB-255: \(color1.rgbString255)").bold()
                            .shadow(color: .black, radius: 1)
                    }
                }
            
            ColorRectangle(color: color2)
                .overlay{
                    VStack{
                        Text("RGB-1: \(color2.rgbString)").bold()
                            .shadow(color: .black, radius: 1)
                        Text("RGB-255: \(color2.rgbString255)").bold()
                            .shadow(color: .black, radius: 1)
                    }
                }
            
            ColorRectangle(color: color3)
                .overlay{
                    VStack{
                        Text("RGB-1: \(color3.rgbString)").bold()
                            .shadow(color: .black, radius: 1)
                        Text("RGB-255: \(color3.rgbString255)").bold()
                            .shadow(color: .black, radius: 1)
                    }
                }
            
            Button(action: generateColors) {
                Text("Generate")
                    .padding(8)
                    .frame(width: 300)
                    .font(.system(size: 20))
                    .fontWeight(.black)
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
        }
        .navigationTitle("Pallete Generator")
    }
    
    func generateColors() {
        // Generate random colors
        color1 = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
        color2 = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
        color3 = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    }
}
