//
//  Toast.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/22/25.
//

import SwiftUI

struct ToastData: Equatable {
    let title: String
    let subtitle: String?
    let icon: ToastIcon
    let duration: Double
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: ToastIcon = .none,
        duration: Double = 2.0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.duration = duration
    }
    
    static func == (lhs: ToastData, rhs: ToastData) -> Bool {
        return lhs.title == rhs.title &&
               lhs.subtitle == rhs.subtitle &&
               lhs.icon == rhs.icon &&
               lhs.duration == rhs.duration
    }
}

enum ToastIcon: Equatable {
    case none
    case system(name: String)
    case custom(name: String)
    case sfSymbol(name: String, color: Color)
    static func == (lhs: ToastIcon, rhs: ToastIcon) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.system(name1), .system(name2)):
            return name1 == name2
        case let (.custom(name1), .custom(name2)):
            return name1 == name2
        case let (.sfSymbol(name1, color1), .sfSymbol(name2, color2)):
            return name1 == name2 && color1 == color2
        default:
            return false
        }
    }
}

struct ToastView: View {
    let toast: ToastData
    @Binding var isPresented: Bool
    @State private var opacity: CGFloat = 0
    @State private var offset: CGFloat = -100
    @State private var dragOffset: CGFloat = 0
    var body: some View {
        HStack(spacing: 8) {
            // Content
            if toast.subtitle != nil {
                // With subtitle - align left
                VStack(alignment: .leading, spacing: 1) {
                    // Icon
                    iconView
                        .imageScale(.small)
                    
                    Text(toast.title)
                        .font(.system(size: 20, weight: .medium))
                    
                    Text(toast.subtitle!)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } else {
                // Icon
                HStack{
                    iconView
                        .imageScale(.medium)
                    
                    Text(toast.title)
                        .font(.system(size: 18, weight: .medium))
                }
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
#if os(iOS)
            Capsule()
                .stroke(.gray, lineWidth: 1)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
#else
            Capsule()
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
#endif
        }
        .frame(maxWidth: 130)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .opacity(opacity)
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
                            opacity = 0
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
    
    private var iconView: some View {
        Group {
            switch toast.icon {
            case .none:
                EmptyView()
            case .system(let name):
                Image(systemName: name)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            case .custom(let name):
                Image(name)
                    .resizable()
                    .frame(width: 16, height: 16)
            case .sfSymbol(let name, let color):
                Image(systemName: name)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
        }
    }
    
    private func showToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            opacity = 1
            offset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            dismissToast()
        }
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            opacity = 0
            offset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let toast = toast {
                    ToastView(
                        toast: toast,
                        isPresented: Binding(
                            get: { self.toast != nil },
                            set: { if !$0 { self.toast = nil } }
                        )
                    )
                }
            }
    }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}


