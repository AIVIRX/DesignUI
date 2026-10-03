import Foundation
import Supabase

enum DockUIDesignPublisherError: LocalizedError {
    case notAuthorized
    case missingSession
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "This account is not allowed to publish designs."
        case .missingSession:
            return "Sign in to publish this design."
        case .invalidResponse:
            return "DockUI returned an invalid publishing response."
        case .requestFailed(let message):
            return message
        }
    }
}

struct DockUIPublishedDesign: Decodable {
    let id: String
    let slug: String
}

/// Publishes a local canvas through the server-side `PublishDesign` Edge Function.
/// The function repeats the account check before it writes Storage or the posts table.
@MainActor
final class DockUIDesignPublisher {
    static let shared = DockUIDesignPublisher()

    static let permittedUploaderID = UUID(uuidString: "ab52fbc5-e8bc-47e9-82ff-7b8abd970d54")!

    private let supabase = SupabaseManager.shared.client

    private init() {}

    var canPublish: Bool {
        supabase.auth.currentUser?.id == Self.permittedUploaderID
    }

    func publish(
        title: String,
        codeSnippet: String,
        designJSON: String,
        previewPNG: Data
    ) async throws -> DockUIPublishedDesign {
        guard canPublish else { throw DockUIDesignPublisherError.notAuthorized }
        guard !previewPNG.isEmpty, previewPNG.count <= 3_000_000 else {
            throw DockUIDesignPublisherError.requestFailed("The preview image must be smaller than 3 MB.")
        }

        let accessToken: String
        if let session = supabase.auth.currentSession {
            accessToken = session.accessToken
        } else {
            do {
                accessToken = try await supabase.auth.session.accessToken
            } catch {
                throw DockUIDesignPublisherError.missingSession
            }
        }

        guard let designObject = try? JSONSerialization.jsonObject(with: Data(designJSON.utf8)) else {
            throw DockUIDesignPublisherError.requestFailed("Could not prepare the design for publishing.")
        }

        let payload = PublishPayload(
            title: title,
            code_snippet: codeSnippet,
            design_json: AnyEncodable(designObject),
            preview_png_base64: previewPNG.base64EncodedString()
        )
        let endpoint = SupabaseManager.shared.supabaseURL.appendingPathComponent("functions/v1/PublishDesign")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DockUIDesignPublisherError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(PublishError.self, from: data).error)
                ?? "Publishing failed (HTTP \(httpResponse.statusCode))."
            throw DockUIDesignPublisherError.requestFailed(message)
        }
        guard let published = try? JSONDecoder().decode(DockUIPublishedDesign.self, from: data) else {
            throw DockUIDesignPublisherError.invalidResponse
        }
        return published
    }
}

private struct PublishPayload: Encodable {
    let title: String
    let code_snippet: String
    let design_json: AnyEncodable
    let preview_png_base64: String
}

private struct PublishError: Decodable {
    let error: String
}

private struct AnyEncodable: Encodable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as String: try container.encode(value)
        case let value as Bool: try container.encode(value)
        case let value as Int: try container.encode(value)
        case let value as Double: try container.encode(value)
        case let value as [Any]: try container.encode(value.map(AnyEncodable.init))
        case let value as [String: Any]: try container.encode(value.mapValues(AnyEncodable.init))
        default: try container.encodeNil()
        }
    }
}
