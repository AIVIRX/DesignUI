import Foundation
import Supabase
import Combine

enum AIOperationKind: String, Codable {
    case insert
    case updateProps = "update_props"
    case updateModifiers = "update_modifiers"
    case move
    case delete
}

enum AIOperationModifierMode {
    case merge
    case replace
}

struct AIOperationModifier: Codable, Equatable {
    let type: String
    let properties: [String: AnyCodable]?
}

struct AIEditOperation: Codable, Equatable {
    let op: AIOperationKind
    let nodeId: String?
    let parentId: String?
    let index: Int?
    let node: UIComponent?
    let props: [String: AnyCodable]?
    let mode: String?
    let modifiers: [AIOperationModifier]?
    let upsert: [AIOperationModifier]?
    let removeTypes: [String]?

    var modifierMode: AIOperationModifierMode {
        mode?.lowercased() == "replace" ? .replace : .merge
    }
}

enum AIOperationReducerError: Error, LocalizedError {
    case invalidPath(String)
    case nodeNotFound(String)
    case parentNotFound(String)
    case nonContainerTarget(String)
    case invalidNodePayload
    case rootMutationNotAllowed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPath(let path): return "Invalid node path: \(path)"
        case .nodeNotFound(let path): return "Node not found: \(path)"
        case .parentNotFound(let path): return "Parent not found: \(path)"
        case .nonContainerTarget(let path): return "Target is not a container: \(path)"
        case .invalidNodePayload: return "Operation node payload is invalid"
        case .rootMutationNotAllowed(let op): return "Operation '\(op)' is not allowed on root"
        }
    }
}

protocol AIOperationReducing {
    func apply(to root: UIComponent, operations: [AIEditOperation]) throws -> UIComponent
}

struct AIOperationReducer: AIOperationReducing {
    static let shared = AIOperationReducer()

    private static let containerTypes: Set<ComponentType> = [.vstack, .hstack, .zstack, .scrollView, .button]

    struct ApplyResult {
        let component: UIComponent
        let inverse: [AIEditOperation]
    }

    func apply(to root: UIComponent, operations: [AIEditOperation]) throws -> UIComponent {
        let working = root.clone()
        for operation in operations {
            try apply(operation: operation, root: working)
        }
        return working
    }

    func applyWithInverse(to root: UIComponent, operations: [AIEditOperation]) throws -> ApplyResult {
        let working = root.clone()
        var inversesInExecutionOrder: [[AIEditOperation]] = []

        for operation in operations {
            switch operation.op {
            case .move:
                guard let sourcePath = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
                guard sourcePath != "root" else { throw AIOperationReducerError.rootMutationNotAllowed("move") }
                guard let sourceRef = resolveNode(path: sourcePath, root: working) else { throw AIOperationReducerError.nodeNotFound(sourcePath) }
                guard sourceRef.parent != nil, let oldIndex = sourceRef.indexInParent else { throw AIOperationReducerError.nodeNotFound(sourcePath) }
                let movedId = sourceRef.node.id
                let oldParentPath = parentPath(of: sourcePath)

                try apply(operation: operation, root: working)

                guard let newPath = pathForNode(id: movedId, root: working) else {
                    throw AIOperationReducerError.nodeNotFound("moved node")
                }
                let inverse = AIEditOperation(
                    op: .move,
                    nodeId: newPath,
                    parentId: oldParentPath,
                    index: oldIndex,
                    node: nil,
                    props: nil,
                    mode: nil,
                    modifiers: nil,
                    upsert: nil,
                    removeTypes: nil
                )
                inversesInExecutionOrder.append([inverse])

            default:
                let inverseOps = try inverseOperations(for: operation, root: working)
                try apply(operation: operation, root: working)
                inversesInExecutionOrder.append(inverseOps)
            }
        }

        let inverse = inversesInExecutionOrder.reversed().flatMap { $0 }
        return ApplyResult(component: working, inverse: inverse)
    }

