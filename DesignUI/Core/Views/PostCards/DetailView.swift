import SwiftUI
import HighlightSwift
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
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    @State private var toast: ToastData?

    var body: some View {
        ScrollView{
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
                                                .shadow(radius: 6)
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
                        .overlay{
                            VStack{
                                Spacer()
                                
                                HStack{
                                    Spacer()
                                    
                                    Text("@\(author)")
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
                    
                    Text("Code Snippet:")
                        .font(.title2).bold()
                        .padding(.top)
                    
                    AsyncCodeText(codeSnippet: codeSnippet)
                        .font(.body)
                    
                    Spacer()
                    
                    Button(action: {
                        copyToClipboard(codeSnippet)
                        HapticManager.shared.triggerImpact(style: .medium)
                        
#if os(iOS)
                        toast = ToastData(
                            title: "Copied",
                            icon: .sfSymbol(name: "document.on.document", color: .gray),
                            duration: 3.0
                        )
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
                                    Text("@\(author)")
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
                            
                            AsyncCodeText(codeSnippet: codeSnippet)
                                .font(.body)
                            
                            Spacer()
                            
                            Button(action: {
                                copyToClipboard(codeSnippet)
                                
                                HapticManager.shared.triggerImpact(style: .medium)
#if os(iOS)
                                toast = ToastData(
                                    title: "Copied",
                                    icon: .sfSymbol(name: "document.on.document", color: .gray),
                                    duration: 3.0
                                )
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
                        .frame(width:300)
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .overlay{
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: 257, height: 557)
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
                                
                            }
                            
                            HStack {
                                Text("@\(author)")
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
                        
                        AsyncCodeText(codeSnippet: codeSnippet)
                            .font(.body)
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard(codeSnippet)
#if os(iOS)
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
#endif
#if os(iOS)
                            toast = ToastData(
                                title: "Copied",
                                icon: .sfSymbol(name: "document.on.document", color: .gray),
                                duration: 3.0
                            )
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
            }
            .padding(.vertical)
            .environment(\.symbolVariants, .none)
            .accentColor(.none)
            .toolbar {
                ToolbarItem() {
                    ShareLink(item: URL(string: "https://dockui.com/p/\(id)")!)
                }
            }
#endif
        }
        .scrollIndicators(.hidden)
        .toast($toast)
        
#if os(iOS)
        .toolbar {
            ShareLink(item: URL(string: "https://dockui.com/p/\(id)")!)
        }
        .navigationBarTitle(title)
#endif
        .padding(.horizontal, 7)
    }
    
    func copyToClipboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#endif
        if !hasRequestedReview {
            requestReview()
            hasRequestedReview = true
        }
    }
}

struct AsyncCodeText: View {
    let codeSnippet: String
    @State private var isLoaded: Bool = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                ScrollView {
                    VStack(alignment: .leading) {
                        CodeText(codeSnippet)
                            .highlightLanguage(.swift)
                            .font(.system(size: 20))
                            .textSelection(.enabled)
                            .padding()
                    }
                }
                if isLoaded {
                    CodeText(codeSnippet)
                        .highlightLanguage(.swift)
                        .font(.body)
                        .padding()
                } else {
                    ProgressView()
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                // Simulate processing delay (optional)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoaded = true
                }
            }
        }
    }
}


