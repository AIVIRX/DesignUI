//
//  StoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

@MainActor
class StoreViewModel: ObservableObject {
    @Published var offerings: Offerings?
    @Published var errorMessage: String?
    
    init() {
        fetchOfferings()
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
}

struct StoreView: View {
    @State private var offerings: Offerings?
    @State private var isPurchasing = false
    @State private var purchaseSuccess = false
    @State private var purchaseError: Error?

    var body: some View {
        VStack {
            if let offerings = offerings {
                ForEach(offerings.current?.availablePackages ?? [], id: \.identifier) { package in
                    VStack {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        Text(package.storeProduct.localizedDescription)
                            .font(.subheadline)
                        Text(package.storeProduct.localizedPriceString)
                            .font(.title2)
                        
                        Button(action: {
                            purchase(package: package)
                        }) {
                            Text("Buy \(package.storeProduct.localizedTitle)")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isPurchasing)
                    }
                    .padding()
                }
            } else {
                Text("Loading subscriptions...")
            }

            if purchaseSuccess {
                Text("Purchase successful!")
                    .foregroundColor(.green)
            }

            if let error = purchaseError {
                Text("Purchase failed: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .onAppear(perform: fetchOfferings)
    }

    private func fetchOfferings() {
        Purchases.shared.getOfferings { (offerings, error) in
            if let error = error {
                print("Error fetching offerings: \(error)")
            } else {
                self.offerings = offerings
            }
        }
    }

    private func purchase(package: Package) {
        isPurchasing = true
        purchaseSuccess = false
        purchaseError = nil

        Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
            isPurchasing = false
            if let error = error {
                self.purchaseError = error
            } else if userCancelled {
                self.purchaseError = NSError(domain: "com.yourapp", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled the purchase."])
            } else {
                self.purchaseSuccess = true
            }
        }
    }
}

#Preview{
    StoreView()
}
