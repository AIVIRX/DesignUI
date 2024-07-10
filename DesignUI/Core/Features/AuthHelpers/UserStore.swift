//
//  UserStore.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/9/24.
//

import Foundation
import FirebaseAuth

class UserStore: ObservableObject {
    @Published var user: UserModel? = nil

    init() {
        self.user = fetchCurrentUser()
    }

    func fetchCurrentUser() -> UserModel? {
        if let user = Auth.auth().currentUser {
            return UserModel(id: user.uid, displayName: user.displayName ?? "New User", bio: "")
        }
        return nil
    }

    func signIn(user: UserModel) {
        self.user = user
    }

    func signOut() {
        self.user = nil
    }
}
