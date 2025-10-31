//
//  SubscriptionManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import Foundation
import RevenueCat
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    
    private init() {
        checkSubscriptionStatus()
    }
    
    func checkSubscriptionStatus() {
        isLoading = true
        
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                let offerings = try await Purchases.shared.offerings()
                
                await MainActor.run {
                    self.customerInfo = customerInfo
                    self.offerings = offerings
                    // Check for specific entitlement using shared constant
                    self.isSubscribed = customerInfo.entitlements[Constants.ENTITLEMENT_ID]?.isActive == true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error fetching subscription status: \(error)")
                }
            }
        }
    }
    
    func purchase(package: Package) async -> Bool {
        isLoading = true
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let customerInfo = result.customerInfo
            
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isSubscribed = customerInfo.entitlements[Constants.ENTITLEMENT_ID]?.isActive == true
                self.isLoading = false
            }
            
            return customerInfo.entitlements[Constants.ENTITLEMENT_ID]?.isActive == true
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isSubscribed = customerInfo.entitlements[Constants.ENTITLEMENT_ID]?.isActive == true
                self.isLoading = false
            }
            
            return customerInfo.entitlements["premium"]?.isActive == true
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Restore failed: \(error)")
            return false
        }
    }
    
    func presentPaywallIfNeeded() -> Bool {
        return !isSubscribed
    }
}
