import SwiftUI
import AlertToast
import SDWebImage
import SDWebImageSwiftUI

struct DetailView: View {
    var id: String
    var mediaURL: String
    var title: String
    var description: String
    var author: String
    var codeSnippet: String
    var creationDate: String
    var type: String
    @Binding var isLiked: Bool
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    if type == "image" {
                        Image(mediaURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                    if type == "fetched" {
                        WebImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .clipped()
                            }
                        }
                    }
                
                    VStack(alignment: .leading) {
                        HStack {
                            Text(title)
                                .font(.title)
                                .bold()
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                isLiked.toggle()
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .gray)
                                    .font(.title)
                            }
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
                            .font(.headline).bold()
                            .background(Color.blue) // Button background color
                            .foregroundColor(.white) // Button text color
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    .padding(.top, 10)
                    
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                                .padding(8)
                                .font(.headline).bold()
                                .background(Color.blue) // Button background color
                                .foregroundColor(.white) // Button text color
                                .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity)
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
    }

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }


#Preview {
    DetailView(
        id: "722M",
        mediaURL: "String",
        title: "Design Template",
        description: "This is a placeholder for a design",
        author: "Aivirx",
        codeSnippet: """
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
               
               Text("")
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
                   .font(.headline).bold()
           }
           .buttonStyle(.borderedProminent)
           .foregroundStyle(Color.white)
           .clipShape(RoundedRectangle(cornerRadius: 12.0))
           .padding(.top, 10)
           
           Button(action: {
               showShareSheet = true
           }) {
               HStack {
                   Image(systemName: "square.and.arrow.up")
                   Text("Share")
                       .padding(8)
                       .frame(maxWidth: .infinity)
                       .font(.headline).bold()
               }
           }
           .buttonStyle(.borderedProminent)
           .foregroundStyle(Color.white)
           .clipShape(RoundedRectangle(cornerRadius: 12.0))
           .padding(.top, 10)
       }
    """,
        creationDate: "April 1, 2024",
        type: "image",
        isLiked: .constant(true)
    )
}
