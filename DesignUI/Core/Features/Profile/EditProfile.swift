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
import Supabase

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
    @State private var newDisplayName = ""
    @State private var isLoading: Bool = false
    @State private var newBio = ""
    @State private var newUsername = ""
    @State private var isUsernameValid: Bool = false
    @State private var isUsernameUnique: Bool = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    var body: some View {
        VStack {
            if let profile = userViewModel.profile {
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
                    .onAppear {
                        self.newDisplayName = profile.display_name // Use profile data to prefill
                    }
                TextFieldWithValidation(placeholder: "Username", text: $newUsername, maxLength: 15, isValid: $isUsernameValid, isUnique: $isUsernameUnique)
                    .onAppear {
                        self.newUsername = profile.username // Use profile data to prefill
                    }
                    .onChange(of: newUsername) {
                        validateUsernameFormat()
                    }
                TextEditorWithCounter(label: "Bio", text: $newBio, maxLength: 80)
                    .onAppear {
                        self.newBio = profile.bio // Use profile data to prefill
                    }
                Spacer()
                
                Button(action: {
                    validateAndSaveProfile()
                }) {
                    Text(isLoading ? "Saving..." : "Save Changes")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isUsernameValid && isUsernameUnique ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isUsernameValid && isUsernameUnique)
            }
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
            Task {
                fetchProfileData() // Fetch profile data on view appearance
            }
        }
    }
    
    func fetchProfileData() {
        Task {
            do {
                let session = try await client.auth.session
                let userId = session.user.id.uuidString
                
                // Fetch the profile data from Supabase
                let profileData = try await userViewModel.fetchProfileFromBackend(userId: userId)
                
                DispatchQueue.main.async {
                    newDisplayName = profileData.display_name
                    newBio = profileData.bio
                    newUsername = profileData.username
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveProfile() {
        Task {
            guard let session = try? await client.auth.session else {
                errorMessage = "User session not available"
                return
            }
            
            isLoading = true
            errorMessage = nil
            
            let userId = session.user.id.uuidString
            let cleanedBio = removeBlankLines(from: newBio)
            
            // Explicitly type the values in the dictionary as String or conforming types
            var updates: [String: String] = [
                "display_name": newDisplayName,
                "bio": cleanedBio,
                "username": newUsername.lowercased()
            ]
            
            // Handle image upload if a new image is selected
            if let selectedImage = selectedImage {
                let fileName = "profile_avatar.png"
                let storagePath = "users/\(userId)/\(fileName)"
                
                if let imageData = selectedImage.pngData() {
                    do {
                        // Upload the image to Supabase Storage
                        _ = try await client.storage
                            .from("avatars")
                            .upload(
                                storagePath, // Use the new method
                                data: imageData, // Changed from file: to data:
                                options: FileOptions(
                                    cacheControl: "3600", // Caches the image for 1 hour
                                    contentType: "image/png",
                                    upsert: false // Do not overwrite existing files
                                )
                            )
                        
                        // Manually construct the public URL (assuming public bucket)
                        let publicUrl = "https://dwxfipenxnqkhgtwggrv.supabase.co/storage/v1/object/public/\(storagePath)"
                        updates["image_url"] = publicUrl
                        
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = "Image upload failed: \(error.localizedDescription)"
                            isLoading = false
                        }
                        return
                    }
                }
            }
            
            // Update the profile data in Supabase
            do {
                try await client
                    .from("profiles")
                    .update(updates)  // Ensure all values are Encodable (String)
                    .eq("id", value: userId)
                    .execute()
                
                DispatchQueue.main.async {
                    isLoading = false
                    print("Profile updated successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // Utility function to remove blank lines from bio
    private func removeBlankLines(from bio: String) -> String {
        return bio
            .split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }
    
    
    
    func validateAndSaveProfile() {
        // First, validate the username format
        validateUsernameFormat()
        
        // If the format is valid, check the uniqueness
        if isUsernameValid {
            Task {
                do {
                    let isUnique = try await checkUsernameAvailability(newUsername)
                    print(isUnique ? "USERNAME UNIQE":"USERNAME NOT UNIQUE")
                    if isUnique {
                        // Save profile if the username is unique
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
                } catch {
                    errorMessage = "Failed to check username availability: \(error.localizedDescription)"
                }
            }
        } else {
            errorMessage = "Invalid username format."
        }
    }
    
    func validateUsernameFormat() {
        let usernameRegex = "^[a-zA-Z0-9_]{1,15}$"
        isUsernameValid = NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: newUsername)
    }
    
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedUsername = trimmedUsername.lowercased() // Normalize case

        let response = try await client
            .from("profiles")
            .select()
            .eq("username", value: username)
            .execute()

        // Print the raw response data directly
        print("Checking availability for username: '\(username)'")
        
        // Assuming response.data is of type Data and already contains the JSON
        do {
            // Deserialize the JSON data directly
            if let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]] {
                // Print the JSON data in a readable format
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                let jsonString = String(data: jsonData, encoding: .utf8)
                print("Response Data: \(jsonString ?? "Invalid JSON")")
            } else {
                print("Response Data is not an array: \(response.data)")
            }
        } catch {
            print("Failed to serialize response data to JSON: \(error)")
        }

        // If no profiles are returned, the username is available
        return response.data.isEmpty
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
