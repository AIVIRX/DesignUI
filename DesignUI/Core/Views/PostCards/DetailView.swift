import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct DetailWebImage: View {
    let url: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let isComponent: Bool
    
    init(url: String, width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 10, shadowRadius: CGFloat = 4, isComponent: Bool) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.isComponent = isComponent
    }
    
    var body: some View {
        WebImage(url: URL(string: url)) { image in
            if !isComponent{
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .clipped()
                    .shadow(radius: shadowRadius)
            } else {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(15)
                    .shadow(radius: shadowRadius)
            }
        } placeholder: {
            ProgressView()
                .frame(width: width, height: height)
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
    }
}

struct DetailView: View {
    let id: String
    let slug: String
    let mediaURL: String
    let title: String
    let description: String
    let author: String
    let codeSnippet: String
    let creationDate: String
    let isAuthorVerified: Bool
    let isPremium: Bool
    let isComponent: Bool
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
        return (width: 180, height: 390, cornerRadius: 20)
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
        ScrollView {
            VStack{
                VStack{
                    if isComponent {
                        DetailWebImage(
                            url: mediaURL,
                            width: imageDimensions.width,
                            height: imageDimensions.height,
                            cornerRadius: imageDimensions.cornerRadius,
                            shadowRadius: 10,
                            isComponent: isComponent
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.2))
                            .frame(maxWidth: .infinity)
#if os(iOS)
                            .frame(height: 350)
#else
                            .frame(height: 450)
#endif
                            .overlay(
                                DetailWebImage(
                                    url: mediaURL,
                                    width: imageDimensions.width,
                                    height: imageDimensions.height,
                                    cornerRadius: imageDimensions.cornerRadius,
                                    shadowRadius: 10,
                                    isComponent: isComponent
                                )
                            )
                    }
                    
                    Text(description)
#if os(iOS)
                        .font(.body)
#else
                        .font(.title2)
#endif
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    LiveSyntaxHighlightedCode(
                        code: codeSnippet,
                        fontSize: 20,
                        maxHeight: 300
                    )
                    
                    SimilarPostsView(currentPostId: id)
                        .padding(.vertical)
                }
                .frame(maxWidth: 900, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 40)
                .task {
                    await fetchAuthorProfile()
                }
            }
            .frame(maxWidth: .infinity)
            .navigationTitle(title)
        }
#if os(iOS)
        .toolbar {
            ShareLink(item: URL(string: "https://dockui.com/templates/\(slug)")!)
        }
#else
        .toolbar {
            ToolbarItem {
                ShareLink(item: URL(string: "https://dockui.com/templates/\(slug)")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
#endif
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

