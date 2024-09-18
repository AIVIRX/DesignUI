//
//  UserStore.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/9/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserStore: ObservableObject {
    @Published var user: UserModel? = nil
    func fetchCurrentUser() -> UserModel? {
        if let user = Auth.auth().currentUser {
            return UserModel(id: user.uid, profileImage: "", displayName: user.displayName ?? "", username: user.displayName ?? "", bio: "", isVerified: false)
        }
        return nil
    }
    
    func signIn(user: UserModel) {
        self.user = user
    }
    
    func updateUser(displayName: String, username: String, bio: String) {
        guard var currentUser = self.user else { return }
        currentUser.displayName = displayName
        currentUser.username = username
        currentUser.bio = bio
        self.user = currentUser
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(currentUser.id)
        
        userDocRef.updateData([
            "displayName": displayName,
            "username": username,
            "bio": bio,
            "updatedAt": Timestamp()
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            }
        }
    }
    
    func fetchUserData(uid: String, completion: @escaping (UserModel?) -> Void) {
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(uid)
        userDocRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let profileURL = data?["imageURL"] as? String ?? ""
                let displayName = data?["displayName"] as? String ?? "New User"
                let username = data?["username"] as? String ?? ""
                let bio = data?["bio"] as? String ?? ""
                let verified = data?["isVerified"] as? Bool ?? false
                let user = UserModel(id: uid, profileImage: profileURL, displayName: displayName, username: username, bio: bio, isVerified: verified)
                DispatchQueue.main.async {
                    self.user = user
                    completion(user)  // Ensure this is called after setting self.user
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func signOut() {
        self.user = nil
    }
}


