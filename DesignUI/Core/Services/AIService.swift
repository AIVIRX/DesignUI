import Foundation
import Supabase
import Functions

class AIService {
    static let shared = AIService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    @MainActor
    func generateUI(prompt: String, context: [String: String]? = nil) async throws -> [UIComponent] {
        struct AIPayload: Encodable {
            let prompt: String
            let context: [String: String]?
        }
        
        let payload = AIPayload(prompt: prompt, context: context)

        struct AIWrapper: Decodable {
            let components: [UIComponent]
        }
        
        struct AIErrorResponse: Decodable {
            let error: String
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
            return wrapper.components
        }
        
        if let errorWrapper = try? decoder.decode(AIErrorResponse.self, from: data) {
            throw NSError(
                domain: "AIService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: errorWrapper.error]
            )
        }
        
        let rawString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        debugLog("❌ AI decode failed. Raw response: \(rawString)")
        
        throw NSError(
            domain: "AIService",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Failed to decode AI response. Raw: \(rawString)"]
        )
    }
}
