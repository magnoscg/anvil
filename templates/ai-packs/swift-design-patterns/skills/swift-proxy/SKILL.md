---
name: swift-proxy
description: >
  Swift Proxy design pattern -- Structural. Use when controlling access to sensitive resources,
  adding lazy initialization, or implementing caching/logging layers transparently.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Proxy -- Swift

> **Category**: Structural
> **Intent**: Provide a surrogate or placeholder for another object to control access to it.

## When to Use

The Proxy pattern is appropriate when you need a more versatile or sophisticated reference to an object than a simple pointer. Common scenarios include: lazy initialization (virtual proxy) when the real object is resource-intensive; access control (protection proxy) when different clients should have different access rights; logging requests (logging proxy); and caching results (caching proxy).

Use Proxy in iOS when you need to guard access to sensitive data (biometrics before showing bank accounts), when you want to add transparent caching to network requests, or when you need to defer expensive object creation until first use. It is also useful for wrapping remote services behind a local interface that handles network details transparently.

In Swift, the Proxy pattern benefits greatly from protocol-oriented design. Both the real subject and proxy conform to the same protocol, making them interchangeable from the client's perspective. This is especially powerful with dependency injection -- you can swap a real service for a proxy in tests or in specific security contexts without changing client code.

## Structure

| Participant | Role |
|-------------|------|
| Subject (Protocol) | Declares the common interface for both RealSubject and Proxy so that a Proxy can be used anywhere a RealSubject is expected. |
| Real Subject | Contains the core business logic. The object that the proxy represents. |
| Proxy | Has a reference to the real subject. Controls access to it, may handle creation, caching, logging, or access control. Conforms to the same protocol as the real subject. |
| Client | Works with both real subjects and proxies via the Subject protocol. |

## Conceptual Example

```swift
import XCTest

protocol Subject {
    func request()
}

class RealSubject: Subject {
    func request() {
        print("RealSubject: Handling request.")
    }
}

class Proxy: Subject {
    private var realSubject: RealSubject

    init(_ realSubject: RealSubject) {
        self.realSubject = realSubject
    }

    func request() {
        if (checkAccess()) {
            realSubject.request()
            logAccess()
        }
    }

    private func checkAccess() -> Bool {
        print("Proxy: Checking access prior to firing a real request.")
        return true
    }

    private func logAccess() {
        print("Proxy: Logging the time of request.")
    }
}

class Client {
    static func clientCode(subject: Subject) {
        subject.request()
    }
}

class ProxyConceptual: XCTestCase {
    func test() {
        print("Client: Executing the client code with a real subject:")
        let realSubject = RealSubject()
        Client.clientCode(subject: realSubject)

        print("\nClient: Executing the same client code with a proxy:")
        let proxy = Proxy(realSubject)
        Client.clientCode(subject: proxy)
    }
}
```

**Output:**
```
Client: Executing the client code with a real subject:
RealSubject: Handling request.

Client: Executing the same client code with a proxy:
Proxy: Checking access prior to firing a real request.
RealSubject: Handling request.
Proxy: Logging the time of request.
```

## Real-World Example

