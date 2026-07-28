---
name: swift-bridge
description: >
  Swift Bridge design pattern — Structural. Use when you need to separate abstraction from
  implementation so both can vary independently, support cross-platform rendering, or decouple
  high-level logic from platform-specific details. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Bridge — Swift

> **Category**: Structural
> **Intent**: Bridge is a structural design pattern that lets you split a large class or a set of closely related classes into two separate hierarchies — abstraction and implementation — which can be developed independently of each other.

## When to Use

Use the Bridge pattern when you want to divide and organize a monolithic class that has several variants of some functionality (e.g., working with various database servers or UI platforms). The pattern lets you split the class into several class hierarchies, each varying independently.

This pattern is ideal when you need to extend a class in several orthogonal (independent) dimensions. Instead of growing a single class hierarchy exponentially, Bridge suggests extracting one of the dimensions into a separate hierarchy, so the original class references an object of the new hierarchy instead of having all state and behaviors in one class.

In iOS, Bridge is useful when building cross-platform features (iOS/macOS/watchOS), supporting multiple sharing services, rendering engines, or any scenario where you want to decouple "what" from "how."

## Structure

| Participant | Role |
|-------------|------|
| Abstraction | High-level control layer. Delegates work to the Implementation object. |
| Refined Abstraction | Extends the Abstraction with additional operations. |
| Implementation (Protocol) | Declares the interface common to all concrete implementations. |
| Concrete Implementation | Platform-specific implementation of the Implementation interface. |

## Conceptual Example

```swift
import XCTest

class Abstraction {
    fileprivate var implementation: Implementation

    init(_ implementation: Implementation) {
        self.implementation = implementation
    }

    func operation() -> String {
        let operation = implementation.operationImplementation()
        return "Abstraction: Base operation with:\n" + operation
    }
}

class ExtendedAbstraction: Abstraction {
    override func operation() -> String {
        let operation = implementation.operationImplementation()
        return "ExtendedAbstraction: Extended operation with:\n" + operation
    }
}

protocol Implementation {
    func operationImplementation() -> String
}

class ConcreteImplementationA: Implementation {
    func operationImplementation() -> String {
        return "ConcreteImplementationA: Here's the result on the platform A.\n"
    }
}

class ConcreteImplementationB: Implementation {
    func operationImplementation() -> String {
        return "ConcreteImplementationB: Here's the result on the platform B.\n"
    }
}

class Client {
    static func someClientCode(abstraction: Abstraction) {
        print(abstraction.operation())
    }
}

class BridgeConceptual: XCTestCase {
    func testBridgeConceptual() {
        let implementation = ConcreteImplementationA()
        Client.someClientCode(abstraction: Abstraction(implementation))

        let concreteImplementation = ConcreteImplementationB()
        Client.someClientCode(abstraction: ExtendedAbstraction(concreteImplementation))
    }
}
```

**Output:**
```
Abstraction: Base operation with:
ConcreteImplementationA: Here's the result on the platform A.

ExtendedAbstraction: Extended operation with:
ConcreteImplementationB: Here's the result on the platform B.
```

## Real-World Example

```swift
import XCTest
import UIKit

protocol SharingSupportable {
    func accept(service: SharingService)
    func update(content: Content)
}

class BaseViewController: UIViewController, SharingSupportable {
    fileprivate var shareService: SharingService?

    func update(content: Content) {
        print("\(description): User selected a \(content) to share")
        shareService?.share(content: content)
    }

    func accept(service: SharingService) {
        shareService = service
    }
}

class PhotoViewController: BaseViewController {
    override var description: String { return "PhotoViewController" }
}

class FeedViewController: BaseViewController {
    override var description: String { return "FeedViewController" }
}

protocol SharingService {
    func share(content: Content)
}

class FaceBookSharingService: SharingService {
    func share(content: Content) {
        print("Service: \(content) was posted to the Facebook")
    }
}

class InstagramSharingService: SharingService {
    func share(content: Content) {
        print("Service: \(content) was posted to the Instagram\n")
    }
}

protocol Content: CustomStringConvertible {
    var title: String { get }
    var images: [UIImage] { get }
}

struct FoodDomainModel: Content {
    var title: String
    var images: [UIImage]
    var calories: Int
    var description: String { return "Food Model" }
}

class BridgeRealWorld: XCTestCase {
    func testBridgeRealWorld() {
        print("Client: Pushing Photo View Controller...")
        push(PhotoViewController())

        print()

        print("Client: Pushing Feed View Controller...")
        push(FeedViewController())
    }

    func push(_ container: SharingSupportable) {
        let instagram = InstagramSharingService()
        let facebook = FaceBookSharingService()
        let foodModel = FoodDomainModel(title: "This food is so various and delicious!",
                                         images: [UIImage(), UIImage()],
                                         calories: 47)

        container.accept(service: instagram)
        container.update(content: foodModel)

        container.accept(service: facebook)
        container.update(content: foodModel)
    }
}
```

**Output:**
```
Client: Pushing Photo View Controller...
PhotoViewController: User selected a Food Model to share
Service: Food Model was posted to the Instagram

PhotoViewController: User selected a Food Model to share
Service: Food Model was posted to the Facebook

Client: Pushing Feed View Controller...
FeedViewController: User selected a Food Model to share
Service: Food Model was posted to the Instagram

FeedViewController: User selected a Food Model to share
Service: Food Model was posted to the Facebook
```

## iOS Framework Usage

- **UIKit**: `UIDevice` / `UIScreen` bridge hardware details from the OS. `UIPrintInteractionController` bridges app content to printer-specific rendering.
- **SwiftUI**: View protocol bridges your declarative description to platform-specific rendering (UIKit on iOS, AppKit on macOS). `ViewModifier` bridges modifiable behavior to view rendering.
- **Foundation**: `FileManager` bridges file operations across platforms. `URLSession` bridges networking across different transport implementations.

## Swift-Specific Notes

- **Protocols as implementations**: Swift protocols naturally serve as the Implementation interface. Protocol-oriented programming makes Bridge a natural fit.
- **Dependency injection**: The Bridge pattern is essentially dependency injection at the architectural level — inject the implementation into the abstraction.
- **Generics**: Use generic constraints to bind abstraction to implementation at compile time: `class Renderer<T: RenderingEngine>`.
- **Value types**: For lightweight bridges, use structs with protocol-typed properties instead of class hierarchies.
- **Testability**: Bridge makes both sides independently testable — mock the implementation protocol for abstraction tests.

## Related Patterns

- **Adapter**: Adapter makes unrelated classes work together after they're designed. Bridge is designed upfront to let abstraction and implementation vary independently.
- **Abstract Factory**: Can create objects for a Bridge. When the Bridge abstraction can only work with specific implementations, Abstract Factory encapsulates creation.
- **Strategy**: Both use composition with a protocol. Bridge focuses on structural separation; Strategy focuses on swapping algorithms at runtime.
