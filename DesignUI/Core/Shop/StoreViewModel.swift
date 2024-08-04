//
//  StoreViewModel.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/3/24.
//

import SwiftUI
import RevenueCat

@MainActor
class StoreViewModel: ObservableObject {
    @Published var offerings: Offerings?
    @Published var errorMessage: String?
    @Published var isSubscribed = false
    @Published var subscribedPlanTitle: String?
    
    init() {
        fetchOfferings()
        fetchCustomerInfo()
    }
    
    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.offerings = offerings
            }
        }
    }
    
    func fetchCustomerInfo() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            if let customerInfo = customerInfo {
                self?.isSubscribed = !customerInfo.entitlements.active.isEmpty
                //print("\(String(describing: self?.isSubscribed))")
            } else if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}

