//
//  SwiftUIView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/14/24.
//

import SwiftUI

class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []
    
    func showToast(message: String) {
        let toast = Toast(message: message)
        toasts.append(toast)
        
        // Dismiss the toast after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dismissToast(toast)
        }
    }
    
    private func dismissToast(_ toast: Toast) {
        if let index = toasts.firstIndex(where: { $0.id == toast.id }) {
            withAnimation {
                toasts.remove(at: index)
            }
        }
    }
}

struct Toast: Identifiable {
    let id = UUID()
    let message: String
}


struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack{
            Image(systemName: "doc.on.doc.fill")
            Text(message)
        }
        .padding()
        .background(.gray, in: RoundedRectangle(cornerRadius: 8))
        .foregroundColor(.white).bold()
        .shadow(radius: 5)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
}
