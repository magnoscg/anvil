---
name: swift-template-method
description: >
  Swift Template Method design pattern — Behavioral. Use when you need to define an algorithm
  skeleton with customizable steps, allow subclasses to override specific steps without changing
  structure, or use protocol default implementations for shared behavior.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Template Method — Swift

> **Category**: Behavioral
> **Intent**: Template Method is a behavioral design pattern that defines the skeleton of an algorithm in the superclass but lets subclasses override specific steps of the algorithm without changing its structure.

## When to Use

Use the Template Method pattern when you want to let clients extend only particular steps of an algorithm, but not the whole algorithm or its structure. The pattern suggests breaking the algorithm into a sequence of steps, turning them into methods, and putting a series of calls to these methods inside a single "template method." The steps can be abstract or have a default implementation.

This pattern is ideal when you have several classes that contain nearly identical algorithms with some minor differences. When you modify one algorithm, you need to change all classes. With Template Method, you pull the algorithm structure into a single method in a base class/protocol and let subclasses or conforming types provide their own implementations for the varying steps.

In Swift, protocol extensions with default implementations provide an elegant alternative to the class-based Template Method. The protocol defines required methods (the varying steps) while the extension provides the template method and default implementations for optional hooks.

## Structure

| Participant | Role |
|-------------|------|
| AbstractClass (Protocol) | Declares the template method and the steps. Provides default implementations for some steps via protocol extensions. |
| ConcreteClassA/B | Implements the required steps. May override default hook implementations. |

## Conceptual Example

```swift
import XCTest

protocol AbstractProtocol {
    func templateMethod()
    func baseOperation1()
    func baseOperation2()
    func baseOperation3()
    func requiredOperations1()
    func requiredOperation2()
    func hook1()
    func hook2()
}

extension AbstractProtocol {
    func templateMethod() {
        baseOperation1()
        requiredOperations1()
        baseOperation2()
        hook1()
        requiredOperation2()
        baseOperation3()
        hook2()
    }

    func baseOperation1() {
        print("AbstractProtocol says: I am doing the bulk of the work\n")
    }

    func baseOperation2() {
        print("AbstractProtocol says: But I let subclasses override some operations\n")
    }

    func baseOperation3() {
        print("AbstractProtocol says: But I am doing the bulk of the work anyway\n")
    }

    func hook1() {}
    func hook2() {}
}

class ConcreteClass1: AbstractProtocol {
    func requiredOperations1() {
        print("ConcreteClass1 says: Implemented Operation1\n")
    }

    func requiredOperation2() {
        print("ConcreteClass1 says: Implemented Operation2\n")
    }

    func hook2() {
        print("ConcreteClass1 says: Overridden Hook2\n")
    }
}

class ConcreteClass2: AbstractProtocol {
    func requiredOperations1() {
        print("ConcreteClass2 says: Implemented Operation1\n")
    }

    func requiredOperation2() {
        print("ConcreteClass2 says: Implemented Operation2\n")
    }

    func hook1() {
        print("ConcreteClass2 says: Overridden Hook1\n")
    }
}

class Client {
    static func clientCode(use object: AbstractProtocol) {
        object.templateMethod()
    }
}

class TemplateMethodConceptual: XCTestCase {
    func test() {
        print("Same client code can work with different subclasses:\n")
        Client.clientCode(use: ConcreteClass1())

        print("\nSame client code can work with different subclasses:\n")
        Client.clientCode(use: ConcreteClass2())
    }
}
```

**Output:**
```
Same client code can work with different subclasses:
AbstractProtocol says: I am doing the bulk of the work
ConcreteClass1 says: Implemented Operation1
AbstractProtocol says: But I let subclasses override some operations
ConcreteClass1 says: Implemented Operation2
AbstractProtocol says: But I am doing the bulk of the work anyway
ConcreteClass1 says: Overridden Hook2

Same client code can work with different subclasses:
AbstractProtocol says: I am doing the bulk of the work
ConcreteClass2 says: Implemented Operation1
AbstractProtocol says: But I let subclasses override some operations
ConcreteClass2 says: Overridden Hook1
ConcreteClass2 says: Implemented Operation2
AbstractProtocol says: But I am doing the bulk of the work anyway
```

## Real-World Example