    private func apply(operation: AIEditOperation, root: UIComponent) throws {
        switch operation.op {
        case .insert:
            guard let parentId = operation.parentId else { throw AIOperationReducerError.parentNotFound("<nil>") }
            guard let payloadNode = operation.node else { throw AIOperationReducerError.invalidNodePayload }
            guard let parentRef = resolveNode(path: parentId, root: root) else { throw AIOperationReducerError.parentNotFound(parentId) }
            guard Self.containerTypes.contains(parentRef.node.type) else { throw AIOperationReducerError.nonContainerTarget(parentId) }
            let child = payloadNode.clone()
            let insertionIndex = clampIndex(operation.index, count: parentRef.node.children.count)
            parentRef.node.children.insert(child, at: insertionIndex)

        case .updateProps:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard let target = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            for (key, wrappedValue) in operation.props ?? [:] {
                if wrappedValue.value is NSNull {
                    target.node.properties.removeAll { $0.key == key }
                    continue
                }
                setOrInsertProperty(on: target.node, key: key, value: wrappedValue.value)
            }

        case .updateModifiers:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard let target = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }

            if operation.modifierMode == .replace {
                target.node.modifiers = []
            }

            let removeTypes = Set((operation.removeTypes ?? []).compactMap { ModifierType(rawValue: $0) })
            if !removeTypes.isEmpty {
                target.node.modifiers.removeAll { removeTypes.contains($0.type) }
            }

            if operation.modifierMode == .replace {
                let replacement = (operation.modifiers ?? []).compactMap(makeModifier(from:))
                target.node.modifiers = replacement
            } else {
                for mod in operation.modifiers ?? [] {
                    upsertModifier(on: target.node, modifier: mod)
                }
            }

            for mod in operation.upsert ?? [] {
                upsertModifier(on: target.node, modifier: mod)
            }

        case .move:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard nodeId != "root" else { throw AIOperationReducerError.rootMutationNotAllowed("move") }
            guard let parentId = operation.parentId else { throw AIOperationReducerError.parentNotFound("<nil>") }

            guard let sourceRef = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            guard let sourceParent = sourceRef.parent, let sourceIndex = sourceRef.indexInParent else {
                throw AIOperationReducerError.nodeNotFound(nodeId)
            }
            guard let destinationRef = resolveNode(path: parentId, root: root) else { throw AIOperationReducerError.parentNotFound(parentId) }
            guard Self.containerTypes.contains(destinationRef.node.type) else { throw AIOperationReducerError.nonContainerTarget(parentId) }

            let movingNode = sourceRef.node
            sourceParent.children.remove(at: sourceIndex)

            var insertionIndex = clampIndex(operation.index, count: destinationRef.node.children.count)
            if sourceParent.id == destinationRef.node.id, sourceIndex < insertionIndex {
                insertionIndex = max(0, insertionIndex - 1)
            }
            destinationRef.node.children.insert(movingNode, at: insertionIndex)

        case .delete:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard nodeId != "root" else { throw AIOperationReducerError.rootMutationNotAllowed("delete") }
            guard let target = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            guard let parent = target.parent, let index = target.indexInParent else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            parent.children.remove(at: index)
        }
    }

    private func setOrInsertProperty(on component: UIComponent, key: String, value: Any) {
        if let index = component.properties.firstIndex(where: { $0.key == key }) {
            component.properties[index].value = value
            return
        }
        let inferredType = inferPropertyType(for: key, value: value)
        component.properties.append(
            ComponentProperty(
                key: key,
                displayName: ComponentProperty.properDisplayName(for: key),
                type: inferredType,
                value: value,
                defaultValue: value
            )
        )
    }

    private func inferPropertyType(for key: String, value: Any) -> PropertyType {
        let lower = key.lowercased()
        if lower.contains("color") || lower.contains("foreground") || lower.contains("background") || lower.contains("fill") {
            return .color
        }
        if value is Bool { return .boolean }
        if value is Double || value is Float || value is Int { return .number }
        return .string
    }

    private func makeModifier(from operationModifier: AIOperationModifier) -> ComponentModifier? {
        guard let type = ModifierType(rawValue: operationModifier.type) else { return nil }
        let properties = operationModifier.properties?.mapValues { $0.value } ?? [:]
        return ComponentModifier(type: type, properties: properties)
    }

    private func upsertModifier(on component: UIComponent, modifier: AIOperationModifier) {
        guard let type = ModifierType(rawValue: modifier.type) else { return }
        let properties = modifier.properties?.mapValues { $0.value } ?? [:]
        if let existingIndex = component.modifiers.firstIndex(where: { $0.type == type }) {
            component.modifiers[existingIndex].properties = properties
            return
        }
        component.modifiers.append(ComponentModifier(type: type, properties: properties))
    }

    private func clampIndex(_ index: Int?, count: Int) -> Int {
        guard let index else { return count }
        return min(max(index, 0), count)
    }

    private func parsePath(_ path: String) -> [Int]? {
        if path == "root" { return [] }
        guard path.hasPrefix("root.") else { return nil }
        let suffix = String(path.dropFirst("root.".count))
        guard !suffix.isEmpty else { return nil }
        let parts = suffix.split(separator: ".")
        var result: [Int] = []
        for part in parts {
            guard let value = Int(part), value >= 0 else { return nil }
            result.append(value)
        }
        return result
    }

    private func resolveNode(path: String, root: UIComponent) -> (node: UIComponent, parent: UIComponent?, indexInParent: Int?)? {
        guard let indexes = parsePath(path) else { return nil }
        var current = root
        var parent: UIComponent?
        var indexInParent: Int?
        for index in indexes {
            guard current.children.indices.contains(index) else { return nil }
            parent = current
            indexInParent = index
            current = current.children[index]
        }
        return (current, parent, indexInParent)
    }

    private func inverseOperations(for operation: AIEditOperation, root: UIComponent) throws -> [AIEditOperation] {
        switch operation.op {
        case .insert:
            guard let parentId = operation.parentId else { throw AIOperationReducerError.parentNotFound("<nil>") }
            guard let parentRef = resolveNode(path: parentId, root: root) else { throw AIOperationReducerError.parentNotFound(parentId) }
            let insertIndex = clampIndex(operation.index, count: parentRef.node.children.count)
            let insertedPath = childPath(parent: parentId, index: insertIndex)
            return [
                AIEditOperation(
                    op: .delete,
                    nodeId: insertedPath,
                    parentId: nil,
                    index: nil,
                    node: nil,
                    props: nil,
                    mode: nil,
                    modifiers: nil,
                    upsert: nil,
                    removeTypes: nil
                ),
            ]

        case .delete:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard nodeId != "root" else { throw AIOperationReducerError.rootMutationNotAllowed("delete") }
            guard let target = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            guard target.parent != nil, let index = target.indexInParent else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            let parent = parentPath(of: nodeId)
            return [
                AIEditOperation(
                    op: .insert,
                    nodeId: nil,
                    parentId: parent,
                    index: index,
                    node: target.node.clone(),
                    props: nil,
                    mode: nil,
                    modifiers: nil,
                    upsert: nil,
                    removeTypes: nil
                ),
            ]

        case .updateProps:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard let target = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            var inverseProps: [String: AnyCodable] = [:]
            if let updateKeys = operation.props?.keys {
                for key in updateKeys {
                    if let existing = target.node.properties.first(where: { $0.key == key }) {
                        inverseProps[key] = AnyCodable(existing.value)
                    } else {
                        inverseProps[key] = AnyCodable(NSNull())
                    }
                }
            }
            return [
                AIEditOperation(
                    op: .updateProps,
                    nodeId: nodeId,
                    parentId: nil,
                    index: nil,
                    node: nil,
                    props: inverseProps,
                    mode: nil,
                    modifiers: nil,
                    upsert: nil,
                    removeTypes: nil
                ),
            ]

        case .updateModifiers:
            guard let nodeId = operation.nodeId else { throw AIOperationReducerError.nodeNotFound("<nil>") }
            guard let target = resolveNode(path: nodeId, root: root) else { throw AIOperationReducerError.nodeNotFound(nodeId) }
            let previousModifiers = target.node.modifiers.map { modifier in
                AIOperationModifier(
                    type: modifier.type.rawValue,
                    properties: modifier.properties.mapValues { AnyCodable($0) }
                )
            }
            return [
                AIEditOperation(
                    op: .updateModifiers,
                    nodeId: nodeId,
                    parentId: nil,
                    index: nil,
                    node: nil,
                    props: nil,
                    mode: "replace",
                    modifiers: previousModifiers,
                    upsert: nil,
                    removeTypes: nil
                ),
            ]

        case .move:
            return []
        }
    }

    private func parentPath(of path: String) -> String {
        guard path != "root", let dot = path.lastIndex(of: ".") else { return "root" }
        let parent = String(path[..<dot])
        return parent.isEmpty ? "root" : parent
    }

    private func childPath(parent: String, index: Int) -> String {
        if parent == "root" { return "root.\(index)" }
        return "\(parent).\(index)"
    }

    private func pathForNode(id: UUID, root: UIComponent) -> String? {
        if root.id == id { return "root" }
        for (index, child) in root.children.enumerated() {
            if let path = pathForNode(id: id, node: child, prefix: "root.\(index)") {
                return path
            }
        }
        return nil
    }

    private func pathForNode(id: UUID, node: UIComponent, prefix: String) -> String? {
        if node.id == id { return prefix }
        for (index, child) in node.children.enumerated() {
            if let path = pathForNode(id: id, node: child, prefix: "\(prefix).\(index)") {
                return path
            }
        }
        return nil
    }
}

