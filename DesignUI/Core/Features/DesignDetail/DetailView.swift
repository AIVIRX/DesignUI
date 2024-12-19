import SwiftUI
import Drops
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
    var isAuthorVerified: Bool
    
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var repostCount: Int = 0
    @State private var shareCount: Int = 0
    @State private var viewCount: Int = 0
    @State private var showReportAlert = false
    @Environment(\.colorScheme) var colorScheme
    @State private var isReporting: Bool = false
    @State private var isCurrentUserAuthor: Bool = false
    let client = SupabaseManager.shared.client
    @StateObject private var likeManager = LikeManager.shared
    @State private var likeCount: Int = 0
    @State private var isLiked: Bool = false
    var body: some View {
        ScrollView() {
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .foregroundStyle(.thinMaterial)
                        .overlay{
                            RoundedRectangle(cornerRadius: 15)
                                .frame(width: 115,height: 250)
                                .overlay{
                                    WebImage(url: URL(string: mediaURL)) { phase in
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
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .clipped()
                                                .shadow(radius: 8)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity, maxHeight: 250)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .clipped()
                                                .shadow(radius: 8)
                                        }
                                    }
                                }
                        }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment:.leading){
                                //author
                                HStack {
                                    Text("\(author)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 3)
                                    
                                    if isAuthorVerified{
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        //TagView(tags: tags)
                    }
                    Text(description)
                        .padding(.top)
                        .font(.body)
                    
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
                    
                    Spacer()
                    Button(action: {
                        copyToClipboard(codeSnippet)
                        isCopied = true
                        
#if os(iOS)
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
#endif
#if os(iOS)
                        let drop = Drop(
                            title: "Copied Code",
                            icon: UIImage(systemName: "doc.on.doc.fill"),
                            position: .bottom
                        )
                        
                        Drops.show(drop)
#endif
                    }) {
                        Text("Copy Code")
                            .padding(8)
                            .font(.headline).bold()
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    .padding(.top, 10)
                    
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
                            .frame(width:400)
                            .foregroundStyle(Color.gray.opacity(0.2))
                            .overlay{
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 257,height: 557)
                                    .overlay{
                                        WebImage(url: URL(string: mediaURL)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(maxWidth: .infinity, maxHeight: 558)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(maxWidth: .infinity, maxHeight: 558)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                                    .clipped()
                                                    .shadow(radius: 8)
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(maxWidth: .infinity, maxHeight: 558)
                                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                                    .clipped()
                                                    .shadow(radius: 8)
                                            }
                                        }
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
                                    Text("\(author)")
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
                                    .frame(maxHeight: 700, alignment: .top)
                                
                                Text("Code Snippet:")
                                    .font(.system(size: 25)).bold()
                                    .padding(.top,5)
                            }
                            ScrollView {
                                VStack(alignment: .leading) {
                                    Text(codeSnippet)
                                        .textSelection(.enabled)
                                        .font(.system(size: 20))
                                        .padding()
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            
                            Spacer()
                            
                            Button(action: {
                                copyToClipboard(codeSnippet)
                                isCopied = true
                                
#if os(iOS)
                                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                impactMed.impactOccurred()
#endif
#if os(iOS)
                                let drop = Drop(
                                    title: "Copied Code",
                                    icon: UIImage(systemName: "doc.on.doc.fill")
                                )
                                
                                Drops.show(drop)
#endif
                            }) {
                                Text("Copy Code")
                                    .padding(8)
                                    .font(.headline).bold()
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10.0))
                            .padding(.top, 10)
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
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(width:400)
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .overlay{
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: 257,height: 557)
                                .overlay{
                                    WebImage(url: URL(string: mediaURL)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity, maxHeight: 558)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity, maxHeight: 558)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .clipped()
                                                .shadow(radius: 8)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity, maxHeight: 558)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .clipped()
                                                .shadow(radius: 8)
                                        }
                                    }
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
                                
                                Spacer()
                                
                                Button {
                                    Task {
                                        try? await likeManager.toggleLike(postId: id)
                                        // Refresh like count after toggle
                                        await fetchLikeStatus()
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: likeManager.likedPosts.contains(id) ? "heart.fill" : "heart")
                                            .foregroundColor(likeManager.likedPosts.contains(id) ? .red : .gray)
                                            .font(.system(size: 24))
                                        
                                        Text(formatCount(likeCount))
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            HStack {
                                Text("\(author)")
                                    .font(.system(size: 15)).bold()
                                    .foregroundColor(.secondary)
                                
                                if isAuthorVerified{
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("Description:")
                                .font(.system(size: 25)).bold()
                                .padding(.top,5)
                            
                            Text(description)
                                .font(.system(size: 18))
                                .frame(maxHeight: 700, alignment: .top)
                            
                            Text("Code Snippet:")
                                .font(.system(size: 25)).bold()
                                .padding(.top,5)
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading) {
                                Text(codeSnippet)
                                    .textSelection(.enabled)
                                    .font(.system(size: 20))
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        Spacer()
                        
                        
                        Button(action: {
                            copyToClipboard(codeSnippet)
                            isCopied = true
                            
#if os(iOS)
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
#endif
#if os(iOS)
                            let drop = Drop(
                                title: "Copied Code",
                                icon: UIImage(systemName: "doc.on.doc.fill")
                            )
                            
                            Drops.show(drop)
#endif
                        }) {
                            Text("Copy Code")
                                .padding(8)
                                .font(.headline).bold()
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10.0))
                        .padding(.top, 10)
                    }
                }
                .frame(height: 700)
                
                SimilarPostsView(currentPostId: id)
            }
            .environment(\.symbolVariants, .none)
            .accentColor(.none)
            
            
#endif
        }
        .scrollIndicators(.hidden)
        
#if os(iOS)
        .navigationBarTitle(title)
#endif
        .padding(7)
        .task {
            await fetchLikeStatus()
        }
    }
    
    func copyToClipboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#endif
    }
    
    private func fetchLikeStatus() async {
            do {
                // Fetch like count
                let query = SupabaseManager.shared.client
                    .from("posts")
                    .select("like_count")
                    .eq("id", value: id)
                    .single()
                
                let result: [String: Int] = try await query.execute().value
                likeCount = result["like_count"] ?? 0
                
                // Check if current user has liked
                if let userId = AuthManager.shared.currentUser?.id {
                    let likeQuery = SupabaseManager.shared.client
                        .from("likes")
                        .select()
                        .eq("post_id", value: id)
                        .eq("user_id", value: userId)
                        .single()
                    
                    let _: Like? = try? await likeQuery.execute().value
                    isLiked = likeManager.likedPosts.contains(id)
                }
            } catch {
                print("Error fetching like status: \(error)")
            }
        }
}
