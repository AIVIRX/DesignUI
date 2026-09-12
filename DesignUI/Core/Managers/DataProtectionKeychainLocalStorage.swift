//
//  DataProtectionKeychainLocalStorage.swift
//  Dock UI
//
//  Keeps authentication sessions in the app's data-protection keychain on macOS.
//  This avoids the login-keychain access prompt that can appear when a session is
//  read or refreshed in the background.
//

import Foundation
import Security
import Auth

struct DataProtectionKeychainLocalStorage: AuthLocalStorage {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func store(key: String, value: Data) throws {
        let status = SecItemAdd(itemQuery(for: key, value: value) as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let attributes = [kSecValueData as String: value]
            try assertSuccess(SecItemUpdate(itemQuery(for: key) as CFDictionary, attributes as CFDictionary))
        } else {
            try assertSuccess(status)
        }
    }

    func retrieve(key: String) throws -> Data? {
        var query = itemQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        try assertSuccess(status)
        return result as? Data
    }

    func remove(key: String) throws {
        try assertSuccess(SecItemDelete(itemQuery(for: key) as CFDictionary))
    }

    private func itemQuery(for key: String, value: Data? = nil) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if let value {
            query[kSecValueData as String] = value
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        }

        #if os(macOS)
        // macOS 15+ gives apps an isolated, data-protection-backed keychain.
        // Include the flag in every operation so reads, updates, and deletion
        // resolve the same item that was created here.
        if #available(macOS 15.0, *) {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        #endif

        return query
    }

    private func assertSuccess(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) as String? ?? "Keychain operation failed."]
            )
        }
    }
}
