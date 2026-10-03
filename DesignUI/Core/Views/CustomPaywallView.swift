import SwiftUI
import RevenueCat
import RevenueCatUI

struct CustomPaywallView: View {
    #if os(macOS)
    private static let macPaywallSize = CGSize(width: 500, height: 700)
    #endif
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var paywallManager: PaywallManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var purchases = PurchasesService.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    private let usesOwnNavigationStack: Bool

    init(usesOwnNavigationStack: Bool = true) {
        self.usesOwnNavigationStack = usesOwnNavigationStack
    }
    
    var body: some View {
        Group {
            if usesOwnNavigationStack {
                NavigationStack {
                    paywallContent
                }
            } else {
                paywallContent
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await purchases.loadOfferings()
                await purchases.loadCustomerInfo()
            }
        }
#if os(macOS)
        .frame(
            minWidth: Self.macPaywallSize.width,
            idealWidth: Self.macPaywallSize.width,
            maxWidth: Self.macPaywallSize.width,
            minHeight: Self.macPaywallSize.height,
            idealHeight: Self.macPaywallSize.height,
            maxHeight: Self.macPaywallSize.height
        )
#endif
    }

    @ViewBuilder
    private var paywallContent: some View {
        if let offerings = purchases.offerings, let currentOffering = offerings.current {
            PaywallView(offering: currentOffering)
                .onPurchaseCompleted { _ in
                    Task {
                        await purchases.loadCustomerInfo()
                        await MainActor.run {
                            subscriptionManager.checkSubscriptionStatus()
                            paywallManager.dismiss()
                            dismiss()
                        }
                    }
                }
                .onPurchaseFailure { error in
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                .onRestoreCompleted { _ in
                    Task {
                        await purchases.loadCustomerInfo()
                        await MainActor.run {
                            subscriptionManager.checkSubscriptionStatus()
                            paywallManager.dismiss()
                            dismiss()
                        }
                    }
                }
                .onRestoreFailure { error in
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                .onPurchaseCancelled {
                    paywallManager.dismiss()
                    dismiss()
                }
        } else {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading subscription...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
#elseif os(macOS)
            .background(Color(NSColor.windowBackgroundColor))
#endif
        }
    }
}
