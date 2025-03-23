import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let features = [
        "Access to all premium designs",
        "Export designs in high quality",
        "Remove watermark",
        "Priority support"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Upgrade to Pro")
                        .font(.title.bold())
                        .padding(.top)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                Text(feature)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Subscription Options
                    VStack(spacing: 12) {
                        ForEach(subscriptionManager.subscriptions, id: \.id) { product in
                            SubscriptionOptionView(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                action: { selectedProduct = product }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(action: purchase) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(selectedProduct == nil)
                        .padding(.horizontal)
                    }
                    
                    // Restore Purchases
                    Button("Restore Purchases", action: restore)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") { dismiss() })
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            do {
                try await subscriptionManager.loadProducts()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func purchase() {
        guard let product = selectedProduct else { return }
        isLoading = true
        
        Task {
            do {
                try await subscriptionManager.purchase(product)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func restore() {
        isLoading = true
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct SubscriptionOptionView: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 