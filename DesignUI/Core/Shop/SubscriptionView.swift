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
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    if entitlementManager.hasPro {
                        successView
                    } else {
                        headerSection
                        featuresSection
                        productsSection
                        subscribeButton
                        restoreSection
                    }
                }
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
            
            Text("Unlock All Features")
                .font(.title2.bold())
            
            Text("Get access to all premium features!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
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
        .padding(.vertical, 2)
    }
    
    private var productsSection: some View {
        VStack(spacing: 12) {
            ForEach(purchaseManager.products) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct == product,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedProduct = product
                        }
                    }
                )
            }
        }
    }
    
    private var subscribeButton: some View {
        Button {
            guard let product = selectedProduct else { return }
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
        .padding(.bottom, 2)
    }
    
    private var restoreSection: some View {
        VStack(spacing: 8) {
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
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Text("All purchases are linked to your Apple ID")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Thank You!")
                .font(.title.bold())
            
            Text("You now have access to all premium features")
                .foregroundStyle(.secondary)
            
            Button("Start Exploring") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.top)
        }
        .padding(.vertical, 50)
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
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
                    .fill(isSelected ? Color.indigo.opacity(0.1) : Color(.systemBackground))
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
            return "Billed monthly"
        } else {
            let monthlyPrice = (product.price as Decimal) / 12
            return "About \(monthlyPrice.formatted(.currency(code: product.priceFormatStyle.currencyCode))) /mo"
        }
    }
    
    
}
