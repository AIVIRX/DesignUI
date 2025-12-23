import Foundation
import SwiftUI

// Mocking the types sufficiently to run codable test
enum RenderModifier: Codable {
    case padding(CGFloat?)
    case foregroundColor(String)
}

struct RenderNode: Codable {
    let type: String
    let modifiers: [RenderModifier]
}

let node = RenderNode(type: "Text", modifiers: [.padding(10), .foregroundColor("red")])
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
if let data = try? encoder.encode(node), let str = String(data: data, encoding: .utf8) {
    print(str)
}
