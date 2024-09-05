//
//  RemoteConfig.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/4/24.
//

import SwiftUI
import FirebaseRemoteConfig

class RemoteConfigManager: ObservableObject {
    @Published var bannerLocationIPHONE: String = "top"
    private var remoteConfig: RemoteConfig

    init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600  // fetch interval in seconds
        remoteConfig.configSettings = settings

        // Set default values
        let defaultValues: [String: NSObject] = [
            "welcome_message": "Default Welcome Message" as NSObject
        ]
        remoteConfig.setDefaults(defaultValues)

        fetchRemoteConfig()
    }

    func fetchRemoteConfig() {
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                print("Error fetching remote config: \(error)")
            } else {
                self.bannerLocationIPHONE = self.remoteConfig["banner_location_iphone"].stringValue ?? "top"

            }
        }
    }
}
