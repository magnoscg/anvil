---
name: swift-facade
description: >
  Swift Facade design pattern -- Structural. Use when simplifying complex subsystem interfaces,
  wrapping third-party libraries, or providing a unified API over multiple services.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Facade -- Swift

> **Category**: Structural
> **Intent**: Provide a simplified interface to a complex subsystem of classes, libraries, or frameworks.

## When to Use

The Facade pattern is appropriate when you need to provide a simple interface to a complex subsystem. Subsystems often grow in complexity as they evolve -- applying design patterns typically leads to more, smaller classes. A subsystem becomes more flexible and easier to customize, but it also becomes harder to use for clients that do not need to customize it. A facade offers a simple default view of the subsystem that is good enough for most clients.

Use Facade when you want to layer your subsystems. Define an entry point to each subsystem level with a facade. If subsystems are dependent, you can simplify the dependencies between them by making them communicate solely through their facades. This is especially common in iOS when wrapping networking, caching, and persistence layers behind a single service object.

In Swift specifically, facades are valuable when coordinating between multiple frameworks (e.g., AVFoundation + CoreImage + Photos) or when you need to hide the complexity of asynchronous operations behind a synchronous-looking API. Consider a facade when client code repeatedly uses the same group of objects together in the same sequence.

## Structure

| Participant | Role |
|-------------|------|
| Facade | Provides convenient access to a particular part of the subsystem's functionality. Knows where to direct the client's request and how to operate all the moving parts. |
| Additional Facade | Can be created to prevent polluting a single facade with unrelated features that would make it yet another complex structure. |
| Subsystem Classes | Implement detailed subsystem functionality. Handle work assigned by the facade object. Have no knowledge of the facade and keep no reference to it. |
| Client | Uses the facade instead of calling subsystem objects directly. |

## Conceptual Example

```swift
import XCTest

class Facade {
    private var subsystem1: Subsystem1
    private var subsystem2: Subsystem2

    init(subsystem1: Subsystem1 = Subsystem1(),
         subsystem2: Subsystem2 = Subsystem2()) {
        self.subsystem1 = subsystem1
        self.subsystem2 = subsystem2
    }

    func operation() -> String {
        var result = "Facade initializes subsystems:"
        result += " " + subsystem1.operation1()
        result += " " + subsystem2.operation1()
        result += "\n" + "Facade orders subsystems to perform the action:\n"
        result += " " + subsystem1.operationN()
        result += " " + subsystem2.operationZ()
        return result
    }
}

class Subsystem1 {
    func operation1() -> String {
        return "Subsystem1: Ready!\n"
    }

    func operationN() -> String {
        return "Subsystem1: Go!\n"
    }
}

class Subsystem2 {
    func operation1() -> String {
        return "Subsystem2: Get ready!\n"
    }

    func operationZ() -> String {
        return "Subsystem2: Fire!\n"
    }
}

class Client {
    static func clientCode(facade: Facade) {
        print(facade.operation())
    }
}

class FacadeConceptual: XCTestCase {
    func testFacadeConceptual() {
        let subsystem1 = Subsystem1()
        let subsystem2 = Subsystem2()
        let facade = Facade(subsystem1: subsystem1, subsystem2: subsystem2)
        Client.clientCode(facade: facade)
    }
}
```

**Output:**
```
Facade initializes subsystems: Subsystem1: Ready!
Subsystem2: Get ready!

Facade orders subsystems to perform the action:
Subsystem1: Go!
Subsystem2: Fire!
```

## Real-World Example

```swift
import XCTest

class FacadeRealWorld: XCTestCase {
    func testFacadeRealWorld() {
        let imageView = UIImageView()
        print("Let's set an image for the image view")
        clientCode(imageView)
        print("Image has been set")
        XCTAssert(imageView.image != nil)
    }

    fileprivate func clientCode(_ imageView: UIImageView) {
        let url = URL(string: "www.example.com/logo")
        imageView.downloadImage(at: url)
    }
}

private extension UIImageView {
    func downloadImage(at url: URL?) {
        print("Start downloading...")
        let placeholder = UIImage(named: "placeholder")
        ImageDownloader().loadImage(at: url,
                                    placeholder: placeholder,
                                    completion: { image, error in
            print("Handle an image...")
            self.image = image
        })
    }
}

private class ImageDownloader {
    typealias Completion = (UIImage, Error?) -> ()
    typealias Progress = (Int, Int) -> ()

    func loadImage(at url: URL?,
                   placeholder: UIImage? = nil,
                   progress: Progress? = nil,
                   completion: Completion) {
        completion(UIImage(), nil)
    }
}
```

**Output:**
```
Let's set an image for the image view
Start downloading...
Handle an image...
Image has been set
```

## iOS Framework Usage

- **UIKit**: `UIImagePickerController` is a facade over AVFoundation's capture session, camera device management, and Photos framework. `UIApplication` itself acts as a facade coordinating window management, event dispatch, and app lifecycle.
- **SwiftUI**: The `Environment` and `EnvironmentObject` system acts as a facade, letting views access complex dependency graphs through simple property wrappers without knowing the underlying injection mechanism.
- **Foundation/Combine**: `URLSession` is a classic facade over socket management, HTTP protocol handling, authentication challenges, caching, and cookie storage. `JSONDecoder`/`JSONEncoder` facades hide the complexity of the underlying serialization engine.

## Swift-Specific Notes

- Use default parameter values in the facade initializer (`init(subsystem1: Subsystem1 = Subsystem1())`) to allow easy testing while keeping the simple interface for production use.
- Swift extensions on existing types (like `UIImageView` in the real-world example) provide a natural way to add facade methods without subclassing, keeping the API close to the type it enhances.
- Mark subsystem classes as `private` or `internal` and expose only the facade as `public` to enforce encapsulation at the module level using Swift's access control.
- Combine facades with Swift's `async/await` to present a clean asynchronous API that hides callback-based subsystem complexity (e.g., wrapping `URLSession` + `JSONDecoder` + `CoreData` behind a single `async throws` method).
- Consider using protocols for the facade interface to enable dependency injection and facilitate unit testing with mock facades.

## Related Patterns

- **Adapter**: Wraps an existing interface to make it compatible, while Facade defines a new simplified interface for a whole subsystem.
- **Abstract Factory**: Can serve as an alternative to Facade when you want to hide only the way subsystem objects are created from client code.
- **Mediator**: Organizes collaboration between multiple objects, while Facade merely simplifies the interface without adding new functionality.
