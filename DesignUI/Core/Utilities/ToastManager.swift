//
//  ToastManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Combine

class ToastManager: ObservableObject {
    @Published var currentToast: ToastData?
    
    static let shared = ToastManager()
    
    private init() {}
    
    func showToast(_ toast: ToastData) {
        currentToast = toast
    }
    
    func showCopyToast() {
        currentToast = ToastData(
            title: "Copied",
            icon: .sfSymbol(name: "document.on.document", color: .gray),
            duration: 3.0
        )
    }
    
    func dismissToast() {
        currentToast = nil
    }
}
