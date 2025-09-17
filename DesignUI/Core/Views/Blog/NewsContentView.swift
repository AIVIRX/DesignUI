//
//  NewsContentView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import HighlightSwift
import SDWebImage
import SDWebImageSwiftUI

struct NewsContentView: View {
    let blocks: [NewsBlock]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(blocks) { block in
                switch block.type {
                case .heading:
                    if let text = block.text {
                        Text(text)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.top)
                    }
                case .paragraph:
                    if let text = block.text {
                        Text(text)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                case .image:
                    if let urlString = block.url, let url = URL(string: urlString) {
                        WebImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill()
                                    .cornerRadius(12)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            @unknown default:
                                Color.gray.opacity(0.2)
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                    .cornerRadius(12)
                            }
                        }
                    }
                case .code:
                    if let code = block.code {
                        LiveSyntaxHighlightedCode(
                            code: code,
                            maxHeight: 300
                        )
                    }
                case .bulletedList:
                    if let items = block.items {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(items, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(item)
                                }
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
