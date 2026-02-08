import Foundation
import Supabase
import Functions

struct AIQuota: Decodable {
    let remaining: Int
    let limit: Int
    let reset: String?
    let rate_limit_seconds: Int?
}

struct AIGenerationResult {
    let components: [UIComponent]
    let quota: AIQuota?
}

enum AIServiceError: LocalizedError {
    case rateLimited(message: String, retryAfter: Int?, quota: AIQuota?)
    case server(message: String, quota: AIQuota?)
    case decode(message: String)

    var errorDescription: String? {
        switch self {
        case .rateLimited(let message, let retryAfter, _):
            if let retryAfter = retryAfter {
                return "\(message) (retry in \(retryAfter)s)"
            }
            return message
        case .server(let message, _):
            return message
        case .decode(let message):
            return message
        }
    }
}

class AIService {
    static let shared = AIService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    @MainActor
    func generateUI(prompt: String, context: [String: String]? = nil) async throws -> AIGenerationResult {
        struct AIPayload: Encodable {
            let prompt: String
            let context: [String: String]?
        }
        
        let payload = AIPayload(prompt: prompt, context: context)

        struct AIWrapper: Decodable {
            let components: [UIComponent]
            let quota: AIQuota?
        }
        
        struct AIErrorResponse: Decodable {
            let error: String
            let retry_after: Int?
            let quota: AIQuota?
        }
        
        let data: Data = try await client.functions.invoke(
            "StudioAI",
            options: FunctionInvokeOptions(body: payload)
        ) { data, _ in
            data
        }
        
        guard !data.isEmpty else {
            throw NSError(
                domain: "AIService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "AI response was empty"]
            )
        }
        
        let decoder = JSONDecoder()
        
        if let wrapper = try? decoder.decode(AIWrapper.self, from: data) {
            return AIGenerationResult(components: wrapper.components, quota: wrapper.quota)
        }
        
        if let errorWrapper = try? decoder.decode(AIErrorResponse.self, from: data) {
            // Treat rate-limit style responses as rate-limited
            if let retryAfter = errorWrapper.retry_after {
                throw AIServiceError.rateLimited(message: errorWrapper.error, retryAfter: retryAfter, quota: errorWrapper.quota)
            }
            if errorWrapper.error.lowercased().contains("limit") || errorWrapper.error.lowercased().contains("rate") {
                throw AIServiceError.rateLimited(message: errorWrapper.error, retryAfter: errorWrapper.retry_after, quota: errorWrapper.quota)
            }
            throw AIServiceError.server(message: errorWrapper.error, quota: errorWrapper.quota)
        }
        
        let rawString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        debugLog("❌ AI decode failed. Raw response: \(rawString)")
        
        throw AIServiceError.decode(message: "Failed to decode AI response. Raw: \(rawString)")
    }
}
