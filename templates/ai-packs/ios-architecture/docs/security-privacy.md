# Security & Privacy

Where secrets live, how the generated Keychain wrapper is used, and what an app must declare before it ships: Privacy Manifest, ATS, Data Protection and logging.

## What goes where

| Data | Store | Why |
|------|-------|-----|
| Tokens, passwords, any credential | Keychain, behind a Data-layer DataSource | Encrypted and tied to the device lock |
| Sensitive files | A file written with an explicit Data Protection level | Encrypted at rest |
| Non-sensitive preferences and caches | `UserDefaults`, from a Data-layer DataSource | Plain plist, readable from a backup |
| View-only UI state | `@AppStorage` | Same store as `UserDefaults` |
| Non-secret build configuration | xcconfig, read through `Info.plist` | Ships readable inside the bundle |

Never put a token, password or key in `UserDefaults` or `@AppStorage`.

## Keychain

`Core/Security/KeychainHelper.swift` is generated in every project:

```swift
enum KeychainError: Error, Sendable {
    case itemNotFound
    case duplicateItem
    case encodingFailed
    case decodingFailed
    case unexpectedStatus(OSStatus)
}

struct KeychainHelper: Sendable {
    func save(_ data: Data, for key: String) throws
    func retrieve(for key: String) throws -> Data
    func delete(for key: String) throws
    func save<T: Encodable>(_ item: T, for key: String) throws
    func read<T: Decodable>(for key: String) throws -> T
}
```

- `retrieve` and `read` throw `.itemNotFound` when the key is missing. `delete` treats a missing item as success. Any other failure is `.unexpectedStatus(OSStatus)`.
- The generic overloads store JSON and throw `.encodingFailed` or `.decodingFailed`. **One format per key**: a `String` passed straight to `save(_:for:)` selects the generic overload and is stored as quoted JSON, which does not round-trip through `retrieve` plus UTF-8 decoding. Read with the call that matches the write.
- The helper identifies an item by `key` alone, so keys are app-wide. Prefix them with the feature: `"article.session_token"`.

### Accessibility

The helper stores every item with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: excluded from backups and readable in the background after the first unlock. It takes no accessibility parameter. The criterion:

- A token read only while the app is in use: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. If the project never reads the Keychain in the background, tighten the level in `save`.
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` only for items read in the background (background refresh, push handling).
- `kSecAttrAccessibleAlways` and `kSecAttrAccessibleAlwaysThisDeviceOnly` are deprecated: do not use.
- A read that fails because the device is locked (`errSecInteractionNotAllowed`) does not mean the item is broken. Never delete an item on that error.
- Biometric gating needs `SecAccessControl`, which the helper does not cover.

### Keychain belongs to Data

Keychain access goes through a DataSource in Data. A View, ViewModel or UseCase never touches `KeychainHelper`: storage is an infrastructure detail, and the layers above see only the repository protocol. Answering yes to "Include Keychain storage?" in `anvil feature` generates `Data/Article/DataSources/ArticleKeychainDataSource.swift`:

```swift
protocol ArticleKeychainDataSource: Sendable {
    func save(_ value: String, forKey key: String) throws
    func read(forKey key: String) throws -> String?
    func delete(forKey key: String) throws
}
```

- `ArticleFactory` builds `ArticleKeychainDataSourceImpl(keychainHelper: KeychainHelper())` and injects it into `ArticleRepositoryImpl`.
- It stores strings as UTF-8 through the `Data` overloads of the helper.
- **Absence is explicit.** `read(forKey:)` returns `nil` only for `KeychainError.itemNotFound`; every other error propagates. Never wrap a Keychain call in `try?`: it turns a locked device or a damaged item into "signed out".
- The repository calls it inside `DomainError.catching`. A `KeychainError` that escapes maps to `DomainError.unknown`; add a `DomainError` case in `DomainErrorMapping.swift` if the UI must tell it apart.

```swift
func sessionToken() async throws -> String? {
    try await DomainError.catching {
        try keychainDataSource.read(forKey: "article.session_token")
    }
}
```

## Secrets

- **No secret in source.** A literal ships inside the binary and can be read with `strings`. Marking it `private` or base64-encoding it changes nothing.

```swift
let partnerKey = "any literal placed here ships in the binary"
```

- **xcconfig holds non-secret configuration only.** Its values are copied into `Info.plist`, which ships readable in the bundle. Base URL, API version, timeouts, environment name and pin hashes belong there. An API key does not.
- **User secrets** (session tokens) arrive at runtime and go to the Keychain.
- **App-level third-party keys** stay on a server you control: the app calls your backend and the backend calls the third party.
- Never commit a real value to an xcconfig, a fixture or a document.

## Logging

Logs can be read from Console and travel in sysdiagnoses. Never log a token, password or key. Mark any value that identifies a person as private, and apply the same rule to `print`:

```swift
logger.info("Signed in as \(email, privacy: .private)")
```

## Privacy Manifest

- The generator does not create `PrivacyInfo.xcprivacy`. Add one to the app target (File > New > File > App Privacy File) before the first submission.
- It declares tracking and tracking domains, collected data types, and every Required Reason API with a reason code. There are five categories: file timestamp, system boot time, disk space, active keyboard and user defaults. A build that uses one without declaring it is rejected automatically.
- `UserDefaults` always needs a declaration. A feature generated with a local data source (`ArticleLocalDataSourceImpl`) uses it, so declare `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1`, the code for information the app itself stored. `1C8F.1` is the code for information shared through an App Group. Declare the code that matches the real use.
- Each third-party SDK must ship its own manifest, and you answer for the data it collects.

## Transport and files

- **ATS** is on by default: `URLSession` requires HTTPS with TLS 1.2 or later, and the generated base URLs are `https`. Do not set `NSAllowsArbitraryLoads`: it disables ATS for the whole app, and App Review flags it and may reject. If one host cannot comply, add an exception for that domain under `NSExceptionDomains` and be ready to justify it. SSL pinning is in `networking.md`.
- **Data Protection.** Choose a level when you write a sensitive file. `.completeUntilFirstUserAuthentication` is the baseline for most app data, because the file stays readable in the background after the first unlock. Use `.complete` only for files touched while the device is unlocked: background work on a locked device fails with it. `.noFileProtection` leaves the file unencrypted, so keep it for data that is not sensitive at all.

```swift
try data.write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
```

## Before submitting

- [ ] No secret in source, xcconfig or `Info.plist`
- [ ] Credentials only in the Keychain, behind a Data-layer DataSource
- [ ] `PrivacyInfo.xcprivacy` covers every Required Reason API used by the app and its SDKs
- [ ] No `NSAllowsArbitraryLoads`; every ATS exception has a reason
- [ ] Real pins and a backup pin in the production xcconfig (`networking.md`)
- [ ] No token, password or personal value in logs
- [ ] `ITSAppUsesNonExemptEncryption` set in `Info.plist`: the generated one omits it, and the app uses CryptoKit to hash pins

Deeper reference (Axiom plugin, if installed): `axiom-security` (`skills/keychain.md`, `skills/keychain-ref.md`, `skills/file-protection-ref.md`) for the SecItem model, accessibility levels, `SecAccessControl` and protection levels, plus the `security-privacy-scanner` agent; `axiom-integration` (`skills/privacy-ux.md`) for the Privacy Manifest, reason codes and App Tracking Transparency; `axiom-shipping` (`skills/app-store-ref.md`) for submission requirements; `axiom-networking` (`skills/networking-diag.md`) for ATS.