enum AIServiceError: Error {
    case notAuthenticated
    case missingSession
    case requestFailed(String)
    case invalidResponse
    case emptyComponents
}

enum AIGenerationMode: String, Codable {
    case standard
    case fastPreview = "fast_preview"
    case refine
}

final class AIService: ObservableObject {
    static let shared = AIService()

    private init() {}

    @Published private(set) var lastQuotaRemaining: Int = 0
    @Published private(set) var lastQuotaLimit: Int = 0
    @Published private(set) var lastQuotaReset: String? = nil
    @Published private(set) var lastRateLimitSeconds: Int? = nil
    @Published private(set) var lastCanvasSettings: CanvasSettings? = nil
    @Published private(set) var lastOperations: [AIEditOperation] = []
    private var lastGenerationID: String?
    private var pendingOutcomeGenerationID: String?
    private var outcomeTrackingStartedAt: Date?
    private var firstOutcomeEditAt: Date?
    private var lastCountedOutcomeEditAt: Date?
    private var pendingOutcomeEditCount = 0
    private var didReportOutcomeEdit = false
    private var latestOutcomeScreen: GenerationScreenSnapshot?
    private var keptOutcomeTask: Task<Void, Never>?

    private struct Payload: Codable {
        let prompt: String
        let context: [String: AnyCodable]
    }

