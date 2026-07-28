---
name: swift-factory-method
description: >
  Swift Factory Method design pattern — Creational. Use when you need to decouple object creation
  from usage, let subclasses decide which class to instantiate, or provide a library/framework
  extension point. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Creational
  source: refactoring.guru
---

# Factory Method — Swift

> **Category**: Creational
> **Intent**: Provides an interface for creating objects in a superclass, but allows subclasses to alter the type of objects that will be created.

## When to Use

Use the Factory Method pattern when you do not know ahead of time the exact types and dependencies of the objects your code should work with. The Factory Method separates product construction code from the code that actually uses the product. This makes it easier to extend the product construction code independently from the rest of the code. For example, to add a new product type to the app, you only need to create a new creator subclass and override the factory method in it.

The pattern is also appropriate when you are building a library or framework and want to provide users with a way to extend its internal components. Inheritance is the easiest way to extend the default behavior of a library or framework. The Factory Method lets framework consumers plug in their own subclasses by overriding a single factory method, rather than modifying framework internals.

Factory Method also applies when you want to conserve system resources by reusing existing objects instead of rebuilding them each time. This is common with resource-intensive objects like database connections, file systems, or network sockets. With Factory Method, you have a natural place to put the creation/reuse logic -- inside the factory method itself -- rather than scattering it across client code. The method can check a pool, return an existing instance, or create a new one as needed.

## Structure

| Participant | Role |
|-------------|------|
| Product (protocol) | Declares the interface common to all objects that the factory method can produce. |
| Concrete Product | A specific implementation of the Product interface. |
| Creator (protocol/class) | Declares the factory method that returns Product objects. May also contain core business logic that relies on Product objects. |
| Concrete Creator | Overrides the factory method to return a specific Concrete Product. |
| Client | Calls the factory method through the Creator interface, remaining decoupled from concrete product classes. |

## Conceptual Example

```swift
import XCTest

/// The Creator protocol declares the factory method that's supposed to return a
/// new object of a Product class. The Creator's subclasses usually provide the
/// implementation of this method.
protocol Creator {

    /// Note that the Creator may also provide some default implementation of
    /// the factory method.
    func factoryMethod() -> Product

    /// Also note that, despite its name, the Creator's primary responsibility
    /// is not creating products. Usually, it contains some core business logic
    /// that relies on Product objects, returned by the factory method.
    /// Subclasses can indirectly change that business logic by overriding the
    /// factory method and returning a different type of product from it.
    func someOperation() -> String
}

/// This extension implements the default behavior of the Creator. This behavior
/// can be overridden in subclasses.
extension Creator {

    func someOperation() -> String {
        // Call the factory method to create a Product object.
        let product = factoryMethod()

        // Now, use the product.
        return "Creator: The same creator's code has just worked with " + product.operation()
    }
}

/// Concrete Creators override the factory method in order to change the
/// resulting product's type.
class ConcreteCreator1: Creator {

    /// Note that the signature of the method still uses the abstract product
    /// type, even though the concrete product is actually returned from the
    /// method. This way the Creator can stay independent of concrete product
    /// classes.
    public func factoryMethod() -> Product {
        return ConcreteProduct1()
    }
}

class ConcreteCreator2: Creator {

    public func factoryMethod() -> Product {
        return ConcreteProduct2()
    }
}

/// The Product protocol declares the operations that all concrete products must
/// implement.
protocol Product {

    func operation() -> String
}

/// Concrete Products provide various implementations of the Product protocol.
class ConcreteProduct1: Product {

    func operation() -> String {
        return "{Result of the ConcreteProduct1}"
    }
}

class ConcreteProduct2: Product {

    func operation() -> String {
        return "{Result of the ConcreteProduct2}"
    }
}


/// The client code works with an instance of a concrete creator, albeit through
/// its base protocol. As long as the client keeps working with the creator via
/// the base protocol, you can pass it any creator's subclass.
class Client {
    // ...
    static func someClientCode(creator: Creator) {
        print("Client: I'm not aware of the creator's class, but it still works.\n"
            + creator.someOperation())
    }
    // ...
}

/// Let's see how it all works together.
class FactoryMethodConceptual: XCTestCase {

    func testFactoryMethodConceptual() {

        /// The Application picks a creator's type depending on the
        /// configuration or environment.

        print("App: Launched with the ConcreteCreator1.")
        Client.someClientCode(creator: ConcreteCreator1())

        print("\nApp: Launched with the ConcreteCreator2.")
        Client.someClientCode(creator: ConcreteCreator2())
    }
}
```

**Output:**

```
App: Launched with the ConcreteCreator1.
Client: I'm not aware of the creator's class, but it still works.
Creator: The same creator's code has just worked with {Result of the ConcreteProduct1}

App: Launched with the ConcreteCreator2.
Client: I'm not aware of the creator's class, but it still works.
Creator: The same creator's code has just worked with {Result of the ConcreteProduct2}
```

