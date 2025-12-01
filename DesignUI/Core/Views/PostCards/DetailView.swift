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
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    
    @State private var authorProfile: Profile?
    @State private var isLoadingProfile = false
    private let supabase = SupabaseManager.shared.client

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
                                        .textSelection(.disabled)
                                    
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
                    
                    // Author Profile Section
                    AuthorProfileSection(
                        profile: authorProfile,
                        isLoading: isLoadingProfile,
                        username: author
                    )
                    .padding(.vertical)
                }
                .environment(\.symbolVariants, .none)
                .accentColor(.none)
                .task {
                    await fetchAuthorProfile()
                }
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
                                        .textSelection(.disabled)
                                    
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
                    
                    // Author Profile Section
                    AuthorProfileSection(
                        profile: authorProfile,
                        isLoading: isLoadingProfile,
                        username: author
                    )
                    .padding(.vertical)
                }
                .environment(\.symbolVariants, .none)
                .accentColor(.none)
                .task {
                    await fetchAuthorProfile()
                }
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
                                    .textSelection(.disabled)
                                
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
                    .padding(.bottom, 20)
                
                // Author Profile Section
                AuthorProfileSection(
                    profile: authorProfile,
                    isLoading: isLoadingProfile,
                    username: author
                )
                .padding(.bottom, 20)
            }
            .padding(.vertical)
            .environment(\.symbolVariants, .none)
            .task {
                await fetchAuthorProfile()
            }
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
    
    private func fetchAuthorProfile() async {
        guard !isLoadingProfile, authorProfile == nil else { return }
        isLoadingProfile = true
        
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: author)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let profile = try decoder.decode(Profile.self, from: response.data)
            
            await MainActor.run {
                self.authorProfile = profile
                self.isLoadingProfile = false
            }
        } catch {
            print("Error fetching author profile: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingProfile = false
            }
        }
    }
}

// MARK: - Author Profile Section
struct AuthorProfileSection: View {
    let profile: Profile?
    let isLoading: Bool
    let username: String
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.top, 8)
            
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading profile...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else {
                HStack(spacing: 12) {
                    // Profile Picture
                    Group {
                        if let avatarUrl = profile?.avatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                            WebImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 50, height: 50)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Circle()
                                        .fill(Color.blue.opacity(0.8))
                                        .overlay(
                                            Text(profile?.display_name?.prefix(1).uppercased() ?? username.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.blue.opacity(0.8))
                                        .overlay(
                                            Text(profile?.display_name?.prefix(1).uppercased() ?? username.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(profile?.display_name?.prefix(1).uppercased() ?? username.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // Name and Username
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(profile?.display_name ?? username)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if profile?.verified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

