import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct DesignCards: View {
    var id: String
    var media: String
    var title: String
    var authorName: String
    var isVerified: Bool
    var description: String
    var codeSnippet: String
    var published: String
    var likesCount: Int
    var isLiked: Bool
    var namespace: Namespace.ID
    
    @State private var isHovered: Bool = false
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var isVisible = false
    @State private var showDetail = false
    let client = SupabaseManager.shared.client    
    @StateObject private var viewModel = LatestPostsViewModel()
    @State private var isLikedByUser: Bool = false
    @State private var userId: String? = nil

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showDetail = true
            }
        } label: {
            VStack(alignment: .center) {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .foregroundStyle(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .matchedGeometryEffect(id: "container\(id)", in: namespace)
                        .overlay{
                            RoundedRectangle(cornerRadius: 15)
                                .frame(width: 115,height: 250)
                                .overlay{
                                    WebImage(url: URL(string: media)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity, maxHeight: 350)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity, maxHeight: 250)
                                                .frame(maxWidth: .infinity, maxHeight: 370)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .clipped()
                                                .matchedGeometryEffect(id: "image\(id)", in: namespace)
                                                .shadow(radius: 8)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity, maxHeight: 250)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .clipped()
                                                .shadow(radius: 8)
                                        }
                                    }
                                }
                        }
                }
                // ... rest of your existing iPad and macOS code ...
#endif
                VStack(alignment: .leading) {
                    Text(title).bold()
                        .font(.system(size: 16))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                    
                    HStack {
                        Text(authorName)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        LikeButton(
                            postId: id,
                            initialLikeCount: likesCount
                        )
                    }
                    .padding(.bottom, 5)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 1)
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isVisible = true
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showDetail) {
            DetailView(
                id: id,
                mediaURL: media,
                title: title,
                description: description,
                author: authorName,
                codeSnippet: codeSnippet,
                creationDate: published,
                isAuthorVerified: isVerified,
                namespace: namespace
            )
        }
        
#if os(iOS)
        .simultaneousGesture(TapGesture().onEnded {
            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
            impactHeavy.impactOccurred()
        })
#endif
    }
} 