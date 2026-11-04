# Security & Privacy Guide

> Security best practices and Privacy Manifest requirements for iOS apps.
> Related skill: `/axiom:audit security`
> Axiom complementa: Privacy Nutrition Labels, ATT UX

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

1. File → New → File → App Privacy
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
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>DDA9.1</string>
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

`Example/` ships `Core/Security/KeychainHelper.swift`: a caseless `enum` with `static` methods (no instance to create or inject).

```swift
// Core/Security/KeychainHelper.swift (signatures)
enum KeychainHelper {
    // MARK: - Errors

    enum KeychainError: Error, Equatable {
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case dataConversionError
    }

    // MARK: - Public Methods

    static func save(_ data: Data, forKey key: String) throws
    static func load(forKey key: String) throws -> Data
    static func delete(forKey key: String) throws
    static func exists(forKey key: String) -> Bool
}

// MARK: - Convenience Extensions

extension KeychainHelper {
    static func save(_ string: String, forKey key: String) throws
    static func loadString(forKey key: String) throws -> String
}
```

Behavior worth knowing:
- `save` deletes any existing item for the key, then adds the new one with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- `load` throws `.itemNotFound` when the key is missing and `.dataConversionError` when the result is not `Data`.
- `delete` treats `errSecItemNotFound` as success.
- `exists` returns `false` on any load error.

### Keychain Accessibility Options

| Option | Description |
|--------|-------------|
| `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Used by `KeychainHelper.save`. Available only while unlocked, not backed up. |
| `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | Use for secrets needed in the background after the first unlock (requires a variant of `save`). Not backed up. |
| `kSecAttrAccessibleWhenUnlocked` | Available only when unlocked |
| `kSecAttrAccessibleAlways` | **AVOID**. Always accessible. |

### Storing Tokens

Keychain access is persistence, so it belongs in a Data-layer DataSource, never in a ViewModel. `Example/` has no auth feature; this is the pattern to follow:

```swift
// Data/Auth/DataSources/AuthTokenKeychainDataSourceImpl.swift
struct AuthTokenKeychainDataSourceImpl: AuthTokenKeychainDataSource {
    // MARK: - Constants

    private enum Constants {
        static let tokenKey = "auth_token"
    }

    // MARK: - AuthTokenKeychainDataSource

    func saveToken(_ token: String) throws {
        try KeychainHelper.save(token, forKey: Constants.tokenKey)
    }

    func loadToken() throws -> String? {
        do {
            return try KeychainHelper.loadString(forKey: Constants.tokenKey)
        } catch KeychainHelper.KeychainError.itemNotFound {
            return nil
        }
    }

    func deleteToken() throws {
        try KeychainHelper.delete(forKey: Constants.tokenKey)
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

Store secrets with `KeychainHelper` from a Data-layer DataSource (see Storing Tokens above). The ViewModel calls a UseCase, which calls a Repository (wrapping failures in `DomainError.catching`), which uses the DataSource. ViewModels never touch the Keychain directly.

```swift
// RIGHT: Keychain behind a DataSource
try KeychainHelper.save(token, forKey: "auth_token")
```

---

## Hardcoded Secrets

### DON'T: Hardcode API Keys

```swift
// WRONG: Visible in binary
let apiKey = "sk-1234567890abcdef"

// WRONG: Still visible
private let apiKey = "sk-1234567890abcdef"

// WRONG: Even encoded is visible
let apiKey = String(data: Data(base64Encoded: "c2stMTIzNA==")!, encoding: .utf8)!
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
let token = try KeychainHelper.loadString(forKey: "auth_token")
```

---

## App Transport Security (ATS)

### Default: HTTPS Required

ATS is enabled by default. All connections must use HTTPS.

### Exception Configuration (When Necessary)

```xml
<!-- Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Allow specific domain with HTTP (avoid if possible) -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>legacy-api.example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

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
// Write file with protection
let data = sensitiveData
let url = documentsURL.appendingPathComponent("sensitive.dat")

try data.write(to: url, options: .completeFileProtection)

// Or set attribute explicitly
try FileManager.default.setAttributes(
    [.protectionKey: FileProtectionType.complete],
    ofItemAtPath: url.path
)
```

| Protection Level | When Available |
|------------------|----------------|
| `.complete` | Only when device unlocked |
| `.completeUnlessOpen` | Open files remain accessible |
| `.completeUntilFirstUserAuthentication` | After first unlock |
| `.none` | Always accessible (default) |

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

### Run Before Release

```bash
/axiom:audit security
```

The audit checks for:
- Hardcoded API keys and secrets
- Insecure @AppStorage usage
- Missing Privacy Manifest
- ATS violations
- Logging sensitive data

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
