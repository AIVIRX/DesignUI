//
//  UpdatePost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/30/24.
//

import SwiftUI
import FirebaseFirestore

struct EditPostView: View {
    @State var id: String
    @State var title: String
    @State var description: String
    @State var codeSnippet: String
    @State var tags: [String]
    @State var hexa: String
    @State var showAlert: Bool = false
    @State var visibility: String
    @State var alertMessage: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    let visibilityOptions = ["public", "private", "unlisted"]
    
    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Title", text: $title)
            }
            
            Section(header: Text("Description")) {
                TextField("Description", text: $description)
            }
            
            Section(header: Text("Code Snippet")) {
                TextEditor(text: $codeSnippet)
                    .frame(height: 200)
            }
            
            Section(header: Text("Visibility")) {
                Picker("Select Visibility", selection: $visibility) {
                    ForEach(visibilityOptions, id: \.self) { option in
                        Text(option.capitalized)  // Capitalize the first letter of the options
                    }
                }
                .pickerStyle(MenuPickerStyle())  // Dropdown style for the picker
            }
            
            Section(header: Text("Tags")) {
                TextField("Tags (comma separated)", text: Binding(
                    get: {
                        self.tags.joined(separator: ", ")
                    },
                    set: {
                        self.tags = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                ))
            }
            
            Section(header: Text("Background Color (Hex)")) {
                TextField("Hex Color", text: $hexa)
            }
            
            Button("Save Changes") {
                saveChanges()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationTitle("Edit Post")
#if os(iOS)
        .navigationBarItems(leading: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
#endif
    }
    
    private func saveChanges() {
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(id)
        
        let updatedData: [String: Any] = [
            "title": title,
            "description": description,
            "codeSnippet": codeSnippet,
            "tags": tags,
            "hexa": hexa,
            "visibility": visibility
        ]
        
        postRef.updateData(updatedData) { error in
            if let error = error {
                self.alertMessage = "Error updating post: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
