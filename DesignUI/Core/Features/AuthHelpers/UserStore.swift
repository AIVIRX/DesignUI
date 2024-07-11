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
            return UserModel(id: user.uid, displayName: user.displayName ?? "New User", bio: "")
        }
        return nil
    }
    
    func signIn(user: UserModel) {
        self.user = user
    }
    
    func updateUser(displayName: String, bio: String) {
        guard var currentUser = self.user else { return }
        currentUser.displayName = displayName
        currentUser.bio = bio
        self.user = currentUser
    }
    
    func fetchUserData(uid: String, completion: @escaping (UserModel?) -> Void) {
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(uid)
        
        userDocRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let displayName = data?["displayName"] as? String ?? "New User"
                let bio = data?["bio"] as? String ?? ""
                let user = UserModel(id: uid, displayName: displayName, bio: bio)
                DispatchQueue.main.async {
                    self.user = user
                }
                completion(user)
            } else {
                completion(nil)
            }
        }
    }

    func signOut() {
        self.user = nil
    }
}
