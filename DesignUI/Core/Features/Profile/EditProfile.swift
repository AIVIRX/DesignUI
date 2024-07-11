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
    @EnvironmentObject var userStore: UserStore
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
            TextFieldWithCounter(placeholder: "Name", text: $newDisplayName, maxLength: 15)
            
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
        guard let user = userStore.user else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.id)
        
        isLoading = true
        
        let cleanedBio = removeBlankLines(from: newBio)
        
        userDocRef.updateData([
            "displayName": newDisplayName,
            "bio": cleanedBio
        ]) { error in
            isLoading = false
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully")
                // Update the local user data
                userStore.fetchUserData(uid: user.id) { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    func removeBlankLines(from text: String) -> String {
        let lines = text.split(separator: "\n")
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return nonEmptyLines.joined(separator: "\n")
    }
    
    struct TextFieldWithCounter: View {
        let placeholder: String
        @Binding var text: String
        let maxLength: Int
        var body: some View {
            VStack(alignment: .leading) {
                Text(placeholder)
                    .font(.headline)
                TextField(placeholder, text: $text)
                    .padding()
                    .frame(height: 50)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
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
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
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
}

#Preview {
    EditProfileView(displayName: "John Doe", bio: "Software Programmer Living In New York City")
}
