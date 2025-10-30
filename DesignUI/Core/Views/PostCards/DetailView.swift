import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct DetailWebImage: View {
    let url: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(url: String, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 10, shadowRadius: CGFloat = 8) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        WebImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: width, height: height)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .clipped()
                    .shadow(radius: shadowRadius)
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .clipped()
                    .shadow(radius: shadowRadius)
            }
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
        .onDisappear {
            // Only clear memory cache when view disappears to prevent memory buildup
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                SDImageCache.shared.clearMemory()
            }
        }
    }
}

struct DetailView: View {
    let id: String
    let mediaURL: String
    let title: String
    let description: String
    let author: String
    let codeSnippet: String
    let creationDate: String
    let isAuthorVerified: Bool
    let isPremium: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager

    private var imageDimensions: (width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return (width: 115, height: 250, cornerRadius: 20)
        } else {
            return (width: 257, height: 557, cornerRadius: 20)
        }
#else
        return (width: 257, height: 557, cornerRadius: 20)
#endif
    }
    
    private var containerDimensions: (width: CGFloat, height: CGFloat) {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return (width: .infinity, height: 280)
        } else {
            return (width: 300, height: 600)
        }
#else
        return (width: 300, height: 600)
#endif
    }
    
    var body: some View {
        ScrollView{
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: containerDimensions.width)
                        .frame(height: containerDimensions.height)
                        .foregroundStyle(.thinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: imageDimensions.width, height: imageDimensions.height)
                                .overlay {
                                    DetailWebImage(
                                        url: mediaURL,
                                        width: imageDimensions.width,
                                        height: imageDimensions.height,
                                        cornerRadius: imageDimensions.cornerRadius,
                                        shadowRadius: 6
                                    )
                                }
                        }
                        .overlay{
                            VStack{
                                Spacer()
                                
                                HStack{
                                    Spacer()
                                    
                                    Text(author)
                                        .font(.subheadline).bold()
                                        .foregroundColor(.secondary)
                                        .padding(.top, 3)
                                    
                                    if isAuthorVerified{
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                            }
                        }
                    
                    Text(description)
                        .padding(.top)
                        .font(.body)
                    
                    LiveSyntaxHighlightedCode(
                        code: codeSnippet,
                        fontSize: 20,
                        maxHeight: 300
                    )
                                    
                    SimilarPostsView(currentPostId: id)
                        .padding(.vertical)
                }
                .environment(\.symbolVariants, .none)
                .accentColor(.none)
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                VStack(alignment: .leading) {
                    HStack{
                        RoundedRectangle(cornerRadius: 15)
                            .frame(maxWidth: .infinity)
                            .frame(width: containerDimensions.width)
                            .foregroundStyle(Color.gray.opacity(0.2))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: imageDimensions.width, height: imageDimensions.height)
                                    .overlay {
                                        DetailWebImage(
                                            url: mediaURL,
                                            width: imageDimensions.width,
                                            height: imageDimensions.height,
                                            cornerRadius: imageDimensions.cornerRadius,
                                            shadowRadius: 8
                                        )
                                    }
                            }
                        VStack{
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(title)
                                        .font(.system(size: 30))
                                        .bold()
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                HStack {
                                    Text(author)
                                        .font(.system(size: 15)).bold()
                                        .foregroundColor(.secondary)
                                    
                                    if isAuthorVerified{
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Text(description)
                                    .font(.system(size: 18))
                                    .frame(maxHeight: 100, alignment: .top)
                            }
                            
                            LiveSyntaxHighlightedCode(
                                code: codeSnippet,
                                fontSize: 20,
                                maxHeight: 600
                            )
                        }
                    }
                    .frame(height: 600)
                    SimilarPostsView(currentPostId: id)
                        .padding(.vertical)
                }
                .environment(\.symbolVariants, .none)
                .accentColor(.none)
            }
#endif
            
#if os(macOS)
            VStack(alignment: .leading) {
                HStack{
                    RoundedRectangle(cornerRadius: 20)
                        .frame(maxWidth: .infinity)
                        .frame(width: containerDimensions.width)
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: imageDimensions.width, height: imageDimensions.height)
                                .overlay {
                                    DetailWebImage(
                                        url: mediaURL,
                                        width: imageDimensions.width,
                                        height: imageDimensions.height,
                                        cornerRadius: imageDimensions.cornerRadius,
                                        shadowRadius: 8
                                    )
                                }
                        }
                    
                    VStack{
                        VStack(alignment: .leading) {
                            HStack {
                                Text(title)
                                    .font(.system(size: 30))
                                    .bold()
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            HStack {
                                Text(author)
                                    .font(.headline).bold()
                                    .foregroundColor(.secondary)
                                
                                if isAuthorVerified{
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(description)
                                .font(.title2)
                                .frame(maxHeight: 100)
                                .foregroundStyle(.secondary)
                        }
                        
                        LiveSyntaxHighlightedCode(
                            code: codeSnippet,
                            maxHeight: 600
                        )
                    }
                }
                .frame(height: 600)
                
                SimilarPostsView(currentPostId: id)
            }
            .padding(.vertical)
            .environment(\.symbolVariants, .none)
            .toolbar {
                ToolbarItem() {
                    ShareLink(item: URL(string: "https://dockui.com/templates/\(id)")!)
                }
            }
#endif
        }
        .scrollIndicators(.hidden)
#if os(iOS)
        .toolbar {
            ShareLink(item: URL(string: "https://dockui.com/templates/\(id)")!)
        }
        .navigationBarTitle(title)
#endif
        .padding(.horizontal, 7)
        .overlay(
            Group {
                if isPremium && !subscriptionManager.isSubscribed {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: 16) {
                            Text("Premium Template")
                                .font(.title2).bold()
                            Text("Subscribe to access this template.")
                                .foregroundColor(.secondary)
                            Button("Subscribe") {
                                paywallManager.present()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        )
    }
}

