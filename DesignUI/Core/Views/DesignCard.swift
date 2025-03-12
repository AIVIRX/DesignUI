import SwiftUI
import SDWebImageSwiftUI

struct DesignCard: View {
    let id: String
    let mediaURL: String
    let title: String
    let author: String
    let isAuthorVerified: Bool
    var namespace: Namespace.ID
    @State private var isDetailPresented = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isDetailPresented = true
            }
        } label: {
            VStack {
                RoundedRectangle(cornerRadius: 15)
                    .frame(height: 280)
                    .foregroundStyle(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: 115, height: 250)
                            .overlay {
                                WebImage(url: URL(string: mediaURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity, maxHeight: 250)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .matchedGeometryEffect(id: "image\(id)", in: namespace)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    }
                                }
                            }
                    }
                    .matchedGeometryEffect(id: "container\(id)", in: namespace)
                
                HStack {
                    Text(author)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    if isAuthorVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isDetailPresented) {
            DetailView(
                id: id,
                mediaURL: mediaURL,
                title: title,
                description: "", // Add other required properties
                author: author,
                codeSnippet: "",
                creationDate: "",
                isAuthorVerified: isAuthorVerified,
                namespace: namespace
            )
        }
    }
} 