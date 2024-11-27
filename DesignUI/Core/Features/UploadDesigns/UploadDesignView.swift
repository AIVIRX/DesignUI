//
//  UploadDesignView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/13/24.
//

import SwiftUI
import Drops
import Supabase

struct UploadDesignView: View {
    @State private var postID: String = ""
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var codeSnippet: String = ""
#if os(iOS)
    @State private var selectedImage: UIImage?
#endif
    
#if os(macOS)
    @State private var selectedImage: NSImage?
#endif
    @State private var isShowingImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var showToast = false
    @State private var selectedTags: [String] = []
    let client = SupabaseManager.shared.client
    let tags: [String] = ["swift", "ios", "developer"]
    let availableTags = [ "Animation", "Component", "SwiftUI", "Template", "UIKit"]
    var isUploadEnabled: Bool {
        return !title.isEmpty && !description.isEmpty && !codeSnippet.isEmpty && selectedImage != nil && !isLoading && !selectedTags.isEmpty
    }
    
    var body: some View {
        ScrollView {
#if os(iOS)
            VStack(alignment: .leading){
                RoundedRectangle(cornerRadius: 15)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .foregroundStyle(.thinMaterial)
                    .overlay{
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: 115,height: 250)
                            .foregroundStyle(Color.clear)
                            .overlay{
                                if let image = selectedImage {
                                    Button(action: {
                                        selectedImage = nil
                                        isShowingImagePicker = true
                                    }) {
#if os(iOS)
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity, maxHeight: 270)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .clipped()
                                            .shadow(radius: 8)
#endif
#if os(macOS)
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity, maxHeight: 270)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .clipped()
                                            .shadow(radius: 8)
#endif
                                    }
                                } else {
                                    Button(action: {
                                        isShowingImagePicker = true
                                    }) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundColor(.clear)
                                            .overlay(
                                                Image(systemName: "plus.circle.fill")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.blue)
                                            )
                                            .frame(height: 200)
                                    }
                                    .padding()
                                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0, dash: [5])))
                                    .sheet(isPresented: $isShowingImagePicker) {
                                        ImagePicker(selectedImage: $selectedImage)
                                    }
                                }
                            }
                    }
                
                Text("Title")
                    .bold()
                TextFieldWithCounter(placehold: "Login Screen Template", text: $title, maxLength: 30)
                
                Text("Description")
                    .bold()
                TextFieldWithCounter(placehold: "A simple login menu.", text: $description, maxLength: 300)
                
                Text("Code")
                    .bold()
                TextEditorWithCounter(text: $codeSnippet, maxLength: 5000)
                
                Text("Tags (Select up to 3)")
                    .bold()
                
                // Tags Selection View
                TagSelectionView(availableTags: availableTags, selectedTags: $selectedTags)
            }
#if os(iOS)
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){ Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
#endif
            
#if os(iOS)
            Button(action: { uploadDesign() }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Upload Design")
                        .padding(8)
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .background(isUploadEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .disabled(!isUploadEnabled)
            .padding(.top)
#endif
#endif
        }
        .environment(\.symbolVariants, .none)
        .accentColor(.none)
        .padding(7)
        .navigationTitle("Upload Design")
    }
    
    // Custom TextField with character counter
    struct TextFieldWithCounter: View {
        let placehold: String
        @Binding var text: String
        let maxLength: Int
        var body: some View {
            VStack(alignment: .leading) {
                TextField(placehold, text: $text)
                    .padding()
                    .bold()
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                HStack{
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(.caption)
                        .foregroundColor(text.count > maxLength ? .red : .secondary)
                }
            }
            .onChange(of: text) {
                if text.count > maxLength {
                    text = String(text.prefix(maxLength))
                }
            }
        }
    }
    
    // Custom TextEditor with character counter
    struct TextEditorWithCounter: View {
        @Binding var text: String
        let maxLength: Int
        var body: some View {
            VStack(alignment: .leading) {
                TextEditor(text: $text)
                    .padding()
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                HStack{
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(.caption)
                        .foregroundColor(text.count > maxLength ? .red : .secondary)
                }
            }
            .onChange(of: text) {
                if text.count > maxLength {
                    text = String(text.prefix(maxLength))
                }
            }
        }
    }
    
    struct TagSelectionView: View {
        let availableTags: [String]
        @Binding var selectedTags: [String]
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(availableTags, id: \.self) { tag in
                        Button(action: {
                            toggleTag(tag: tag)
                        }) {
                            HStack {
                                Image(systemName: selectedTags.contains(tag) ? "checkmark.circle.fill" : "plus.circle")
                                Text(tag)
                            }
                            .padding(8)
                            .foregroundColor(selectedTags.contains(tag) ? .white : .white)
                            .background(selectedTags.contains(tag) ? Color.blue : Color.gray)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedTags.contains(tag) ? Color.blue : Color.gray, lineWidth: 1)
                            )
                        }
                        .disabled(selectedTags.count >= 3 && !selectedTags.contains(tag))
                    }
                }
            }
        }
        
        private func toggleTag(tag: String) {
            if selectedTags.contains(tag) {
                selectedTags.removeAll { $0 == tag }
            } else if selectedTags.count < 3 {
                selectedTags.append(tag)
            }
        }
    }
    
    func generateUniqueImageID() -> String {
        let uuid = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        return "\(uuid)_\(timestamp)"
    }
    
#if os(iOS)
    func uploadDesign() {
        Task{
            guard let session = try? await client.auth.session else {
                errorMessage = "User session not available"
                return
            }
            
            let userId = session.user.id.uuidString
            
            isLoading = true
            
            guard let image = selectedImage else {
                print("Please select an image.")
                isLoading = false
                return
            }
            
            guard let imageData = image.jpegData(compressionQuality: 0.3) else {
                print("Failed to convert image.")
                isLoading = false
                return
            }
            
            let fileName = "\(UUID().uuidString).jpg"
            let storagePath = "\(userId)/\(fileName)"
            
            _ = try await client.storage
                .from("posts")
                .upload(
                    storagePath,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/png",
                        upsert: true
                    )
                )
            
            // Debug print: Confirm after upload
            print("Upload successful postS")
            
            // Construct the public URL (assuming the bucket is public)
            let publicUrl = "https://dwxfipenxnqkhgtwggrv.supabase.co/storage/v1/object/public/posts/\(storagePath)"
            
            do {
                try await client
                    .from("posts")
                    .insert(["title": title, "description": description, "code_snippet": codeSnippet,   "tags": selectedTags.joined(separator: ",") ,"image_url": publicUrl])
                    .execute()
                
                DispatchQueue.main.async {
                    isLoading = false
                    print("post uploaded successfully")
                }
            } catch {
                // Debug print: Show error message during profile update
                print("post upload failed for userID: \(userId), error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
#endif
    
    
#if os(iOS)
    struct ImagePicker: UIViewControllerRepresentable {
        @Environment(\.presentationMode) var presentationMode
        @Binding var selectedImage: UIImage?
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        }
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.presentationMode.wrappedValue.dismiss()
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
#endif
}

extension Date {
    func toFormattedString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: self)
    }
}
