//
//  EditProfile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/14/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @State private var newDisplayName: String
    @State private var initialDisplayName: String
    @State private var isLoading: Bool = false
    @State private var newBio: String
    @State private var initialBio: String
    @Environment(\.presentationMode) var presentationMode
    
    init(displayName: String, bio: String) {
        self._newDisplayName = State(initialValue: displayName)
        self._initialDisplayName = State(initialValue: displayName)
        self._newDisplayName = State(initialValue: displayName)
        self._initialDisplayName = State(initialValue: displayName)
        self._newBio = State(initialValue: bio)
        self._initialBio = State(initialValue: bio)
    }
    
    var body: some View {
        VStack {
            TextFieldWithCounter(placehold: "Name", text: $newDisplayName, maxLength: 15)
            
            TextEditorWithCounter(label: "Bio", text: $newBio, maxLength: 80)
            
            Spacer()
            //Save Button
            Button(action: {
                saveProfile()
            }) {
                Text(isLoading ? "Saving..." : "Save")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoading || (newDisplayName == initialDisplayName && newBio == initialBio) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading || (newDisplayName == initialDisplayName && newBio == initialBio))
        }
        .padding()
    }
    
    func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        
        isLoading = true
        
        userDocRef.updateData([
            "displayName": newDisplayName,
            "bio": newBio
        ]) { error in
            isLoading = false
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully")
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    struct TextFieldWithCounter: View {
        let placehold: String
        @Binding var text: String
        let maxLength: Int
        var body: some View {
            VStack(alignment: .leading) {
                Text(placehold)
                    .font(.headline)
                TextField(placehold, text: $text)
                    .padding()
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                HStack {
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
    
    struct TextEditorWithCounter: View {
        let label: String
        @Binding var text: String
        let maxLength: Int
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.headline)
                TextEditor(text: $text)
                    .padding()
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(text.count > maxLength ? .red : .secondary)
            }
            .onChange(of: text) {
                if text.count > maxLength {
                    text = String(text.prefix(maxLength))
                }
            }
        }
    }
}


#Preview {
    EditProfileView(displayName: "John Doe", bio: "Software Programmer Living In New York City")
}
