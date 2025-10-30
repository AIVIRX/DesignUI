import Foundation
import SwiftUI

@MainActor
class PaywallManager: ObservableObject {
    static let shared = PaywallManager()
    @Published var isPresenting: Bool = false
    private init() {}
    
    func present() {
        isPresenting = true
    }
    
    func dismiss() {
        isPresenting = false
    }
}