```swift
import XCTest
import AVFoundation
import CoreLocation
import Photos

class TemplateMethodRealWorld: XCTestCase {
    func testTemplateMethodReal() {
        let accessors = [CameraAccessor(), MicrophoneAccessor(), PhotoLibraryAccessor()]

        accessors.forEach { item in
            item.requestAccessIfNeeded({ status in
                let message = status ? "You have access to " : "You do not have access to "
                print(message + item.description + "\n")
            })
        }
    }
}

class PermissionAccessor: CustomStringConvertible {
    typealias Completion = (Bool) -> ()

    func requestAccessIfNeeded(_ completion: @escaping Completion) {
        guard !hasAccess() else { completion(true); return }

        willReceiveAccess()

        requestAccess { status in
            status ? self.didReceiveAccess() : self.didRejectAccess()
            completion(status)
        }
    }

    func requestAccess(_ completion: @escaping Completion) {
        fatalError("Should be overridden")
    }

    func hasAccess() -> Bool {
        fatalError("Should be overridden")
    }

    var description: String { return "PermissionAccessor" }

    /// Hooks — optional steps with default empty implementations
    func willReceiveAccess() {}
    func didReceiveAccess() {}
    func didRejectAccess() {}
}

class CameraAccessor: PermissionAccessor {
    override func requestAccess(_ completion: @escaping Completion) {
        AVCaptureDevice.requestAccess(for: .video) { status in
            return completion(status)
        }
    }

    override func hasAccess() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    override var description: String { return "Camera" }
}

class MicrophoneAccessor: PermissionAccessor {
    override func requestAccess(_ completion: @escaping Completion) {
        AVAudioSession.sharedInstance().requestRecordPermission { status in
            completion(status)
        }
    }

    override func hasAccess() -> Bool {
        return AVAudioSession.sharedInstance().recordPermission == .granted
    }

    override var description: String { return "Microphone" }
}

class PhotoLibraryAccessor: PermissionAccessor {
    override func requestAccess(_ completion: @escaping Completion) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(status == .authorized)
        }
    }

    override func hasAccess() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }

    override var description: String { return "PhotoLibrary" }

    override func didReceiveAccess() {
        print("PhotoLibrary Accessor: Receive access. Updating analytics...")
    }

    override func didRejectAccess() {
        print("PhotoLibrary Accessor: Rejected with access. Updating analytics...")
    }
}
```

**Output:**
```
You have access to Camera
You have access to Microphone
PhotoLibrary Accessor: Rejected with access. Updating analytics...
You do not have access to PhotoLibrary
```

## iOS Framework Usage

- **UIKit**: `UIViewController` lifecycle is Template Method — `viewDidLoad()`, `viewWillAppear()`, `viewDidAppear()` are hooks in a fixed lifecycle sequence. `UICollectionViewLayout` requires subclasses to implement `layoutAttributesForElements(in:)`.
- **SwiftUI**: View protocol's `body` property is a required step; modifiers provide hooks. `ButtonStyle.makeBody(configuration:)` defines how a button renders while the framework handles the template.
- **Foundation**: `Hashable` requires `hash(into:)` while `Equatable` provides `!=` via template. `Codable` auto-synthesizes `encode(to:)` and `init(from:)` as a template with customizable `CodingKeys`.

## Swift-Specific Notes

- **Protocol extensions over inheritance**: Swift's protocol extensions provide a cleaner Template Method than class inheritance. Define required methods in the protocol, provide the template algorithm in the extension.
- **No abstract classes**: Swift has no `abstract` keyword. Use protocols with `fatalError("Must override")` for class-based approach, or protocols with required methods for the idiomatic approach.
- **Hooks via default implementations**: Protocol extensions can provide empty default implementations for optional hooks, just like the conceptual example above.
- **`@objc` for optional overrides**: When working with Objective-C runtime (UIKit subclassing), `@objc` methods in classes can be optionally overridden.
- **Generics**: Combine with generics for type-safe template methods: `protocol DataLoader { associatedtype Output; func parse(_ data: Data) -> Output }` with a shared `load(from:)` template.

## Related Patterns

- **Strategy**: Template Method uses inheritance/protocol conformance to vary parts of an algorithm. Strategy uses composition (delegation) to change the entire algorithm.
- **Factory Method**: Often a step within a Template Method — the template defines when objects are created, Factory Method defines what objects are created.
- **Observer**: Template Method steps can notify observers at each stage of the algorithm execution.
