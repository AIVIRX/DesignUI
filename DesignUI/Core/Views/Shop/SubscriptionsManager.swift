//
//  SubscriptionsManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/15/25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedProduct: Product?
    @State private var showingSuccess = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    featuresSection
                    productsSection
                    subscribeButton
                    restoreSection
                    legalSection
                }
                .frame(maxWidth: 800)
                .padding()
            }
        }
        .task {
            do {
                try await purchaseManager.loadProducts()
                // Pre-select monthly subscription
                if let monthlyProduct = purchaseManager.products.first(where: { $0.subscription?.subscriptionPeriod.unit == .month }) {
                    selectedProduct = monthlyProduct
                }
            } catch {
                print(error)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(15)
            
            Text("Premium")
                .font(.title.bold())
            
            Text("Get access to all premium features!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if entitlementManager.hasPro {
                Text("You're Currently Subscribed")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.green)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features included:")
                .font(.headline)
            
            ForEach([
                "✓ Remove all ads",
                "✓ Access to all designs",
                "✓ Early access to new features"
            ], id: \.self) { feature in
                HStack(spacing: 8) {
                    Text(feature)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var productsSection: some View {
        VStack(spacing: 12) {
            ForEach(purchaseManager.products) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct == product,
                    isCurrentSubscription: entitlementManager.activeSubscriptionID == product.id, // Check if active plan
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedProduct = product
                        }
                    }
                )
#if os(iOS)
                .simultaneousGesture(TapGesture().onEnded {
                    HapticManager.shared.triggerImpact(style: .medium)
                })
#endif
            }
        }
    }
    
    private var subscribeButton: some View {
        
        VStack{
            if let product = selectedProduct, let subscription = product.subscription {
                Text("Plan auto-renews for \(product.displayPrice)/\(subscription.subscriptionPeriod.unit == .month ? "month" : "year") until canceled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                guard let product = selectedProduct else { return }
#if os(iOS)
                HapticManager.shared.triggerImpact(style: .medium)
#endif
                isLoading = true
                
                Task {
                    do {
                        try await purchaseManager.purchase(product)
                        withAnimation(.spring) {
                            showingSuccess = true
                        }
                    } catch {
                        print(error)
                    }
                    isLoading = false
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Subscribe Now")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(selectedProduct != nil ? Color.indigo : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .font(.headline)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedProduct == nil || isLoading)
            .buttonStyle(.plain)
        }
    }
    
    private var restoreSection: some View {
        VStack() {
            Button {
                Task {
                    do {
                        try await AppStore.sync()
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var legalSection: some View {
        HStack{
            Link("Privacy Policy", destination: URL(string: "https://dockui.com/privacy")!)
            Text("-")
            Link("Terms Of Service", destination: URL(string: "https://dockui.com/terms")!)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isCurrentSubscription: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if let subscription = product.subscription,
                           subscription.subscriptionPeriod.unit == .year {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.indigo)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        if isCurrentSubscription {
                            Text("Current Plan")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(6)
                                .background(Color.green.opacity(0.2))
                                .clipShape(Capsule())
                                .padding(.trailing, 8)
                        }
                        
                    }
                    
                    if let subscription = product.subscription {
                        Text(subscription.subscriptionPeriod.unit == .month ? "Monthly Plan" : "Annual Plan")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.headline)
                    
                    if let subscription = product.subscription {
                        Text(getPricePerMonth(product, subscription))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.indigo.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.indigo : Color.gray.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getPricePerMonth(_ product: Product, _ subscription: Product.SubscriptionInfo) -> String {
        if subscription.subscriptionPeriod.unit == .month {
            return "Per Month"
        } else {
            let monthlyPrice = (product.price as Decimal) / 12
            return "Per Year"
        }
    }
}
