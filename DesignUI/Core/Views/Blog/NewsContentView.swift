//
//  NewsContentView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import HighlightSwift

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
                    }
                case .paragraph:
                    if let text = block.text {
                        Text(text)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                case .image:
                    if let urlString = block.url, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .scaledToFill()
                        .cornerRadius(10)
                    }
                case .code:
                    if let code = block.code {
                        ScrollView {
                            VStack(alignment: .leading) {
                                CodeText(code)
                                    .highlightLanguage(.swift)
                                    .font(.system(size: 20))
                                    .textSelection(.enabled)
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                case .bulletedList:
                    if let items = block.items {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(items, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("•").bold()
                                        .foregroundColor(.primary)
                                    Text(item)
                                        .foregroundColor(.primary)

                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
