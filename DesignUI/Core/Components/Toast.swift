//
//  Toast.swift
//
//  Created by Maicol Cabreja on 3/22/25.
//

import SwiftUI

struct ToastData: Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let duration: Double
    let isLoading: Bool
    
    init(
        title: String,
        icon: String = "document.on.document",
        duration: Double = 2.0,
        isLoading: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.duration = duration
        self.isLoading = isLoading
    }
    
    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        return lhs.title == rhs.title &&
               lhs.icon == rhs.icon &&
               lhs.duration == rhs.duration && lhs.isLoading == rhs.isLoading && lhs.id == rhs.id
    }
}

struct ToastView: View {
    let toast: ToastData
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = -100
    @State private var dragOffset: CGFloat = 0
    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            HStack(spacing: 8) {
                // Icon
                HStack {
                    if toast.isLoading { ProgressView().controlSize(.small) }
                    else { Image(systemName: toast.icon)
                        .font(.system(size: 16))
                        .tint(.primary)
                        .imageScale(.medium)
                    }
                    
                    Text(toast.title)
                        .font(.title3)
                        .tint(.primary)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .fixedSize(horizontal: true, vertical: false)
            .glassEffect()
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .offset(y: offset + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let translation = gesture.translation.height
                        dragOffset = translation < 0 ? translation : 0
                    }
                    .onEnded { gesture in
                        let translation = gesture.translation.height
                        if translation < -50 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = -100
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isPresented = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .onAppear {
                showToast()
            }
        } else {
            HStack(spacing: 8) {
                // Icon
                HStack {
                    if toast.isLoading { ProgressView().controlSize(.small) }
                    else { Image(systemName: toast.icon)
                        .font(.system(size: 16))
                        .tint(.primary)
                        .imageScale(.medium)
                    }
                    
                    Text(toast.title)
                        .font(.title3)
                        .tint(.primary)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .fixedSize(horizontal: true, vertical: false)
            .background(toastBackground)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .offset(y: offset + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let translation = gesture.translation.height
                        dragOffset = translation < 0 ? translation : 0
                    }
                    .onEnded { gesture in
                        let translation = gesture.translation.height
                        if translation < -50 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = -100
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isPresented = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .onAppear {
                showToast()
            }
        }
    }
    
    private func showToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
        }
        
        // Zero duration is used for progress that lasts until the operation finishes.
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    @ViewBuilder
    private var toastBackground: some View {
#if os(iOS)
            Capsule()
                .stroke(.gray, lineWidth: 1)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
#else
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
#endif
        }
    }

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let toast = toast {
                    ToastView(
                        toast: toast,
                        isPresented: Binding(
                            get: { self.toast != nil },
                            set: { if !$0 && self.toast?.id == toast.id { self.toast = nil } }
                        )
                    )
                    .id(toast.id)
                    .task(id: toast.id) {
                        guard toast.duration > 0 else { return }
                        do {
                            try await Task.sleep(for: .seconds(toast.duration))
                            guard self.toast?.id == toast.id else { return }
                            withAnimation { self.toast = nil }
                        } catch { /* Replacement or disappearance cancels dismissal. */ }
                    }
                }
            }
    }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
