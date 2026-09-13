#if os(iOS)
import SwiftUI
import UIKit

/// Observes touches within this viewport without placing a hit-testing surface over controls.
struct IOSCanvasGestures: UIViewRepresentable {
    var canPan: Bool
    var onPan: (CGSize, Bool) -> Void
    var onZoom: (CGFloat, Bool) -> Void

    func makeUIView(context: Context) -> GestureViewport {
        let view = GestureViewport()
        view.coordinator = context.coordinator
        context.coordinator.viewport = view
        return view
    }

    func updateUIView(_ view: GestureViewport, context: Context) {
        context.coordinator.owner = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(owner: self) }
    static func dismantleUIView(_ view: GestureViewport, coordinator: Coordinator) {
        coordinator.attach(to: nil)
    }

    final class GestureViewport: UIView {
        weak var coordinator: Coordinator?
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(to: window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var owner: IOSCanvasGestures
        weak var viewport: GestureViewport?
        weak var attachedWindow: UIWindow?
        private var lastPan: CGSize = .zero
        private lazy var pan: UIPanGestureRecognizer = {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(panned))
            gesture.maximumNumberOfTouches = 1
            gesture.cancelsTouchesInView = false
            gesture.delegate = self
            return gesture
        }()
        private lazy var pinch: UIPinchGestureRecognizer = {
            let gesture = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
            gesture.cancelsTouchesInView = false
            gesture.delegate = self
            return gesture
        }()

        init(owner: IOSCanvasGestures) { self.owner = owner }

        func attach(to window: UIWindow?) {
            guard attachedWindow !== window else { return }
            attachedWindow?.removeGestureRecognizer(pan)
            attachedWindow?.removeGestureRecognizer(pinch)
            attachedWindow = window
            window?.addGestureRecognizer(pan)
            window?.addGestureRecognizer(pinch)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let viewport, viewport.bounds.contains(touch.location(in: viewport)) else { return false }
            // Find the containing controller's root view rather than relying on
            // SwiftUI's private representable wrapper hierarchy.
            var container = viewport.superview
            while let view = container, !(view.next is UIViewController) {
                container = view.superview
            }
            guard let host = container, let touched = touch.view,
                  touched.isDescendant(of: host) else { return false }
            if gestureRecognizer === pan {
                guard owner.canPan else { return false }
                var ancestor: UIView? = touched
                while let view = ancestor {
                    if view is UIScrollView || view is UIControl { return false }
                    ancestor = view.superview
                }
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            // Pinching must not wait for an embedded ScrollView's pan recognizer to fail.
            gestureRecognizer === pinch || other === pinch
        }

        @objc private func panned(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: attachedWindow)
            let offset = CGSize(width: translation.x, height: translation.y)
            switch gesture.state {
            case .began, .changed:
                lastPan = offset
                owner.onPan(offset, false)
            case .ended:
                owner.onPan(offset, true)
                lastPan = .zero
            case .cancelled, .failed:
                owner.onPan(lastPan, true)
                lastPan = .zero
            default: break
            }
        }

        @objc private func pinched(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began, .changed: owner.onZoom(gesture.scale, false)
            case .ended, .cancelled, .failed: owner.onZoom(gesture.scale, true)
            default: break
            }
        }
    }
}
#endif
