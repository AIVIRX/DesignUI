import SwiftUI
import FirebaseAuth
import FirebaseFirestore
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
    @State private var likesCount: Int = 0
    @State private var isLiking: Bool = false
    
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
                                if !isLiking {
                                    isLiking = true
                                    toggleLike()
                                }
                            }) {
                                if type == "fetched"{
                                    VStack{
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .foregroundColor(isLiked ? .red : .gray)
                                            .font(.title)
                                        Text("\(likesCount)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
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
            .onAppear(perform: fetchLikeStatus)
            }

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    func fetchLikeStatus() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userLikedPostRef = db.collection("users").document(user.uid).collection("likedPosts").document(id)
        
        userLikedPostRef.getDocument { likedDocument, error in
            if let likedDocument = likedDocument, likedDocument.exists {
                isLiked = true
            } else {
                isLiked = false
            }
            
            // Fetch the likes count from the post document
            let postRef = db.collection("CommunityPosts").document(id)
            postRef.getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data(), let likes = data["likesCount"] as? Int {
                        DispatchQueue.main.async {
                            self.likesCount = likes
                        }
                    }
                }
            }
        }
    }




    func toggleLike() {
            guard let user = Auth.auth().currentUser else { return }
            let db = Firestore.firestore()
            let postRef = db.collection("CommunityPosts").document(id)
            let userLikedPostRef = db.collection("users").document(user.uid).collection("likedPosts").document(id)
            
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let postDocument: DocumentSnapshot
                do {
                    postDocument = try transaction.getDocument(postRef)
                } catch let error as NSError {
                    print("Error getting post document: \(error)")
                    return nil
                }
                
                guard let oldLikesCount = postDocument.data()?["likesCount"] as? Int else {
                    return nil
                }
                
                if self.isLiked {
                    // Unlike the post
                    transaction.updateData(["likesCount": oldLikesCount - 1], forDocument: postRef)
                    transaction.deleteDocument(userLikedPostRef)
                } else {
                    // Like the post
                    transaction.updateData(["likesCount": oldLikesCount + 1], forDocument: postRef)
                    transaction.setData(["likedBy":user.uid], forDocument: userLikedPostRef)
                }
                
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    self.isLiked.toggle()
                    self.likesCount += self.isLiked ? 1 : -1
                }
                self.isLiking = false
            }
        }
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