## Real-World Example

```swift
import XCTest

class FactoryMethodRealWorld: XCTestCase {

    func testFactoryMethodRealWorld() {

        let info = "Very important info of the presentation"

        let clientCode = ClientCode()

        /// Present info over WiFi
        clientCode.present(info: info, with: WifiFactory())

        /// Present info over Bluetooth
        clientCode.present(info: info, with: BluetoothFactory())
    }
}

protocol ProjectorFactory {

    func createProjector() -> Projector

    func syncedProjector(with projector: Projector) -> Projector
}

extension ProjectorFactory {

    /// Base implementation of ProjectorFactory

    func syncedProjector(with projector: Projector) -> Projector {

        /// Every instance creates an own projector
        let newProjector = createProjector()

        /// sync projectors
        newProjector.sync(with: projector)

        return newProjector
    }
}

class WifiFactory: ProjectorFactory {

    func createProjector() -> Projector {
        return WifiProjector()
    }
}

class BluetoothFactory: ProjectorFactory {

    func createProjector() -> Projector {
        return BluetoothProjector()
    }
}

protocol Projector {

    /// Abstract projector interface

    var currentPage: Int { get }

    func present(info: String)

    func sync(with projector: Projector)

    func update(with page: Int)
}

extension Projector {

    /// Base implementation of Projector methods

    func sync(with projector: Projector) {
        projector.update(with: currentPage)
    }
}

class WifiProjector: Projector {

    var currentPage = 0

    func present(info: String) {
        print("Info is presented over Wifi: \(info)")
    }

    func update(with page: Int) {
        /// ... scroll page via WiFi connection
        /// ...
        currentPage = page
    }
}

class BluetoothProjector: Projector {

    var currentPage = 0

    func present(info: String) {
        print("Info is presented over Bluetooth: \(info)")
    }

    func update(with page: Int) {
        /// ... scroll page via Bluetooth connection
        /// ...
        currentPage = page
    }
}

private class ClientCode {

    private var currentProjector: Projector?

    func present(info: String, with factory: ProjectorFactory) {

        /// Check whether the client code is already presenting something...

        guard let projector = currentProjector else {

            /// 'currentProjector' variable is nil. Create a new projector and
            /// start presentation.

            let projector = factory.createProjector()
            projector.present(info: info)
            self.currentProjector = projector
            return
        }

        /// Client code already has a projector. Let's sync pages of the old
        /// projector with a new one.

        self.currentProjector = factory.syncedProjector(with: projector)
        self.currentProjector?.present(info: info)
    }
}
```

**Output:**

```
Info is presented over Wifi: Very important info of the presentation
Info is presented over Bluetooth: Very important info of the presentation
```

## iOS Framework Usage

- **UIKit**: `UICollectionView` and `UITableView` use a form of Factory Method through their cell registration and dequeue mechanisms (`dequeueReusableCell(withReuseIdentifier:for:)`). `UIStoryboard.instantiateViewController(withIdentifier:)` is another factory method that creates view controllers by identifier. `NSCoder`'s `decodeObject(forKey:)` family of methods also follow this pattern.
- **SwiftUI**: SwiftUI's `ViewBuilder` and `@ViewBuilder` closures act as factories that produce different view types based on conditions. Custom `View` conformances with `var body: some View` are conceptually factory methods that produce different view hierarchies. The `Scene` protocol and `WindowGroup`/`DocumentGroup` are scene factories.
- **Foundation**: `NumberFormatter.string(from:)`, `DateFormatter.string(from:)`, and `URLSession.dataTask(with:)` all follow the Factory Method pattern. `JSONDecoder.decode(_:from:)` produces different model types from the same decoding interface.

## Swift-Specific Notes

- In Swift, Factory Method is naturally expressed using **protocols with default implementations** (via protocol extensions) rather than abstract classes, since Swift does not have abstract classes.
- Use `associatedtype` in protocols when the factory method needs to return a type determined by the conforming type, enabling compile-time type safety.
- Generics can replace class hierarchies: a single generic factory function `func create<T: Product>(_ type: T.Type) -> T` can sometimes replace an entire Creator hierarchy.
- Swift's `Result` builders (`@resultBuilder`) provide a declarative form of factory method for building complex structures (views, queries, etc.).
- For testability, factory methods make it straightforward to inject mock/stub products in unit tests by providing a test creator.
- Consider using closures as lightweight factories: `let factory: () -> Product` avoids the need for a full Creator class when the pattern is simple.

## Related Patterns

- **Abstract Factory**: Often composed of multiple Factory Methods. Abstract Factory classes are frequently implemented using Factory Methods internally.
- **Template Method**: Factory Method is a specialization of Template Method. A factory method can serve as a step in a larger template method.
- **Prototype**: Does not require subclassing but needs a complex initialization operation. Factory Method requires subclassing but does not need initialization.
