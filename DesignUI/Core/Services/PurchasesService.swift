import Foundation
import Combine
import RevenueCat
final class PurchasesService: NSObject, ObservableObject {
    static let shared = PurchasesService()

    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var hasPremium: Bool = false
    @Published private(set) var lastErrorMessage: String?

    private override init() { super.init() }

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