    private struct QuotaPayload: Codable {
        let quota: Quota?
        let error: String?
    }

    private struct ResponsePayload: Codable {
        let components: [UIComponent]?
        let component: UIComponent?
        let ops: [AIEditOperation]?
        let mode: String?
        let canvasSettings: CanvasSettings?
        let quota: Quota?
        let error: String?
        let generationID: String?
        
        enum CodingKeys: String, CodingKey {
            case components, component, ops, mode, quota, error
            case canvasSettings = "canvas_settings"
            case generationID = "generation_id"
        }
    }

    private struct GenerationEventRequest: Encodable {
        let generation_event: GenerationEvent
    }

    private struct GenerationEvent: Encodable {
        let generation_id: String
        let event_type: String
        let final_screen: GenerationScreenSnapshot?
        let edit_count: Int
        let elapsed_ms: Int?
        let time_to_first_edit_ms: Int?
        let learning_consent: Bool
    }

    private struct GenerationScreenSnapshot: Encodable {
        let components: [UIComponent]
        let canvas_settings: CanvasSettings
    }

    private struct StreamResultPayload: Codable {
        let type: String?
        let components: [UIComponent]?
        let component: UIComponent?
        let ops: [AIEditOperation]?
        let mode: String?
        let canvasSettings: CanvasSettings?
        let quota: Quota?
        let error: String?
        
