import Foundation
import Combine
import RevenueCat
import StoreKit

final class PurchasesService: NSObject, ObservableObject {
    static let shared = PurchasesService()

    @Published private(set) var isConfigured: Bool = false
    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var hasPremium: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastErrorMessage: String?

    private override init() { super.init() }

    func configure(appUserID: String? = nil, logLevel: LogLevel = .warn, apiKey: String) {
        guard !isConfigured else { return }
        Purchases.logLevel = logLevel
        Purchases.configure(with: Configuration.Builder(withAPIKey: apiKey)
            .with(appUserID: appUserID)
            .build())
        Purchases.shared.delegate = self
        isConfigured = true
        refresh()
    }

    func refresh() {
        Task { @MainActor in
            await loadCustomerInfo()
            await loadOfferings()
        }
    }

    @MainActor
    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            handleCustomerInfo(info)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    func purchase(package: Package) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            handleCustomerInfo(result.customerInfo)
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            handleCustomerInfo(info)
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    private func handleCustomerInfo(_ info: CustomerInfo) {
        customerInfo = info
        hasPremium = info.entitlements.active.keys.contains(Constants.ENTITLEMENT_ID)
    }
}

extension PurchasesService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.handleCustomerInfo(customerInfo)
        }
    }
}
