//
//  DBTest.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/18/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String?
    var username: String?
}

class UsersViewModel: ObservableObject {
    @Published var users = [User]()

    private var db = Firestore.firestore()

    func fetchUsers() {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.users = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
            }
        }
    }
}

struct UsersListView: View {
    @StateObject var viewModel = UsersViewModel()

    var body: some View {
        VStack {
            List(viewModel.users) { user in
                VStack(alignment: .leading) {
                    if let displayName = user.displayName {
                        Text(displayName)
                            .font(.headline)
                    }
                    if let username = user.username {
                        Text(username)
                            .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        UsersListView()
    }
}