        enum CodingKeys: String, CodingKey {
            case type, components, component, ops, mode, quota, error
            case canvasSettings = "canvas_settings"
        }
    }

    struct CanvasSettings: Codable {
        let statusBarVisible: Bool?
        let statusBarTopSafeArea: Bool?
        let canvasColorScheme: String?
    }

    private struct Quota: Codable {
        let remaining: Int?
        let limit: Int?
        let reset: String?
        let rate_limit_seconds: Int?
    }

    @MainActor
    func generateComponents(prompt: String, context: [String: AnyCodable], generationMode: AIGenerationMode = .standard) async throws -> [UIComponent] {
        let supabase = SupabaseManager.shared.client
        guard supabase.auth.currentUser != nil else {
            print("AIService.generateComponents: not authenticated")
            throw AIServiceError.notAuthenticated
        }

        markRegenerationStarted()

        let accessToken: String
        do {
            accessToken = try await fetchAccessToken(from: supabase)
        } catch {
            let detail = error.localizedDescription.isEmpty ? "Session expired. Please sign in again." : error.localizedDescription
            print("AIService.generateComponents: token fetch failed error=\(error)")
            throw AIServiceError.requestFailed(detail)
        }
        let baseURL = SupabaseManager.shared.supabaseURL
        let endpoint = baseURL.appendingPathComponent("functions/v1/StudioAI")
        print("AIService.generateComponents: POST \(endpoint.absoluteString)")

        var requestContext = context
        requestContext["generation_mode"] = AnyCodable(generationMode.rawValue)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let payload = Payload(prompt: prompt, context: requestContext)
        request.httpBody = try JSONEncoder().encode(payload)
        print("AIService.generateComponents: promptLength=\(prompt.count) contextKeys=\(requestContext.keys.count) mode=\(generationMode.rawValue)")

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 60
        let session = URLSession(configuration: sessionConfig)

        print("AIService.generateComponents: starting request")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("AIService.generateComponents: request failed with error=\(error)")
            let detail = error.localizedDescription.isEmpty ? "Network request failed" : error.localizedDescription
            throw AIServiceError.requestFailed(detail)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("AIService.generateComponents: invalid response (no HTTPURLResponse)")
            throw AIServiceError.invalidResponse
        }
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
        print("AIService.generateComponents: status=\(httpResponse.statusCode) contentType=\(contentType) bodyBytes=\(data.count)")

        if !(200...299).contains(httpResponse.statusCode) {
            print("AIService.generateComponents: non-2xx status=\(httpResponse.statusCode) bodyBytes=\(data.count)")
            if let decoded = try? JSONDecoder().decode(ResponsePayload.self, from: data),
               let message = decoded.error {
                throw AIServiceError.requestFailed(userFacingErrorMessage(message))
            }
            throw AIServiceError.requestFailed("AI failed (\(httpResponse.statusCode))")
        }