```swift
import XCTest

class ProxyRealWorld: XCTestCase {
    func testProxyRealWorld() {
        print("Client: Loading a profile WITHOUT proxy")
        loadBasicProfile(with: Keychain())
        loadProfileWithBankAccount(with: Keychain())

        print("\nClient: Let's load a profile WITH proxy")
        loadBasicProfile(with: ProfileProxy())
        loadProfileWithBankAccount(with: ProfileProxy())
    }

    func loadBasicProfile(with service: ProfileService) {
        service.loadProfile(with: [.basic], success: { profile in
            print("Client: Basic profile is loaded")
        }) { error in
            print("Client: Cannot load a basic profile")
            print("Client: Error: " + error.localizedSummary)
        }
    }

    func loadProfileWithBankAccount(with service: ProfileService) {
        service.loadProfile(with: [.basic, .bankAccount], success: { profile in
            print("Client: Basic profile with a bank account is loaded")
        }) { error in
            print("Client: Cannot load a profile with a bank account")
            print("Client: Error: " + error.localizedSummary)
        }
    }
}

enum AccessField {
    case basic
    case bankAccount
}

protocol ProfileService {
    typealias Success = (Profile) -> ()
    typealias Failure = (LocalizedError) -> ()

    func loadProfile(with fields: [AccessField], success: Success, failure: Failure)
}

class ProfileProxy: ProfileService {
    private let keychain = Keychain()

    func loadProfile(with fields: [AccessField], success: Success, failure: Failure) {
        if let error = checkAccess(for: fields) {
            failure(error)
        } else {
            keychain.loadProfile(with: fields, success: success, failure: failure)
        }
    }

    private func checkAccess(for fields: [AccessField]) -> LocalizedError? {
        if fields.contains(.bankAccount) {
            switch BiometricsService.checkAccess() {
            case .authorized: return nil
            case .denied: return ProfileError.accessDenied
            }
        }
        return nil
    }
}

class Keychain: ProfileService {
    func loadProfile(with fields: [AccessField], success: Success, failure: Failure) {
        var profile = Profile()

        for item in fields {
            switch item {
            case .basic:
                let info = loadBasicProfile()
                profile.firstName = info[Profile.Keys.firstName.raw]
                profile.lastName = info[Profile.Keys.lastName.raw]
                profile.email = info[Profile.Keys.email.raw]
            case .bankAccount:
                profile.bankAccount = loadBankAccount()
            }
        }

        success(profile)
    }

    private func loadBasicProfile() -> [String : String] {
        return [Profile.Keys.firstName.raw : "Vasya",
                Profile.Keys.lastName.raw : "Pupkin",
                Profile.Keys.email.raw : "vasya.pupkin@gmail.com"]
    }

    private func loadBankAccount() -> BankAccount {
        return BankAccount(id: 12345, amount: 999)
    }
}

class BiometricsService {
    enum Access {
        case authorized
        case denied
    }

    static func checkAccess() -> Access {
        return .denied
    }
}

struct Profile {
    enum Keys: String {
        case firstName
        case lastName
        case email
    }

    var firstName: String?
    var lastName: String?
    var email: String?
    var bankAccount: BankAccount?
}

struct BankAccount {
    var id: Int
    var amount: Double
}

enum ProfileError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access is denied. Please enter a valid password"
        }
    }
}

extension RawRepresentable {
    var raw: Self.RawValue {
        return rawValue
    }
}

extension LocalizedError {
    var localizedSummary: String {
        return errorDescription ?? ""
    }
}
```

**Output:**
```
Client: Loading a profile WITHOUT proxy
Client: Basic profile is loaded
Client: Basic profile with a bank account is loaded

Client: Let's load a profile WITH proxy
Client: Basic profile is loaded
Client: Cannot load a profile with a bank account
Client: Error: Access is denied. Please enter a valid password
```

## iOS Framework Usage

- **UIKit**: `UIApperance` acts as a proxy that intercepts appearance-related property settings and applies them to all instances of a class. `NSProxy` (Objective-C heritage) is a dedicated base class for implementing proxy objects.
- **SwiftUI**: Property wrappers like `@AppStorage`, `@SceneStorage`, and `@FetchRequest` act as proxies to underlying storage (UserDefaults, scene state, Core Data) -- they provide transparent access while handling persistence behind the scenes.
- **Foundation/Combine**: `Lazy<T>` patterns and `NSURLProtocol` serve as proxies. `URLProtocol` lets you intercept and proxy all URL loading system requests for caching, mocking, or logging. Combine's `share()` operator creates a proxy publisher that multicasts to multiple subscribers.

## Swift-Specific Notes

- Define the shared interface as a Swift protocol rather than a base class -- this enables both value types (structs) and reference types (classes) to serve as either the real subject or the proxy.
- Use Swift's `@propertyWrapper` to create transparent proxy objects that intercept get/set operations, ideal for logging, validation, or lazy initialization patterns.
- Leverage Swift enums with associated values for access control results (like `BiometricsService.Access` in the real-world example) instead of Boolean returns, making the proxy's decision logic more expressive and extensible.
- Combine the Proxy pattern with Swift's `async/await` for virtual proxies that asynchronously load expensive resources on first access while immediately returning a lightweight placeholder.
- Use `weak` references from proxy to real subject when appropriate to avoid retain cycles, especially in iOS view controller hierarchies where proxies may outlive their subjects.

## Related Patterns

- **Adapter**: Provides a different interface to the wrapped object, while Proxy provides the same interface.
- **Decorator**: Adds responsibilities to objects, while Proxy controls access. A protection proxy may look similar to a decorator but has a fundamentally different intent.
- **Facade**: Both buffer a complex entity and initialize it on its own, but Facade's subject is usually not aware of the facade, while with Proxy the subject interface is matched exactly.
