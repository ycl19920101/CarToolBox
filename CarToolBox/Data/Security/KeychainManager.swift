//
//  KeychainManager.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation
import Security

// MARK: - Keychain Manager

/// Keychain Manager for secure storage of sensitive data
class KeychainManager {

    // MARK: - Keys

    enum Key: String, CaseIterable {
        case accessToken = "com.cartoolbox.accesstoken"
        case refreshToken = "com.cartoolbox.refreshtoken"
        case biometricEnabled = "com.cartoolbox.biometric.enabled"
        case userId = "com.cartoolbox.userid"
        case username = "com.cartoolbox.username"
        case rememberMe = "com.cartoolbox.rememberme"
        case lastLoginDate = "com.cartoolbox.lastlogindate"
    }

    // MARK: - Error

    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
        case encodingError
        case decodingError

        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "Keychain item not found"
            case .duplicateItem:
                return "Keychain item already exists"
            case .unexpectedStatus(let status):
                return "Unexpected keychain status: \(status)"
            case .encodingError:
                return "Encoding error"
            case .decodingError:
                return "Decoding error"
            }
        }
    }

    // MARK: - Shared Instance

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Generic Operations

    /// Save a value to keychain
    /// - Parameters:
    ///   - value: Value to save
    ///   - key: Key to save under
    ///   - accessibility: Accessibility level (default: afterFirstUnlock)
    ///   - isSynchronizable: Whether to sync with iCloud (default: false)
    func save<T: Codable>(_ value: T, for key: Key, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlock, isSynchronizable: Bool = false) throws {
        guard let encoded = try? JSONEncoder().encode(value) else {
            throw KeychainError.encodingError
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: encoded,
            kSecAttrAccessible as String: accessibility,
            kSecAttrSynchronizable as String: isSynchronizable
        ]

        // First try to add
        let status = SecItemAdd(query as CFDictionary, nil)

        // If duplicate, update
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key.rawValue
            ]

            let updateAttributes: [String: Any] = [
                kSecValueData as String: encoded,
                kSecAttrAccessible as String: accessibility,
                kSecAttrSynchronizable as String: isSynchronizable
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Load a value from keychain
    /// - Parameter key: Key to load
    /// - Returns: Decoded value
    func load<T: Codable>(for key: Key) throws -> T {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            throw KeychainError.decodingError
        }

        return decoded
    }

    /// Delete a value from keychain
    /// - Parameter key: Key to delete
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func delete(for key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    /// Check if a key exists in keychain
    /// - Parameter key: Key to check
    /// - Returns: True if exists, false otherwise
    func exists(for key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Delete all items for this app
    @discardableResult
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    // MARK: - String Convenience Methods

    /// Save a string value
    func saveString(_ value: String, for key: Key, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlock, isSynchronizable: Bool = false) throws {
        try save(value, for: key, accessibility: accessibility, isSynchronizable: isSynchronizable)
    }

    /// Load a string value
    func loadString(for key: Key) throws -> String {
        return try load(for: key)
    }

    // MARK: - Token Specific Methods

    /// Save access token
    func saveAccessToken(_ token: String, withBiometricProtection: Bool = false) throws {
        let accessibility: CFString = withBiometricProtection ?
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly : kSecAttrAccessibleAfterFirstUnlock
        try saveString(token, for: .accessToken, accessibility: accessibility)
    }

    /// Load access token
    func loadAccessToken() throws -> String {
        return try loadString(for: .accessToken)
    }

    /// Save refresh token
    func saveRefreshToken(_ token: String) throws {
        try saveString(token, for: .refreshToken)
    }

    /// Load refresh token
    func loadRefreshToken() throws -> String {
        return try loadString(for: .refreshToken)
    }

    /// Delete tokens
    func deleteTokens() {
        delete(for: .accessToken)
        delete(for: .refreshToken)
    }

    // MARK: - User Info Methods

    /// Save user ID
    func saveUserId(_ userId: String) throws {
        try saveString(userId, for: .userId)
    }

    /// Load user ID
    func loadUserId() throws -> String {
        return try loadString(for: .userId)
    }

    /// Save username
    func saveUsername(_ username: String) throws {
        try saveString(username, for: .username)
    }

    /// Load username
    func loadUsername() throws -> String {
        return try loadString(for: .username)
    }

    // MARK: - Settings Methods

    /// Enable biometric authentication
    func enableBiometric() throws {
        try save(true, for: .biometricEnabled)
    }

    /// Disable biometric authentication
    func disableBiometric() {
        delete(for: .biometricEnabled)
    }

    /// Check if biometric is enabled
    func isBiometricEnabled() -> Bool {
        return (try? load(for: .biometricEnabled)) ?? false
    }

    /// Set remember me preference
    func setRememberMe(_ enabled: Bool) throws {
        try save(enabled, for: .rememberMe)
    }

    /// Get remember me preference
    func getRememberMe() -> Bool {
        return (try? load(for: .rememberMe)) ?? false
    }

    /// Save last login date
    func saveLastLoginDate(_ date: Date) throws {
        try save(date.timeIntervalSince1970, for: .lastLoginDate)
    }

    /// Load last login date
    func loadLastLoginDate() -> Date? {
        guard let interval: Double = try? load(for: .lastLoginDate) else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    // MARK: - Debug Methods

    /// Print all items in keychain (for debugging)
    func debugPrintAllItems() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            print("No keychain items found")
            return
        }

        print("Keychain items:")
        for item in items {
            if let account = item[kSecAttrAccount as String] as? String {
                print("  - \(account)")
            }
        }
    }
}
