# Security & Privacy Guide

> Security best practices and Privacy Manifest requirements for iOS apps.

## Overview

This guide covers security patterns, Privacy Manifests (required iOS 17+), and secure storage for iOS applications.

---

## Privacy Manifests (iOS 17+)

### What is a Privacy Manifest?

A `PrivacyInfo.xcprivacy` file that declares:
- Required Reason APIs your app uses
- Data types your app collects
- Tracking domains

**Required** for App Store submission starting Spring 2024.

### Creating Privacy Manifest

1. File -> New -> File -> App Privacy
2. Name: `PrivacyInfo.xcprivacy`
3. Add to your app target

### Required Reason APIs

APIs that require justification in Privacy Manifest:

| API Category | Examples | Common Reasons |
|--------------|----------|----------------|
| **File timestamp** | `NSFileCreationDate`, `NSFileModificationDate` | `DDA9.1` - Display to user |
| **System boot time** | `systemUptime`, `ProcessInfo.systemUptime` | `35F9.1` - Measure time intervals |
| **Disk space** | `volumeAvailableCapacity` | `E174.1` - Write files to disk |
| **User defaults** | `UserDefaults` | `CA92.1` - Access info from same app group |
| **Active keyboard** | `activeInputModes` | `54BD.1` - Customize keyboard UI |

### Privacy Manifest Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

---

## Secure Storage

### Storage Options Comparison

| Storage | Security | Use Case |
|---------|----------|----------|
| **Keychain** | Highest | Passwords, tokens, API keys |
| **Data Protection** | High | Sensitive files |
| **UserDefaults** | Low | Non-sensitive preferences |
| **@AppStorage** | Low | UI state only |

### Keychain Wrapper Pattern

The generator creates this wrapper in every project. It also adds Codable conveniences (`save(_ item: some Encodable, for:)` and `read(for:) -> T`), which throw `KeychainError.encodingFailed` / `.decodingFailed`.

```swift
// Core/Security/KeychainHelper.swift
import Foundation
import Security

// MARK: - KeychainError

enum KeychainError: Error, Sendable {
    case itemNotFound
    case duplicateItem
    case encodingFailed
    case decodingFailed
    case unexpectedStatus(OSStatus)
}

// MARK: - KeychainHelper

struct KeychainHelper: Sendable {

    // MARK: - Save

    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Retrieve

    func retrieve(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        return data
    }

    // MARK: - Delete

    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
```

### Keychain Accessibility Options

| Option | Description |
|--------|-------------|
| `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | **Recommended**. Available after first unlock, not backed up. |
| `kSecAttrAccessibleWhenUnlocked` | Available only when unlocked |
| `kSecAttrAccessibleAlways` | **AVOID**. Always accessible. |

### Storing Tokens

```swift
extension KeychainHelper {
    func saveToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else { return }
        try save(data, for: "auth_token")
    }

    func getToken() throws -> String? {
        let data = try retrieve(for: "auth_token")
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() throws {
        try delete(for: "auth_token")
    }
}
```

---

## Secure @AppStorage Alternative

### DON'T: Store Sensitive Data in @AppStorage

```swift
// WRONG: Tokens in UserDefaults
@AppStorage("authToken") var authToken: String = ""

// WRONG: API keys visible in UserDefaults
@AppStorage("apiKey") var apiKey: String = ""
```

### DO: Use Keychain for Sensitive Data

Keychain access belongs to the **Data** layer, never to a ViewModel. `anvil feature` can generate a `<Feature>KeychainDataSource` (protocol + Impl in `Data/<Feature>/DataSources/`) that wraps `KeychainHelper`; the repository uses it inside `DomainError.catching`, and the ViewModel only talks to its UseCase.

```swift
// Data/Auth/DataSources/AuthKeychainDataSource.swift

// MARK: - AuthKeychainDataSource

protocol AuthKeychainDataSource: Sendable {
    func saveToken(_ token: String) throws
    func readToken() throws -> String
    func deleteToken() throws
}

// MARK: - AuthKeychainDataSourceImpl

struct AuthKeychainDataSourceImpl: AuthKeychainDataSource {
    // MARK: - Properties

    private let keychainHelper: KeychainHelper
    private let tokenKey = "auth_token"

    // MARK: - Init

    init(keychainHelper: KeychainHelper) {
        self.keychainHelper = keychainHelper
    }

    // MARK: - Public Methods

    func saveToken(_ token: String) throws {
        try keychainHelper.save(token, for: tokenKey)
    }

    func readToken() throws -> String {
        try keychainHelper.read(for: tokenKey)
    }

    func deleteToken() throws {
        try keychainHelper.delete(for: tokenKey)
    }
}
```

Treat `KeychainError.itemNotFound` as "no token" explicitly in the repository instead of hiding every Keychain failure behind `try?`.

---

## Hardcoded Secrets

### DON'T: Hardcode API Keys

```swift
// WRONG: Visible in binary
let apiKey = "<REDACTED_SECRET>"
```

### DO: Use Configuration Files or Environment

```swift
// Option 1: Info.plist (for non-secret configuration)
let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String

// Option 2: xcconfig files (build-time injection)
// Create Debug.xcconfig and Release.xcconfig
// API_KEY = $(API_KEY)
// Access via Info.plist: $(API_KEY)

// Option 3: Keychain (for user-specific secrets)
let token = try keychain.getToken()
```

---

## App Transport Security (ATS)

### Default: HTTPS Required

ATS is enabled by default. All connections must use HTTPS.

### ATS Best Practices

| Practice | Description |
|----------|-------------|
| **Never disable ATS globally** | `NSAllowsArbitraryLoads = true` will be rejected |
| **Use exceptions sparingly** | Only for specific domains when absolutely necessary |
| **Document exceptions** | App Store review may ask for justification |
| **Minimum TLS 1.2** | Always require TLS 1.2 or higher |

---

## Data Protection

### File Protection Levels

```swift
let data = sensitiveData
let url = documentsURL.appendingPathComponent("sensitive.dat")

try data.write(to: url, options: .completeFileProtection)
```

| Protection Level | When Available |
|------------------|----------------|
| `.complete` | Only when device unlocked |
| `.completeUnlessOpen` | Open files remain accessible |
| `.completeUntilFirstUserAuthentication` | After first unlock |
| `.none` | Always accessible (default) |

---

## Logging Best Practices

### DON'T: Log Sensitive Data

```swift
// WRONG: Logging tokens
Logger.auth.info("Token: \(token)")

// RIGHT: Log without sensitive data
Logger.auth.info("Authentication succeeded")
```

---

## Pre-Submission Security Checklist

### Required

- [ ] **Privacy Manifest** created and includes all Required Reason APIs
- [ ] **No hardcoded secrets** in source code
- [ ] **Sensitive data in Keychain**, not UserDefaults
- [ ] **HTTPS only** (no ATS exceptions unless justified)

### Recommended

- [ ] **Certificate pinning** for critical endpoints
- [ ] **Biometric authentication** for sensitive operations
- [ ] **Jailbreak detection** for high-security apps
- [ ] **Code obfuscation** for sensitive logic

---

## Quick Reference

| Secret Type | Storage |
|-------------|---------|
| Auth tokens | Keychain |
| API keys | Keychain or xcconfig |
| User preferences | UserDefaults |
| UI state | @AppStorage |
| Sensitive files | Data Protection |
| Passwords | Keychain with biometric |
