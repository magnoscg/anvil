import Foundation
import Security

// MARK: - KeychainHelper

/// Helper for secure storage of sensitive data in the iOS Keychain.
/// Use this instead of @AppStorage or UserDefaults for tokens, credentials, and secrets.
enum KeychainHelper {
    // MARK: - Errors

    enum KeychainError: Error, Equatable {
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case dataConversionError
    }

    // MARK: - Public Methods

    /// Saves data securely to the Keychain.
    /// - Parameters:
    ///   - data: The data to store.
    ///   - key: The key to identify the stored data.
    /// - Throws: `KeychainError` if the operation fails.
    static func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecValueData as String: data,
                                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Loads data from the Keychain.
    /// - Parameter key: The key identifying the stored data.
    /// - Returns: The stored data.
    /// - Throws: `KeychainError` if the item is not found or the operation fails.
    static func load(forKey key: String) throws -> Data {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.dataConversionError
        }

        return data
    }

    /// Deletes data from the Keychain.
    /// - Parameter key: The key identifying the data to delete.
    /// - Throws: `KeychainError` if the operation fails (except for item not found).
    static func delete(forKey key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Checks if an item exists in the Keychain.
    /// - Parameter key: The key to check.
    /// - Returns: `true` if the item exists, `false` otherwise.
    static func exists(forKey key: String) -> Bool {
        do {
            _ = try load(forKey: key)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainHelper {
    /// Saves a string securely to the Keychain.
    /// - Parameters:
    ///   - string: The string to store.
    ///   - key: The key to identify the stored data.
    /// - Throws: `KeychainError` if the operation fails.
    static func save(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        try save(data, forKey: key)
    }

    /// Loads a string from the Keychain.
    /// - Parameter key: The key identifying the stored data.
    /// - Returns: The stored string.
    /// - Throws: `KeychainError` if the item is not found or the operation fails.
    static func loadString(forKey key: String) throws -> String {
        let data = try load(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        return string
    }
}
