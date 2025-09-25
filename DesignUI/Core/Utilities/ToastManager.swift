//
//  ToastManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

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
            icon: "document.on.document",
            duration: 3.0
        )
    }
    
    func dismissToast() {
        currentToast = nil
    }
}
