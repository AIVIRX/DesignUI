//
//  EditProfile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/14/24.
//

import SwiftUI
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
    @State private var initialDisplayName = ""
    @State private var newDisplayName = ""
    @State private var initialBio = ""
    @State private var newBio = ""
    @State private var initialUsername = ""
    @State private var newUsername = ""
    @State private var isLoading: Bool = false
    @State private var isUsernameValid: Bool = false
    @State private var isUsernameUnique: Bool = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userViewModel = UserViewModel.shared // Use shared instance
    let client = SupabaseManager.shared.client
    
    private var isSubmitEnabled: Bool {
        let hasImageChanged = selectedImage != nil
        let hasDisplayNameChanged = initialDisplayName != newDisplayName
        let hasBioChanged = initialBio != newBio
        let hasUsernameChanged = initialUsername != newUsername
        
        return hasImageChanged || hasDisplayNameChanged || hasBioChanged || hasUsernameChanged
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
                    } else if profile.image_url != "" {
                        AsyncImage(url: URL(string: profile.image_url)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                                .shadow(radius: 10)
                        } placeholder: {
                            // Show a placeholder while the image is loading
                            ProgressView() // Default loading indicator
                                .frame(width: 100, height: 100)
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
                .onAppear {
                    Task {
                        // Fetch profile data on view appearance
                        fetchProfileData()
                        
                        // Reset the state variables to match the profile data
                        self.selectedImage = nil  // Reset the image selection
                        self.newDisplayName = self.initialDisplayName
                        self.newBio = self.initialBio
                        self.newUsername = self.initialUsername
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
                        self.initialDisplayName = profile.display_name // Use profile data to prefill
                    }
                TextFieldWithValidation(placeholder: "Username", text: $newUsername, maxLength: 15, isValid: $isUsernameValid, isUnique: $isUsernameUnique)
                    .onAppear {
                        self.initialUsername = profile.username // Use profile data to prefill
                    }
                    .onChange(of: newUsername) {
                        validateUsernameFormat()
                    }
                TextEditorWithCounter(label: "Bio", text: $newBio, maxLength: 80)
                    .onAppear {
                        self.initialBio = profile.bio // Use profile data to prefill
                    }
                Spacer()
                
                Button(action: {
                    validateAndSaveProfile()
                }) {
                    Text(isLoading ? "Saving..." : "Save Changes")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(!isSubmitEnabled ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isSubmitEnabled)
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
                print("VALUE FOR INITIAL BIO: \(initialDisplayName)")
                print("VALUE FOR NEW BIO: \(newDisplayName)")
                
                
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
                    initialDisplayName = profileData.display_name
                    newDisplayName = profileData.display_name
                    
                    initialBio = profileData.bio
                    newBio = profileData.bio
                    
                    initialUsername = profileData.username
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
            
            // Dictionary to hold profile updates
            var updates: [String: String] = [:]
            
            // Only add updated fields to the dictionary
            if newDisplayName != initialDisplayName {
                updates["display_name"] = newDisplayName
            }
            
            if cleanedBio != initialBio {
                updates["bio"] = cleanedBio
            }
            
            if newUsername.lowercased() != initialUsername.lowercased() {
                updates["username"] = newUsername.lowercased()
            }
            
            // Handle image upload/update if a new image is selected
            if let selectedImage = selectedImage {
                let fileName = "profile_avatar.png"
                let storagePath = "\(userId)/\(fileName)"
                
                if let imageData = selectedImage.pngData() {
                    do {
                        // Debug print: Check the storage path and file name
                        print("Attempting to upload file to: avatars/\(storagePath)")
                        
                        // Upload the image to Supabase Storage
                        _ = try await client.storage
                            .from("avatars")
                            .upload(
                                storagePath,
                                data: imageData,
                                options: FileOptions(
                                    cacheControl: "3600", // Caches the image for 1 hour
                                    contentType: "image/png",
                                    upsert: true // Overwrites existing file if it exists
                                )
                            )
                        
                        // Debug print: Confirm after upload
                        print("Upload successful for: avatars/\(storagePath)")
                        
                        // Construct the public URL (assuming the bucket is public)
                        let publicUrl = "https://dwxfipenxnqkhgtwggrv.supabase.co/storage/v1/object/public/avatars/\(storagePath)"
                        updates["image_url"] = publicUrl
                        
                    } catch {
                        // Debug print: Show error message during upload
                        print("Image upload failed for: avatars/\(storagePath), error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.async {
                            errorMessage = "Image upload failed: \(error.localizedDescription)"
                            isLoading = false
                        }
                        return
                    }
                }
            }
            
            // Update the profile data in Supabase only if there are updates
            if !updates.isEmpty {
                do {
                    try await client
                        .from("profiles")
                        .update(updates)
                        .eq("id", value: userId)
                        .execute()
                    
                    DispatchQueue.main.async {
                        isLoading = false
                        dismiss()
                        print("Profile updated successfully")
                    }
                    await userViewModel.fetchProfileData()  // fetch profile data

                } catch {
                    // Debug print: Show error message during profile update
                    print("Profile update failed for userID: \(userId), error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        errorMessage = "Failed to update profile: \(error.localizedDescription)"
                        isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                    print("No changes detected, profile not updated.")
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
    
    func isUsernameUnique(_ username: String, completion: @escaping (Bool) -> Void) async {
        do {
            // Directly query the 'users' table and decode into an array of User objects
            let users: [User] = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: username)
                .execute().value
            
            // If the array is empty, it means the username is unique
            completion(users.isEmpty)
        } catch {
            // Handle any errors from the query
            print("Error checking username uniqueness: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func validateAndSaveProfile() {
        // First, validate the username format
        validateUsernameFormat()
        
        // Check if the username is valid
        if isUsernameValid {
            // Only check username uniqueness if the username has changed
            if newUsername.lowercased() != initialUsername.lowercased() {
                // If the username has changed, check for uniqueness asynchronously
                Task {
                    // Call the asynchronous function to check if the username is unique
                    await isUsernameUnique(newUsername) { isUnique in
                        if isUnique {
                            // If the username is unique, save the profile
                            saveProfile()
                        } else {
                            // If not, set error message
                            
                            isUsernameUnique = false
                            errorMessage = "Username already exists. Please choose a different username."
                        }
                    }
                }
            } else {
                // If the username hasn't changed, just save the profile
                saveProfile()
            }
        } else {
            // If username format is invalid, set error message
            isUsernameUnique = false
            errorMessage = "Username format is not valid"
        }
    }
    
    func validateUsernameFormat() {
        let usernameRegex = "^[a-zA-Z0-9_]{1,15}$"
        isUsernameValid = NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: newUsername)
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
