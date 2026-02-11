import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct DetailWebImage: View {
    let url: String
    
    init(url: String) {
        self.url = url
    }
    
    var body: some View {
        WebImage(url: URL(string: url)) { image in
                image
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .padding()
        } placeholder: {
            ProgressView()
                .frame(width: 30, height: 30)
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
    var description: String = ""  // Optional - will be fetched if empty
    let author: String
    var codeSnippet: String = "" // Optional - will be fetched if empty
    let isPremium: Bool
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @State private var authorProfile: Profile?
    @State private var isLoadingProfile = false
    @State private var loadedDescription: String?
    @State private var loadedCodeSnippet: String?
    @State private var isLoadingDetails = false
    private let supabase = SupabaseManager.shared.client
    
    var body: some View {
        ScrollView {
            VStack{
                VStack{
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.2))
                            .frame(maxWidth: .infinity)
#if os(iOS)
                            .frame(height: 300)
#else
                            .frame(height: 450)
#endif
                            .overlay(
                                DetailWebImage(
                                    url: mediaURL
                                )
                            )
                            .overlay(alignment: .bottomTrailing) {
                                LikeButton(postId: id)
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .padding(12)
                            }
                    
                    
                    Text(loadedDescription ?? description)
#if os(iOS)
                        .font(.body)
#else
                        .font(.title2)
#endif
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider().padding(.vertical,5)
                    
                    // Show loading indicator or code snippet
                    if isLoadingDetails {
                        HStack {
                            ProgressView()
                            Text("Loading code...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                    } else {
                        LiveSyntaxHighlightedCode(
                            code: loadedCodeSnippet ?? codeSnippet,
                            fontSize: 20,
                            maxHeight: 300
                        )
                    }
                    
                    SimilarPostsView(currentPostId: id)
                        .padding(.vertical)
                }
                .frame(maxWidth: 900, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 40)
                .task {
                    await fetchAuthorProfile()
                    await fetchPostDetailsIfNeeded()
                }
            }
            .frame(maxWidth: .infinity)
            .navigationTitle(title)
        }
        .toolbar {
            ToolbarItem {
                HStack {
                    ShareLink(item: URL(string: "https://dockui.com/templates/\(slug)")!) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .padding(.horizontal,3)

            }
        }
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
    
    private func fetchPostDetailsIfNeeded() async {
        // Fetch if code snippet OR description is missing.
        // Also fetch if we haven't loaded them yet.
        let needsFetch = (codeSnippet.isEmpty && loadedCodeSnippet == nil) || 
                        (description.isEmpty && loadedDescription == nil)
        
        guard needsFetch else { return }
        
        await MainActor.run {
            isLoadingDetails = true
        }
        
        do {
            let fullPost = try await PostFetcher.fetchPostDetails(id: id)
            
            await MainActor.run {
                loadedDescription = fullPost.description
                loadedCodeSnippet = fullPost.code_snippet
                isLoadingDetails = false
            }
        } catch {
            print("Error fetching post details: \(error.localizedDescription)")
            await MainActor.run {
                isLoadingDetails = false
                // Optionally set an error state here to show in UI
                // self.error = error
                // Fallback: loadedDescription = "Could not load details."
            }
        }
    }
}
