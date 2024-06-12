//
//  DetailView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
import SwiftUI
import AlertToast

struct DetailView: View {
    var id: String
    var mediaURL: String
    var title: String
    var description: String
    var author: String
    var codeSnippet: String
    var creationDate: String
    var type: DesignType
    @Binding var isLiked: Bool
    @State private var isCopied: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    if type == .image {
                        Image(mediaURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(title)
                                .font(.title)
                                .bold()
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text(creationDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("By \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Description:")
                        .font(.title2).bold()
                        .padding(.top)
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("Code Snippet:")
                        .font(.title2).bold()
                        .padding(.top)
                    
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text(codeSnippet)
                                .font(.body)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    
                    Button(action: {
                        copyToClipboard(codeSnippet)
                        isCopied = true
                    }) {
                        Text("Copy Code")
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .font(.headline).bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    .padding(.top, 10)
                }
                .toast(isPresenting: $isCopied) {
                    AlertToast(displayMode: .alert, type: .regular, title: "Code Copied ✅")
                }
            }
            .padding(7)
        }
        .cornerRadius(20)
    }

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

struct ScrollOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
