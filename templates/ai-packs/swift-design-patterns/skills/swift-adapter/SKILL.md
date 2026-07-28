---
name: swift-adapter
description: >
  Swift Adapter design pattern — Structural. Use when making incompatible interfaces work
  together, wrapping third-party SDKs, bridging Objective-C and Swift, or adding protocol
  conformance to existing types. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Adapter — Swift

> **Category**: Structural
> **Intent**: Adapter is a structural design pattern that allows objects with incompatible interfaces to collaborate. It acts as a wrapper between two objects, catching calls for one and transforming them to a format recognized by the other.

## When to Use

Use the Adapter pattern when you want to use an existing class but its interface is not compatible with the rest of your code. The pattern lets you create a middle-layer class that serves as a translator between your code and a legacy class, a 3rd-party class, or any other class with a weird interface.

This pattern is essential in iOS when integrating third-party SDKs that have different APIs than your app's protocols, when bridging Objective-C libraries into Swift code, or when you need to make unrelated classes work together without modifying their source code.

In Swift, extensions provide a particularly elegant way to implement the Adapter pattern — you can add protocol conformance to any existing type, effectively adapting it to a new interface without subclassing or wrapping.

## Structure

| Participant | Role |
|-------------|------|
| Target (Protocol) | Defines the domain-specific interface used by the client code. |
| Adaptee | Contains useful behavior but has an incompatible interface. |
| Adapter | Makes the Adaptee's interface compatible with the Target interface, either through wrapping or extension-based conformance. |

## Conceptual Example

```swift
import XCTest

class Target {
    func request() -> String {
        return "Target: The default target's behavior."
    }
}

class Adaptee {
    public func specificRequest() -> String {
        return ".eetpadA eht fo roivaheb laicepS"
    }
}

class Adapter: Target {
    private var adaptee: Adaptee

    init(_ adaptee: Adaptee) {
        self.adaptee = adaptee
    }

    override func request() -> String {
        return "Adapter: (TRANSLATED) " + adaptee.specificRequest().reversed()
    }
}

class Client {
    static func someClientCode(target: Target) {
        print(target.request())
    }
}

class AdapterConceptual: XCTestCase {
    func testAdapterConceptual() {
        print("Client: I can work just fine with the Target objects:")
        Client.someClientCode(target: Target())

        let adaptee = Adaptee()
        print("Client: The Adaptee class has a weird interface. See, I don't understand it:")
        print("Adaptee: " + adaptee.specificRequest())

        print("Client: But I can work with it via the Adapter:")
        Client.someClientCode(target: Adapter(adaptee))
    }
}
```

**Output:**
```
Client: I can work just fine with the Target objects:
Target: The default target's behavior.
Client: The Adaptee class has a weird interface. See, I don't understand it:
Adaptee: .eetpadA eht fo roivaheb laicepS
Client: But I can work with it via the Adapter:
Adapter: (TRANSLATED) Special behavior of the Adaptee.
```

## Real-World Example

```swift
import XCTest
import UIKit

class AdapterRealWorld: XCTestCase {
    func testAdapterRealWorld() {
        print("Starting an authorization via Facebook")
        startAuthorization(with: FacebookAuthSDK())

        print("Starting an authorization via Twitter.")
        startAuthorization(with: TwitterAuthSDK())
    }

    func startAuthorization(with service: AuthService) {
        let topViewController = UIViewController()
        service.presentAuthFlow(from: topViewController)
    }
}

protocol AuthService {
    func presentAuthFlow(from viewController: UIViewController)
}

class FacebookAuthSDK {
    func presentAuthFlow(from viewController: UIViewController) {
        print("Facebook WebView has been shown.")
    }
}

class TwitterAuthSDK {
    func startAuthorization(with viewController: UIViewController) {
        print("Twitter WebView has been shown. Users will be happy :)")
    }
}

extension TwitterAuthSDK: AuthService {
    /// Adapter: bridges Twitter's startAuthorization to AuthService's presentAuthFlow
    func presentAuthFlow(from viewController: UIViewController) {
        print("The Adapter is called! Redirecting to the original method...")
        self.startAuthorization(with: viewController)
    }
}

extension FacebookAuthSDK: AuthService {
    /// Facebook already matches — extension just declares conformance
}
```

**Output:**
```
Starting an authorization via Facebook
Facebook WebView has been shown.
Starting an authorization via Twitter.
The Adapter is called! Redirecting to the original method...
Twitter WebView has been shown. Users will be happy :)
```

## iOS Framework Usage

- **UIKit**: `UITableViewDataSource` / `UICollectionViewDataSource` adapt your model to UIKit's data requirements. `UIViewRepresentable` adapts UIKit views for SwiftUI.
- **SwiftUI**: `UIViewControllerRepresentable` and `UIViewRepresentable` are adapters bridging UIKit into SwiftUI. `Transferable` protocol adapts types for drag-and-drop.
- **Foundation**: `NSItemProvider` adapts arbitrary objects for cross-process transfer. `Codable` conformance adapts types for JSON/PropertyList serialization.

## Swift-Specific Notes

- **Extension-based adapters**: Swift extensions can add protocol conformance to any type — even types you don't own. This is the most idiomatic way to implement Adapter in Swift.
- **Protocol composition**: Use `typealias` to combine protocols: `typealias NetworkAdapter = URLSessionProtocol & RetryPolicy` for adapters that bridge multiple interfaces.
- **Objective-C bridging**: `@objc` protocol conformance and `NS_SWIFT_NAME` annotations are built-in adapter mechanisms between Swift and Objective-C.
- **Wrapper structs**: For complex adaptations, a lightweight struct wrapping the adaptee provides value semantics and clear ownership.
- **`where` clauses**: Conditional conformance (`extension Array: MyProtocol where Element: Codable`) enables powerful type-safe adapters.

## Related Patterns

- **Facade**: Both wrap existing interfaces, but Facade simplifies a complex subsystem while Adapter makes an existing interface compatible with a different one.
- **Decorator**: Both wrap objects, but Decorator adds behavior while Adapter changes the interface. Decorator keeps the same interface; Adapter provides a different one.
- **Bridge**: Bridge separates abstraction from implementation upfront. Adapter is applied to an existing system to make incompatible things work together.
