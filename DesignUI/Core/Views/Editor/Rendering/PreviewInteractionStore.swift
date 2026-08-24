import SwiftUI

final class PreviewInteractionStore: ObservableObject {
    @Published private(set) var textValues: [UUID: String] = [:]
    @Published private(set) var searchFieldIds: Set<UUID> = []
    @Published private(set) var selectionValues: [String: String] = [:]

    func textValue(for componentId: UUID, fallback: String) -> String {
        textValues[componentId] ?? fallback
    }

    func setTextValue(_ value: String, for componentId: UUID) {
        textValues[componentId] = value
    }

    func hasExplicitTextValue(for componentId: UUID) -> Bool {
        textValues[componentId] != nil
    }

    func registerSearchField(_ componentId: UUID) {
        searchFieldIds.insert(componentId)
    }

    func activeSearchQuery() -> String? {
        for componentId in searchFieldIds {
            let current = textValue(for: componentId, fallback: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !current.isEmpty {
                return current.lowercased()
            }
        }
        return nil
    }

    func selectionValue(for key: String) -> String? {
        selectionValues[key]
    }

    func setSelectionValue(_ value: String, for key: String) {
        selectionValues[key] = value
    }

    func registerDefaultSelection(_ value: String, for key: String) {
        if selectionValues[key] == nil {
            selectionValues[key] = value
        }
    }
}

private struct PreviewInteractionStoreKey: EnvironmentKey {
    static let defaultValue: PreviewInteractionStore? = nil
}

extension EnvironmentValues {
    var previewInteractionStore: PreviewInteractionStore? {
        get { self[PreviewInteractionStoreKey.self] }
        set { self[PreviewInteractionStoreKey.self] = newValue }
    }
}
