//
//  StoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

//
//  StoreView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
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
                
                if let subscription = customerInfo.entitlements.active.first {
                    self?.subscribedPlanTitle = subscription.value.productIdentifier
                }
            } else if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}

struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var purchaseSuccess = false
    @State private var purchaseError: Error?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center) {
            ScrollView {
                SubscribtionTitleView()
                
                if viewModel.isSubscribed {
                    HStack{
                        Text("You're currently subscribed to Premium!")
                            .foregroundColor(.green)
                    }
                    .padding(8)
                    .background(.thickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                    FeaturesContainerView()
                    
                    OfferingsView(
                        offerings: viewModel.offerings,
                        selectedPackage: $selectedPackage
                    )
                    
                    if purchaseSuccess {
                        Text("Purchase successful!")
                            .foregroundColor(.green)
                            .padding(.top, 8)
                    }
                    
                    if let error = purchaseError {
                        Text("Purchase failed: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    
                    PurchaseButton(
                        isPurchasing: isPurchasing,
                        action: {
                            if let selectedPackage = selectedPackage {
                                purchase(package: selectedPackage)
                            }
                        }
                    )
                    .padding(.top, 8)
                    
            }
        }
        .padding(.horizontal)
        .navigationBarItems(trailing: HStack {
            Button(action: restorePurchases){
                Text("Restore")
            }

        })
        .onAppear {
            viewModel.fetchOfferings()
            viewModel.fetchCustomerInfo()
        }
        .onChange(of: viewModel.offerings) {
            if let newOfferings = viewModel.offerings,
               let firstPackage = newOfferings.current?.availablePackages.first {
                selectedPackage = firstPackage
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
                viewModel.fetchCustomerInfo() // Refresh subscription status
            }
        }
    }
    
    private func restorePurchases() {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error = error {
                self.purchaseError = error
            } else {
                self.purchaseSuccess = true
                viewModel.fetchCustomerInfo() // Refresh subscription status
            }
        }
    }
}

struct OfferingsView: View {
    let offerings: Offerings?
    @Binding var selectedPackage: Package?
    var body: some View {
        if let offerings = offerings {
            ForEach(offerings.current?.availablePackages ?? [], id: \.identifier) { package in
                PackageView(package: package, selectedPackage: $selectedPackage)
                    .padding(.top, 10)
            }
        } else {
            Text("Loading subscriptions...")
        }
    }
}

struct PackageView: View {
    let package: Package
    @Binding var selectedPackage: Package?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
        }) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: selectedPackage == package ? "checkmark.circle.fill" : "circle.fill")
                            .foregroundColor(selectedPackage == package ? Color.indigo : Color.gray.opacity(0.5))
                        
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        
                        if package.storeProduct.subscriptionPeriod?.unit == .year {
                            Spacer()
                            
                            Text("33% OFF")
                                .font(.subheadline)
                                .padding(4)
                                .bold()
                                .background(selectedPackage == package ? Color.indigo : Color.gray.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                    }
                    
                    if package.storeProduct.subscriptionPeriod?.unit == .month {
                        Text("Access for only \(package.storeProduct.localizedPricePerMonth ?? "$Error")/mo")
                            .font(.subheadline)
                            .padding(.top, 3)
                    } else {
                        Text("Access for only \(package.storeProduct.localizedPricePerYear ?? "$Error")/yr (\(package.storeProduct.localizedPricePerMonth ?? "$Error")/mo)")
                            .font(.subheadline)
                            .padding(.top, 3)
                    }
                }
                .padding()
                
                Spacer()
            }
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 20).stroke(selectedPackage == package ? .indigo : .gray.opacity(0.5), lineWidth: 2.5))
            .onTapGesture {
                selectedPackage = package
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PurchaseButton: View {
    let isPurchasing: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("Subscribe")
                .font(.title3)
                .padding()
                .bold()
                .frame(maxWidth: .infinity)
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(30)
        }
        .disabled(isPurchasing)
    }
}

struct RestorePurchasesButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Button(action: action) {
            Text("Restore")
                .font(.body)
                .bold()
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
}

struct SubscribtionTitleView: View {
    var body: some View {
        VStack {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibility(hidden: true)
            
            Text("Dock UI")
                .customTitleText()
            
            Text("Premium")
                .customTitleText()
                .foregroundColor(.mainColor)
        }
        .padding(.top, 8)
    }
}

#Preview {
    StoreView()
}