        let decoded: ResponsePayload
        do {
            decoded = try JSONDecoder().decode(ResponsePayload.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("AIService.generateComponents: decode failed error=\(error) body=\(body)")
            throw AIServiceError.requestFailed("Invalid AI response")
        }
        if let message = decoded.error {
            print("AIService.generateComponents: error message=\(message)")
            throw AIServiceError.requestFailed(userFacingErrorMessage(message))
        }
        applyResponsePayload(decoded)
        return try components(from: decoded)
    }

    private func userFacingErrorMessage(_ message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let safeMessages = ["rate limit", "daily ai limit", "sign in", "session expired"]
        if safeMessages.contains(where: lower.contains) {
            return trimmed
        }

        return "AI couldn't complete that request. Please try again."
    }

    private func components(from payload: ResponsePayload) throws -> [UIComponent] {
        if payload.mode == "component", let component = payload.component {
            print("AIService.generateComponents: success single component")
            return [component]
        }
        if let components = payload.components, !components.isEmpty {
            print("AIService.generateComponents: success components=\(components.count)")
            return components
        }
        if payload.canvasSettings != nil {
            print("AIService.generateComponents: canvas settings only")
            return []
        }
        print("AIService.generateComponents: empty components")
        throw AIServiceError.emptyComponents
    }

    private func applyResponsePayload(_ decoded: ResponsePayload) {
        if let quota = decoded.quota {
            lastQuotaRemaining = quota.remaining ?? lastQuotaRemaining
            lastQuotaLimit = quota.limit ?? lastQuotaLimit
            lastQuotaReset = quota.reset
            lastRateLimitSeconds = quota.rate_limit_seconds
        }
        if let canvasSettings = decoded.canvasSettings {
            lastCanvasSettings = canvasSettings
        }
        lastOperations = decoded.ops ?? []
        lastGenerationID = decoded.generationID
    }

    @MainActor
    func consumeCanvasSettings() -> CanvasSettings? {
        let current = lastCanvasSettings
        lastCanvasSettings = nil
        return current
    }

    @MainActor
    func consumeOperations() -> [AIEditOperation]? {
        guard !lastOperations.isEmpty else { return nil }
        let current = lastOperations
        lastOperations = []
        return current
    }

