import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

enum PlatformLayoutContext {
    static var isMac: Bool {
#if os(macOS)
        true
#else
        false
#endif
    }

}

func platformImage(from data: Data) -> PlatformImage? {
#if os(macOS)
    NSImage(data: data)
#else
    UIImage(data: data)
#endif
}

func swiftUIImage(from data: Data) -> Image? {
    guard let image = platformImage(from: data) else { return nil }
#if os(macOS)
    return Image(nsImage: image)
#else
    return Image(uiImage: image)
#endif
}

func bundledPlatformImage(named name: String) -> PlatformImage? {
#if os(macOS)
    NSImage(named: name)
#else
    UIImage(named: name)
#endif
}

func systemSymbolExists(named name: String) -> Bool {
#if os(macOS)
    NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
#else
    UIImage(systemName: name) != nil
#endif
}
