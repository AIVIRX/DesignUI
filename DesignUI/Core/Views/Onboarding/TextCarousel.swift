//
//  TextCarousel.swift
//  FuseAppOnboarding
//
//  Created by George on 04/11/2025.
//

import SwiftUI
import Combine

struct Carousel: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let image: String
}

struct TextCarousel: View {
    @State var items: [Carousel]
    
    @State private var window: [Carousel] = []
    @State private var index = 0
    
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var highlightID: UUID? {
        window.indices.contains(2) ? window[2].id : nil
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading) {
                ForEach(window) { item in
                    row(for: item, rowHeight: proxy.size.height / 3)
                }
            }
            .frame(height: proxy.size.height, alignment: .leading)
        }
        .mask(gradientMask)
        .onReceive(timer) { _ in
            tick()
        }
        .onAppear {
            setupWindowIfNeeded()
        }
    }

    private func row(for item: Carousel, rowHeight: CGFloat) -> some View {
        let isHighlighted = item.id == highlightID

        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isHighlighted ? .white : .white.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(item.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .scaleEffect(isHighlighted ? 1 : 0.92)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(isHighlighted ? 0.0 : 0.12), lineWidth: 1)
            )
            .transition(
                .move(edge: .leading).combined(with: .opacity).combined(with: .scale)
            )

            Text(item.text)
                .foregroundStyle(isHighlighted ? .white : .white.opacity(0.38))
                .font(
                    .system(
                        size: isHighlighted ? 42 : 34,
                        weight: isHighlighted ? .bold : .semibold,
                        design: .rounded
                    )
                )
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawingGroup()
        .frame(height: rowHeight)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isHighlighted ? .black.opacity(0.18) : .clear)
        )
        .transaction { transaction in
            if item.id == window.first?.id {
                transaction.animation = nil
            }
        }
    }

    private var gradientMask: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.22),
                .init(color: .black, location: 0.78),
                .init(color: .clear, location: 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func tick() {
        guard !items.isEmpty else { return }
        withAnimation {
            if !window.isEmpty {
                window.removeLast()
            }
            window.insert(Carousel(text: items[index].text, image: items[index].image), at: 0)
            index = ((index - 1) + items.count) % items.count
        }
    }

    private func setupWindowIfNeeded() {
        guard window.isEmpty, !items.isEmpty else { return }
        for i in 0..<5 {
            let index = i % items.count
            window.append(Carousel(text: items[index].text, image: items[index].image))
        }
        index = items.count - 1
    }
}