    @MainActor
    func markGenerationApplied(components: [UIComponent], canvasSettings: CanvasSettings) {
        guard let generationID = lastGenerationID else { return }
        lastGenerationID = nil
        keptOutcomeTask?.cancel()
        pendingOutcomeGenerationID = generationID
        outcomeTrackingStartedAt = Date()
        firstOutcomeEditAt = nil
        lastCountedOutcomeEditAt = nil
        pendingOutcomeEditCount = 0
        didReportOutcomeEdit = false
        latestOutcomeScreen = makeGenerationScreenSnapshot(components: components, canvasSettings: canvasSettings)
        Task { await reportGenerationEvent(id: generationID, type: "applied") }
        keptOutcomeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled,
                  let self,
                  self.pendingOutcomeGenerationID == generationID else { return }
            self.reportTrackedGenerationEvent(type: "kept", terminal: false)
        }
    }

    @MainActor
    func markCanvasEditedAfterGeneration(components: [UIComponent], canvasSettings: CanvasSettings) {
        guard let generationID = pendingOutcomeGenerationID,
              let startedAt = outcomeTrackingStartedAt,
              Date().timeIntervalSince(startedAt) >= 1 else { return }
        let now = Date()
        if lastCountedOutcomeEditAt.map({ now.timeIntervalSince($0) >= 0.35 }) ?? true {
            pendingOutcomeEditCount += 1
            lastCountedOutcomeEditAt = now
            latestOutcomeScreen = makeGenerationScreenSnapshot(components: components, canvasSettings: canvasSettings)
        }
        if firstOutcomeEditAt == nil { firstOutcomeEditAt = now }
        guard !didReportOutcomeEdit else { return }
        didReportOutcomeEdit = true
        Task { await reportGenerationEvent(id: generationID, type: "edited") }
    }

    @MainActor
    private func markRegenerationStarted() {
        guard pendingOutcomeGenerationID != nil else { return }
        reportTrackedGenerationEvent(type: "regenerated", terminal: true)
    }

    @MainActor
    func markGenerationExported(components: [UIComponent], canvasSettings: CanvasSettings) {
        guard pendingOutcomeGenerationID != nil else { return }
        latestOutcomeScreen = makeGenerationScreenSnapshot(components: components, canvasSettings: canvasSettings)
        reportTrackedGenerationEvent(type: "exported", terminal: true)
    }

    @MainActor
    private func reportTrackedGenerationEvent(type: String, terminal: Bool) {
        guard let generationID = pendingOutcomeGenerationID else { return }
        let startedAt = outcomeTrackingStartedAt
        let firstEditAt = firstOutcomeEditAt
        let editCount = pendingOutcomeEditCount
        let finalScreen = latestOutcomeScreen
        let elapsedMs = startedAt.map { max(0, Int(Date().timeIntervalSince($0) * 1_000)) }
        let firstEditMs = startedAt.flatMap { start in
            firstEditAt.map { max(0, Int($0.timeIntervalSince(start) * 1_000)) }
        }

        if terminal {
            resetOutcomeTracking()
        }
        Task {
            await reportGenerationEvent(
                id: generationID,
                type: type,
                finalScreen: finalScreen,
                editCount: editCount,
                elapsedMs: elapsedMs,
                timeToFirstEditMs: firstEditMs
            )
        }
    }

    @MainActor
    private func resetOutcomeTracking() {
        keptOutcomeTask?.cancel()
        keptOutcomeTask = nil
        pendingOutcomeGenerationID = nil
        outcomeTrackingStartedAt = nil
        firstOutcomeEditAt = nil
        lastCountedOutcomeEditAt = nil
        pendingOutcomeEditCount = 0
        didReportOutcomeEdit = false
        latestOutcomeScreen = nil
    }

    @MainActor
    private func makeGenerationScreenSnapshot(components: [UIComponent], canvasSettings: CanvasSettings) -> GenerationScreenSnapshot {
        GenerationScreenSnapshot(components: components.map { $0.clone() }, canvas_settings: canvasSettings)
    }

    private func reportGenerationEvent(
        id: String,
        type: String,
        finalScreen: GenerationScreenSnapshot? = nil,
        editCount: Int = 0,
        elapsedMs: Int? = nil,
        timeToFirstEditMs: Int? = nil
    ) async {
        let supabase = SupabaseManager.shared.client
        guard supabase.auth.currentUser != nil,
              let accessToken = try? await fetchAccessToken(from: supabase) else { return }
        let endpoint = SupabaseManager.shared.supabaseURL.appendingPathComponent("functions/v1/StudioAI")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        request.httpBody = try? JSONEncoder().encode(GenerationEventRequest(
            generation_event: GenerationEvent(
                generation_id: id,
                event_type: type,
                final_screen: finalScreen,
                edit_count: editCount,
                elapsed_ms: elapsedMs,
                time_to_first_edit_ms: timeToFirstEditMs,
                learning_consent: false
            )
        ))
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("AIService.reportGenerationEvent failed status=\(httpResponse.statusCode) type=\(type)")
            }
        } catch {
            print("AIService.reportGenerationEvent failed type=\(type) error=\(error.localizedDescription)")
        }
    }

    @MainActor
    func refreshQuota() async {
        let supabase = SupabaseManager.shared.client
        guard supabase.auth.currentUser != nil else { return }

        let accessToken: String
        do {
            accessToken = try await fetchAccessToken(from: supabase)
        } catch {
            return
        }

        let baseURL = SupabaseManager.shared.supabaseURL
        let endpoint = baseURL.appendingPathComponent("functions/v1/StudioAI")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let payload = Payload(prompt: "quota check", context: [:])
        request.httpBody = try? JSONEncoder().encode(payload)

        let session = URLSession(configuration: .default)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else { return }

            if let decoded = try? JSONDecoder().decode(QuotaPayload.self, from: data),
               let quota = decoded.quota {
                lastQuotaRemaining = quota.remaining ?? lastQuotaRemaining
                lastQuotaLimit = quota.limit ?? lastQuotaLimit
                lastQuotaReset = quota.reset
                lastRateLimitSeconds = quota.rate_limit_seconds
            }
        } catch {
            return
        }
    }

    @MainActor
    private func fetchAccessToken(from supabase: SupabaseClient) async throws -> String {
        if let session = supabase.auth.currentSession {
            return session.accessToken
        }
        let session = try await supabase.auth.session
        return session.accessToken
    }

    @MainActor
    private func parseStreamResponse(bytes: URLSession.AsyncBytes, statusCode: Int) async throws -> [UIComponent] {
        var dataBuffer: [String] = []
        func flushBuffer() throws -> [UIComponent]? {
            guard !dataBuffer.isEmpty else { return nil }
            // Try each chunk first, then fall back to a joined payload.
            for chunk in dataBuffer {
                if let result = try handleStreamData(chunk) {
                    return result
                }
            }
            return try handleStreamData(dataBuffer.joined(separator: "\n"))
        }

        for try await line in bytes.lines {
            if line.isEmpty {
                if let result = try flushBuffer() {
                    print("AIService.parseStreamResponse: received result")
                    return result
                }
                dataBuffer.removeAll(keepingCapacity: true)
                continue
            }

            if line == "data: [DONE]" {
                if let result = try flushBuffer() {
                    print("AIService.parseStreamResponse: received result before done")
                    return result
                }
                dataBuffer.removeAll(keepingCapacity: true)
                print("AIService.parseStreamResponse: done marker received")
                break
            }

            if line.hasPrefix("data:") {
                let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                dataBuffer.append(payload)
            }
        }

        if !(200...299).contains(statusCode) {
            print("AIService.parseStreamResponse: non-2xx status=\(statusCode)")
            throw AIServiceError.requestFailed("AI failed (\(statusCode))")
        }

        print("AIService.parseStreamResponse: invalid response (no result)")
        throw AIServiceError.invalidResponse
    }

    private func handleStreamData(_ dataString: String) throws -> [UIComponent]? {
        guard let data = dataString.data(using: .utf8) else {
            return nil
        }

        // Prefer the streaming envelope, but fall back to direct payloads.
        if let streamResult = try? JSONDecoder().decode(StreamResultPayload.self, from: data) {
            if let message = streamResult.error {
                print("AIService.handleStreamData: error message=\(message)")
                throw AIServiceError.requestFailed(message)
            }
            if let canvasSettings = streamResult.canvasSettings {
                lastCanvasSettings = canvasSettings
            }
            lastOperations = streamResult.ops ?? []
            if streamResult.type == "result" {
                if streamResult.mode == "component", let component = streamResult.component {
                    print("AIService.handleStreamData: result single component")
                    return [component]
                }
                guard let components = streamResult.components, !components.isEmpty else {
                    print("AIService.handleStreamData: empty components")
                    throw AIServiceError.emptyComponents
                }
                print("AIService.handleStreamData: result components=\(components.count)")
                return components
            }
        }

        if let decoded = try? JSONDecoder().decode(ResponsePayload.self, from: data) {
            if let message = decoded.error {
                print("AIService.handleStreamData: error message=\(message)")
                throw AIServiceError.requestFailed(message)
            }
            if let canvasSettings = decoded.canvasSettings {
                lastCanvasSettings = canvasSettings
            }
            lastOperations = decoded.ops ?? []
            if decoded.mode == "component", let component = decoded.component {
                print("AIService.handleStreamData: direct single component")
                return [component]
            }
            if let components = decoded.components, !components.isEmpty {
                print("AIService.handleStreamData: direct components=\(components.count)")
                return components
            }
        }

        return nil
    }
}
