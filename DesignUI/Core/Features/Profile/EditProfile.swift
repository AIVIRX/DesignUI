//
//  EditProfile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/14/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage
import SDWebImageSwiftUI

struct EditProfileView: View {
    @EnvironmentObject var userStore: UserStore
    #if os(iOS)
    @State private var selectedImage: UIImage?
    #endif
    
    #if os(macOS)
    @State private var selectedImage: NSImage?
    #endif
    
    #if os(macOS)
    func presentImagePicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [.png, .jpeg, .bmp, .gif, .tiff]
        openPanel.allowsMultipleSelection = false
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url, let image = NSImage(contentsOf: url) {
                selectedImage = image
            }
        }
    }
    #endif
    
    @State private var showImagePicker = false
    @State private var currentImageURL: String = ""
    @State private var newImageURL: String = ""
    @State private var newDisplayName: String
    @State private var initialDisplayName: String
    @State private var isLoading: Bool = false
    @State private var newBio: String
    @State private var initialBio: String
    @State private var newUsername: String
    @State private var initialUsername: String
    @State private var isUsernameValid: Bool = true
    @State private var isUsernameUnique: Bool = true
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    init(displayName: String, bio: String, username: String) {
        self._newDisplayName = State(initialValue: displayName)
        self._initialDisplayName = State(initialValue: displayName)
        self._newBio = State(initialValue: bio)
        self._initialBio = State(initialValue: bio)
        self._newUsername = State(initialValue: username)
        self._initialUsername = State(initialValue: username)
    }
    var body: some View {
        VStack {
            HStack{
                Spacer()
                
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark.circle")
                        .font(.title)
                        .foregroundStyle(.gray)
                })
            }
            ZStack {
                if let selectedImage = selectedImage {
                    #if os(iOS)
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                    #endif
                    
                    #if os(macOS)
                    Image(nsImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                    #endif
                } else if !currentImageURL.isEmpty {
                    WebImage(url: URL(string: currentImageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 160, height: 130)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                                .shadow(radius: 10)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                                .shadow(radius: 10)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 100, height: 100)
                }
                
                Circle()
                    .opacity(0)
                    .frame(width: 100, height: 100)
                    .contentShape(Circle()) // Makes the entire circle tappable
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
                    .onTapGesture {
                        #if os(iOS)
                        showImagePicker = true
                        #elseif os(macOS)
                        presentImagePicker()
                        #endif
                    }
            }
            
            if isLoading {
                ProgressView()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            TextFieldWithCounter(placeholder: "Name", text: $newDisplayName, maxLength: 15)
            TextFieldWithValidation(placeholder: "Username", text: $newUsername, maxLength: 15, isValid: $isUsernameValid, isUnique: $isUsernameUnique)
                .onChange(of: newUsername) {
                    validateUsernameFormat()
                }
            TextEditorWithCounter(label: "Bio", text: $newBio, maxLength: 80)
            
            Spacer()
            
            Button(action: {
                validateAndSaveProfile()
            }) {
                Text(isLoading ? "Saving..." : "Save Changes")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoading || !isUsernameValid || !isUsernameUnique || (newDisplayName == initialDisplayName && newBio == initialBio && newUsername == initialUsername && selectedImage == nil) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading || !isUsernameValid || !isUsernameUnique || (newDisplayName == initialDisplayName && newBio == initialBio && newUsername == initialUsername && selectedImage == nil))
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .frame(width: 500)
        #endif
        .padding()
        .sheet(isPresented: $showImagePicker, content: {
                #if os(iOS)
                ImagePicker(selectedImage: $selectedImage, onImagePicked: { _ in })
                #endif
            })
        .onAppear {
            fetchProfileImage()
        }
    }
    
    func fetchProfileImage() {
        guard let user = userStore.user else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.id)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                self.currentImageURL = document.get("imageURL") as? String ?? ""
            }
        }
    }
    
    func validateAndSaveProfile() {
        validateUsernameUniqueness { isUnique in
            if isUnique {
#if os(iOS)
                saveProfile()
                #endif
                
#if os(macOS)
                saveProfile()
                #endif
            } else {
                isUsernameUnique = false
                errorMessage = "Username is already taken."
            }
        }
    }

    func validateUsernameFormat() {
        let usernameRegex = "^[a-zA-Z0-9_]{1,15}$"
        isUsernameValid = NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: newUsername)
    }

    func validateUsernameUniqueness(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: newUsername).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking username uniqueness: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                isUsernameUnique = snapshot.documents.first?.documentID == userStore.user?.id
            } else {
                isUsernameUnique = true
            }
            
            completion(isUsernameUnique)
        }
    }

    func saveProfile() {
        guard let user = userStore.user else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.id)
        
        isLoading = true
        
        let cleanedBio = removeBlankLines(from: newBio)
        
        var updates: [String: Any] = [
            "displayName": newDisplayName,
            "bio": cleanedBio,
            "username": newUsername
        ]
        
        // Handle image upload if a new image is selected
        if let selectedImage = selectedImage {
            let uniqueImageID = UUID().uuidString
            let storageRef = Storage.storage().reference().child("users/\(user.id)/profile/\(uniqueImageID).jpg")
            
            var imageData: Data?
            
            #if os(iOS)
            imageData = selectedImage.jpegData(compressionQuality: 0.75)
            #elseif os(macOS)
            if let tiffData = selectedImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData) {
                imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.75])
            }
            #endif
            
            guard let finalImageData = imageData else { return }
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(finalImageData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }
                    
                    if let url = url {
                        self.newImageURL = url.absoluteString
                        updates["imageURL"] = self.newImageURL
                        self.updateFirestore(userDocRef: userDocRef, updates: updates)
                    }
                }
            }
        } else {
            updateFirestore(userDocRef: userDocRef, updates: updates)
        }
    }

    func updateFirestore(userDocRef: DocumentReference, updates: [String: Any]) {
        userDocRef.updateData(updates) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                if let newImageURL = updates["imageURL"] as? String {
                    // Delete the previous image if the image URL has changed
                    if !self.currentImageURL.isEmpty {
                        let previousImageRef = Storage.storage().reference(forURL: self.currentImageURL)
                        previousImageRef.delete { error in
                            if let error = error {
                                print("Error deleting previous image: \(error.localizedDescription)")
                            }
                        }
                    }
                    self.currentImageURL = newImageURL
                }
                print("Profile updated successfully")
                // Update the local user data
                userStore.fetchUserData(uid: userStore.user?.id ?? "") { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
            self.isLoading = false
        }
    }
    
    func removeBlankLines(from text: String) -> String {
        let lines = text.split(separator: "\n")
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return nonEmptyLines.joined(separator: "\n")
    }
}







#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                parent.onImagePicked(uiImage)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
#endif

#if os(macOS)
struct ImagePicker: NSViewControllerRepresentable {
    @Binding var selectedImage: NSImage?
    var onImagePicked: (NSImage) -> Void
    
    class Coordinator: NSObject, NSOpenSavePanelDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func panel(_ sender: Any, didChangeToDirectoryURL url: URL?) {
            // Called when the panel's directory is changed
        }
        
        func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
            return true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.delegate = context.coordinator
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.allowedContentTypes = [.png, .jpeg, .bmp, .gif, .tiff]
            openPanel.allowsMultipleSelection = false
            openPanel.begin { response in
                if response == .OK, let url = openPanel.url, let image = NSImage(contentsOf: url) {
                    selectedImage = image
                    onImagePicked(image)
                    openPanel.close() // Close the window after selecting an image
                } else {
                    openPanel.close() // Also close the window if the selection was cancelled
                }
            }
        }
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif




#Preview {
    EditProfileView(displayName: "John Doe", bio: "Software Programmer Living In New York City", username: "john_doe")
}
