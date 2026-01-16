//
//  RippleView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/7/25.
//
//  /// A modifier that applies a ripple effect to its content.
//  ///
//  ///
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

 struct RippleModifier: ViewModifier {
     var origin: CGPoint
     
     var elapsedTime: TimeInterval
     var duration: TimeInterval
     var amplitude: Double
     var frequency: Double
     var decay: Double
     var speed: Double
 
     func body(content: Content) -> some View {
         let shader = ShaderLibrary.bundle(.main).Ripples(
             .float2(origin),
             .float(elapsedTime),
 
             // Parameters
             .float(amplitude),
             .float(frequency),
             .float(decay),
             .float(speed)
         )
 
         let maxSampleOffset = maxSampleOffset
         let elapsedTime = elapsedTime
         let duration = duration
 
         content.visualEffect { view, _ in
             view.layerEffect(
                 shader,
                 maxSampleOffset: maxSampleOffset,
                 isEnabled: 0 < elapsedTime && elapsedTime < duration
             )
         }
     }
 
     var maxSampleOffset: CGSize {
         CGSize(width: amplitude, height: amplitude)
     }
 }
 
 
 struct RippleEffect<T: Equatable>: ViewModifier {
     
     var origin: CGPoint
     var trigger: T
     var amplitude: Double
     var frequency: Double
     var decay: Double
     var speed: Double
 
     init(at origin: CGPoint, trigger: T, amplitude: Double = 12, frequency: Double = 15, decay: Double = 8, speed: Double = 1200) {
         self.origin = origin
         self.trigger = trigger
         self.amplitude = amplitude
         self.frequency = frequency
         self.decay = decay
         self.speed = speed
     }
 
     func body(content: Content) -> some View {
         let origin = origin
         let duration = duration
         let amplitude = amplitude
         let frequency = frequency
         let decay = decay
         let speed = speed
 
         content.keyframeAnimator(
             initialValue: 0,
             trigger: trigger
         ) { view, elapsedTime in
             view.modifier(RippleModifier(
                 origin: origin,
                 elapsedTime: elapsedTime,
                 duration: duration,
                 amplitude: amplitude,
                 frequency: frequency,
                 decay: decay,
                 speed: speed
             ))
         } keyframes: { _ in
             MoveKeyframe(0)
             LinearKeyframe(duration, duration: duration)
         }
     }
 
     var duration: TimeInterval { 3 }
 }

// MARK: - Long Press Modifier

/// A modifier that handles long press gestures internally using platform-specific recognizers
/// to avoid blocking SwiftUI ScrollViews (which DragGesture(minimumDistance: 0) often does).
struct LongPressWithLocationModifier: ViewModifier {
    let duration: TimeInterval
    let action: (CGPoint) -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                LongPressGestureView(duration: duration, action: action)
            )
    }
}

extension View {
    func onLongPress(duration: TimeInterval = 0.5, perform action: @escaping (CGPoint) -> Void) -> some View {
        self.modifier(LongPressWithLocationModifier(duration: duration, action: action))
    }
}

// MARK: - Internal Representables

#if os(iOS)
struct LongPressGestureView: UIViewRepresentable {
    let duration: TimeInterval
    let action: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        // This is critical: ensure touches pass through if the gesture fails or for other interactions
        // However, for the gesture itself to work, we need userInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        // Use a standard UILongPressGestureRecognizer
        let recognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        recognizer.minimumPressDuration = duration
        recognizer.cancelsTouchesInView = false 
        recognizer.delegate = context.coordinator
        
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let action: (CGPoint) -> Void

        init(action: @escaping (CGPoint) -> Void) {
            self.action = action
        }

        @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
            if sender.state == .began {
                let location = sender.location(in: sender.view)
                action(location)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
#elseif os(macOS)
struct LongPressGestureView: NSViewRepresentable {
    let duration: TimeInterval
    let action: (CGPoint) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = LongPressNSView()
        view.pressDuration = duration
        view.action = action
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? LongPressNSView {
            view.pressDuration = duration
            view.action = action
        }
    }
}

class LongPressNSView: NSView {
    var pressDuration: TimeInterval = 0.5
    var action: ((CGPoint) -> Void)?
    
    private var timer: Timer?
    private var isPressed = false
    
    override func mouseDown(with event: NSEvent) {
        isPressed = true
        let location = convert(event.locationInWindow, from: nil)
        
        // Start timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pressDuration, repeats: false) { [weak self] _ in
            guard let self = self, self.isPressed else { return }
            self.action?(location)
            self.isPressed = false
        }
        
        super.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        isPressed = false
        timer?.invalidate()
        super.mouseUp(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
    }
}
#endif
