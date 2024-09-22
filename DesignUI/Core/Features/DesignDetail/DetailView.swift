import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Drops
import SDWebImage
import SDWebImageSwiftUI

struct DetailView: View {
    var id: String
    var mediaURL: String
    var title: String
    var description: String
    var author: String
    var authorUID: String
    var codeSnippet: String
    var creationDate: String
    var type: String
    var isAuthorVerified: Bool
    var tags: [String]
    @Binding var isLiked: Bool
    var likes: Int
    var views: Int
    var hexa: String
    var visibility: String
    
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var repostCount: Int = 0
    @State private var shareCount: Int = 0
    @State private var likesCount: Int = 0
    @State private var viewCount: Int = 0
    @State private var isLiking: Bool = false
    @State private var showReportAlert = false
    @State private var alertItem: AlertItem?
    @Environment(\.colorScheme) var colorScheme
    @State private var isReporting: Bool = false
    @State private var isEditing: Bool = false
    @State private var isCurrentUserAuthor: Bool = false
    @State private var reportMessage: String = ""
    var body: some View {
        ScrollView() {
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .foregroundStyle(Color(hex: hexa))
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
                                
                                if Auth.auth().currentUser != nil{
                                    Text("\(formatCount(viewCount)) views")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if type == "fetched" {
                                if Auth.auth().currentUser != nil{
                                    Button(action: {
                                        if !isLiking {
                                            isLiking = true
                                            toggleLike()
                                        }
                                    }) {
                                        VStack{
                                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                                .foregroundColor(isLiked ? .red : .gray)
                                                .font(.title)
                                            Text("\(formatCount(likesCount))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
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
                            icon: UIImage(systemName: "doc.on.doc.fill")
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
                    
                    HStack{
                        SimilarPostsView(currentPostId: id, tags: tags)
                    }
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
                                    if type == "fetched" {
                                        if Auth.auth().currentUser != nil{
                                            Button(action: {
                                                if !isLiking {
                                                    isLiking = true
                                                    toggleLike()
                                                }
                                            }) {
                                                VStack{
                                                    
                                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                                        .foregroundColor(isLiked ? .red : .gray)
                                                        .font(.title)
                                                    Text("\(formatCount(likesCount))")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                Text(creationDate)
                                    .font(.system(size: 15)).bold()
                                    .foregroundColor(.secondary)
                                
                                if Auth.auth().currentUser != nil{
                                    Text("\(formatCount(viewCount)) views")
                                        .font(.system(size: 15)).bold()
                                        .foregroundColor(.secondary)
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
                                
                                TagView(tags: tags)
                                
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
                    HStack{
                        SimilarPostsView(currentPostId: id, tags: tags)
                    }
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
                                if type == "fetched" {
                                    if Auth.auth().currentUser != nil{
                                        Button(action: {
                                            if !isLiking {
                                                isLiking = true
                                                toggleLike()
                                            }
                                        }) {
                                            VStack{
                                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                                    .foregroundColor(isLiked ? .red : .gray)
                                                    .font(.title)
                                                Text("\(formatCount(likesCount))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            Text(creationDate)
                                .font(.system(size: 15)).bold()
                                .foregroundColor(.secondary)
                            
                            if Auth.auth().currentUser != nil{
                                Text("\(formatCount(viewCount)) views")
                                    .font(.system(size: 15)).bold()
                                    .foregroundColor(.secondary)
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
                            
                            TagView(tags: tags)
                            
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
                
                HStack{
                    SimilarPostsView(currentPostId: id, tags: tags)
                }
            }
            .environment(\.symbolVariants, .none)
            .accentColor(.none)
#endif
        }
        .scrollIndicators(.hidden)
        
#if os(iOS)
        .navigationBarTitle(title)
        .navigationBarItems(trailing:
                                HStack{
            Button(action: {
                isReporting.toggle()
            }) {
                Label("Report", systemImage: "flag")
            }
            
            if checkIfAuthor(){
                Button(action: {
                    isEditing.toggle()
                }) {
                    Label("Edit", systemImage: "square.and.pencil")
                }
                .sheet(isPresented: $isEditing) {
                    EditPostView(id: id, title: title, description: description, codeSnippet: codeSnippet, tags: tags, hexa: hexa, visibility: visibility)
                }
            }
        })
        .sheet(isPresented: $isReporting) {
            VStack {
                Text("Report Content")
                    .font(.title).bold()
                Text("Are you sure you want to report this post?")
                    .font(.headline)
                    .padding(.bottom)
                
                Spacer()
                
                TextEditorWithCounter(label: "Message", text: $reportMessage, maxLength: 100)
                
                Spacer()
                
                Button {
                    reportPost(postId: id, message: reportMessage)
                    isReporting = false // Dismiss sheet
                } label: {
                    Text("Report")
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
            }
            .padding()
            .presentationDetents([.medium])
        }
#endif
        
#if os(macOS)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack{
                    Button(action: {
                        isReporting.toggle() // Show the custom sheet for reporting
                    }) {
                        Label("Report", systemImage: "flag")
                    }
                    
                    
                    if checkIfAuthor(){
                        Button(action: {
                            isEditing.toggle() // Toggle to present a sheet for message input
                        }) {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        .sheet(isPresented: $isEditing) {
                            EditPostView(id: id, title: title, description: description, codeSnippet: codeSnippet, tags: tags, hexa: hexa, visibility: visibility)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isReporting) {
            VStack {
                Text("Report Content")
                    .font(.headline)
                Text("Are you sure you want to report this post?")
                    .padding(.bottom)
                
                TextField("Optional Message", text: $reportMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                HStack {
                    Button("Cancel") {
                        isReporting = false // Dismiss the sheet without reporting
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Report") {
                        reportPost(postId: id, message: reportMessage)
                        isReporting = false // Dismiss the sheet after reporting
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .padding()
            .frame(width: 300)
        }
#endif
        .padding(7)
        .onAppear{
            fetchLikeStatusAndViewCount()
            incrementViewCount()
        }
    }
    
    func checkIfAuthor() -> Bool {
        guard let user = Auth.auth().currentUser else {
            return false
        }
        return user.uid == authorUID
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
    
    func fetchLikeStatusAndViewCount() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userLikedPostRef = db.collection("users").document(user.uid).collection("likedPosts").document(id)
        let postRef = db.collection("posts").document(id)
        
        // Use Firestore's batch to get both documents
        var isLikedStatus = false
        var likesCount = 0
        var viewCount = 0
        
        // Fetch user liked status and post details in parallel
        userLikedPostRef.getDocument { likedDocument, error in
            if let likedDocument = likedDocument, likedDocument.exists {
                isLikedStatus = true
            } else {
                isLikedStatus = false
            }
            
            postRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data() {
                        if let likes = data["likesCount"] as? Int {
                            likesCount = likes
                        }
                        if let views = data["viewCount"] as? Int {
                            viewCount = views
                        }
                    }
                }
                
                // Update UI on the main thread
                DispatchQueue.main.async {
                    self.isLiked = isLikedStatus
                    self.likesCount = likesCount
                    self.viewCount = viewCount
                }
            }
        }
    }
    
    func toggleLike() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(id)
        let userLikedPostRef = db.collection("users").document(user.uid).collection("likedPosts").document(id)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                postDocument = try transaction.getDocument(postRef)
            } catch let error as NSError {
                print("Error getting post document: \(error)")
                return nil
            }
            
            guard postDocument.data()?["likesCount"] is Int else {
                return nil
            }
            
            if self.isLiked {
                // Unlike the post
                transaction.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
                transaction.deleteDocument(userLikedPostRef)
            } else {
                // Like the post
                transaction.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: postRef)
                transaction.setData(["likedBy": user.uid, "timestamp": Timestamp(date: Date())], forDocument: userLikedPostRef)
            }
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.isLiked.toggle()
                    self.likesCount += self.isLiked ? 1 : -1
                    self.isLiking = false
                }
            }
        }
    }
    
    func incrementViewCount() {
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(id)
        
        postRef.updateData([
            "viewCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating view count: \(error)")
            } else {
                print("View count incremented successfully")
            }
        }
    }
    
    func reportPost(postId: String, message: String) {
        let db = Firestore.firestore()
        let reportData: [String: Any] = [
            "postId": postId,
            "message": message,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("reportedPosts").addDocument(data: reportData) { error in
            if let error = error {
                print("Error reporting post: \(error.localizedDescription)")
            } else {
                print("Post reported successfully")
            }
        }
    }
}

struct TagView: View {
    var tags: [String]
    var body: some View {
        if tags != [""]{
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text("\(tag)")
                        .font(.system(size: 13)).bold()
                        .padding(5)
                        .background(color(for: tag))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    func color(for tag: String) -> Color {
        switch tag {
        case "Template":
            return .gray
        case "UIKit":
            return .orange
        case "SwiftUI":
            return .red
        case "Animation":
            return .purple
        case "Component":
            return .blue
        default:
            return .gray
        }
    }
}
