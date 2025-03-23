import SwiftUI

public final class EntitlementManager: ObservableObject {
    public static let shared = EntitlementManager()
    
    static let userDefaults = UserDefaults(suiteName: "group.com.maicolcabreja.DesignUI")!
    
    @AppStorage("hasPro", store: userDefaults)
    public var hasPro: Bool = false
    
    @AppStorage("hasLifetime", store: userDefaults)
    public var hasLifetime: Bool = false
    
    @AppStorage("activeSubscriptionTier", store: userDefaults)
    public var activeSubscriptionTier: String = ""
    
    @AppStorage("subscriptionExpirationDate", store: userDefaults)
    public var subscriptionExpirationDate: Double = 0
    
    private init() {}
} 