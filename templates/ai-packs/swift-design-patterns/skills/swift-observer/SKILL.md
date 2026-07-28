---
name: swift-observer
description: >
  Swift Observer design pattern — Behavioral. Use when you need to notify multiple objects
  about state changes, implement event systems, or create publish-subscribe mechanisms.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Observer — Swift

> **Category**: Behavioral
> **Intent**: Observer is a behavioral design pattern that lets you define a subscription mechanism to notify multiple objects about any events that happen to the object they're observing.

## When to Use

Use the Observer pattern when changes to the state of one object may require changing other objects, and the actual set of objects is unknown beforehand or changes dynamically. This is common in GUI programming where button clicks, text field changes, and slider movements need to trigger updates in multiple parts of the interface.

The Observer pattern is also valuable when some objects in your app must observe others but only for a limited time or in specific cases. The subscription list is dynamic — subscribers can join or leave at any time. This makes it ideal for event-driven architectures, real-time data feeds, and reactive UI updates.

Choose Observer when you need loose coupling between the subject (publisher) and its dependents (subscribers). Instead of the subject knowing about concrete observer classes, it communicates through a shared protocol. This decoupling makes both sides independently extensible and testable.

## Structure

| Participant | Role |
|-------------|------|
| Subject (Publisher) | Maintains a list of observers and provides methods to attach/detach them. Notifies all observers when state changes. |
| Observer (Subscriber) | Declares the update interface used by the subject to notify observers. |
| ConcreteObserverA/B | Implements the Observer interface and reacts to notifications from the subject. |

## Conceptual Example

```swift
import XCTest

/// The Subject owns some important state and notifies observers when the state
/// changes.
class Subject {

    var state: Int = { return Int(arc4random_uniform(10)) }()

    private lazy var observers = [Observer]()

    func attach(_ observer: Observer) {
        print("Subject: Attached an observer.\n")
        observers.append(observer)
    }

    func detach(_ observer: Observer) {
        if let idx = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: idx)
            print("Subject: Detached an observer.\n")
        }
    }

    func notify() {
        print("Subject: Notifying observers...\n")
        observers.forEach({ $0.update(subject: self)})
    }

    func someBusinessLogic() {
        print("\nSubject: I'm doing something important.\n")
        state = Int(arc4random_uniform(10))
        print("Subject: My state has just changed to: \(state)\n")
        notify()
    }
}

protocol Observer: AnyObject {
    func update(subject: Subject)
}

class ConcreteObserverA: Observer {
    func update(subject: Subject) {
        if subject.state < 3 {
            print("ConcreteObserverA: Reacted to the event.\n")
        }
    }
}

class ConcreteObserverB: Observer {
    func update(subject: Subject) {
        if subject.state >= 3 {
            print("ConcreteObserverB: Reacted to the event.\n")
        }
    }
}

class ObserverConceptual: XCTestCase {
    func testObserverConceptual() {
        let subject = Subject()
        let observer1 = ConcreteObserverA()
        let observer2 = ConcreteObserverB()

        subject.attach(observer1)
        subject.attach(observer2)

        subject.someBusinessLogic()
        subject.someBusinessLogic()
        subject.detach(observer2)
        subject.someBusinessLogic()
    }
}
```

**Output:**
```
Subject: Attached an observer.
Subject: Attached an observer.
Subject: I'm doing something important.
Subject: My state has just changed to: 4
Subject: Notifying observers...
ConcreteObserverB: Reacted to the event.
Subject: I'm doing something important.
Subject: My state has just changed to: 2
Subject: Notifying observers...
ConcreteObserverA: Reacted to the event.
Subject: Detached an observer.
Subject: I'm doing something important.
Subject: My state has just changed to: 8
Subject: Notifying observers...
```

## Real-World Example

```swift
import XCTest

class ObserverRealWorld: XCTestCase {
    func test() {
        let cartManager = CartManager()
        let navigationBar = UINavigationBar()
        let cartVC = CartViewController()

        cartManager.add(subscriber: navigationBar)
        cartManager.add(subscriber: cartVC)

        let apple = Food(id: 111, name: "Apple", price: 10, calories: 20)
        cartManager.add(product: apple)

        let tShirt = Clothes(id: 222, name: "T-shirt", price: 200, size: "L")
        cartManager.add(product: tShirt)

        cartManager.remove(product: apple)
    }
}

protocol CartSubscriber: CustomStringConvertible {
    func accept(changed cart: [Product])
}

protocol Product {
    var id: Int { get }
    var name: String { get }
    var price: Double { get }
    func isEqual(to product: Product) -> Bool
}

extension Product {
    func isEqual(to product: Product) -> Bool {
        return id == product.id
    }
}

struct Food: Product {
    var id: Int
    var name: String
    var price: Double
    var calories: Int
}

struct Clothes: Product {
    var id: Int
    var name: String
    var price: Double
    var size: String
}

class CartManager {
    private lazy var cart = [Product]()
    private lazy var subscribers = [CartSubscriber]()

    func add(subscriber: CartSubscriber) {
        print("CartManager: I'am adding a new subscriber: \(subscriber.description)")
        subscribers.append(subscriber)
    }

    func add(product: Product) {
        print("\nCartManager: I'am adding a new product: \(product.name)")
        cart.append(product)
        notifySubscribers()
    }

    func remove(subscriber filter: (CartSubscriber) -> (Bool)) {
        guard let index = subscribers.firstIndex(where: filter) else { return }
        subscribers.remove(at: index)
    }

    func remove(product: Product) {
        guard let index = cart.firstIndex(where: { $0.isEqual(to: product) }) else { return }
        print("\nCartManager: Product '\(product.name)' is removed from a cart")
        cart.remove(at: index)
        notifySubscribers()
    }

    private func notifySubscribers() {
        subscribers.forEach({ $0.accept(changed: cart) })
    }
}

extension UINavigationBar: CartSubscriber {
    func accept(changed cart: [Product]) {
        print("UINavigationBar: Updating an appearance of navigation items")
    }
    open override var description: String { return "UINavigationBar" }
}

class CartViewController: UIViewController, CartSubscriber {
    func accept(changed cart: [Product]) {
        print("CartViewController: Updating an appearance of a list view with products")
    }
    open override var description: String { return "CartViewController" }
}
```

**Output:**
```
CartManager: I'am adding a new subscriber: UINavigationBar
CartManager: I'am adding a new subscriber: CartViewController
CartManager: I'am adding a new product: Apple
UINavigationBar: Updating an appearance of navigation items
CartViewController: Updating an appearance of a list view with products
CartManager: I'am adding a new product: T-shirt
UINavigationBar: Updating an appearance of navigation items
CartViewController: Updating an appearance of a list view with products
CartManager: Product 'Apple' is removed from a cart
UINavigationBar: Updating an appearance of navigation items
CartViewController: Updating an appearance of a list view with products
```

## iOS Framework Usage

- **UIKit**: `NotificationCenter` is the classic Observer implementation. KVO (Key-Value Observing) lets you observe property changes on `NSObject` subclasses. `UIControl.addTarget(_:action:for:)` is event-based observation.
- **SwiftUI**: `@Observable` (Observation framework), `@ObservedObject`/`@StateObject` with `ObservableObject` + `@Published` properties automatically notify views of changes.
- **Combine**: `Publisher`/`Subscriber` protocol pair. `CurrentValueSubject`, `PassthroughSubject`, `.sink()`, `.assign(to:on:)` for reactive observation chains.

## Swift-Specific Notes

- **Observation framework** (`@Observable` macro, iOS 17+): The modern way to implement Observer in Swift — compiler-synthesized change tracking with no boilerplate.
- **Combine framework**: Provides a declarative, chainable API for observation with operators like `map`, `filter`, `debounce`, `combineLatest`.
- **Memory management**: Use `[weak self]` in closure-based observers and `AnyCancellable` sets in Combine to avoid retain cycles.
- **Thread safety**: `NotificationCenter` delivers on the posting thread. Use `receive(on: DispatchQueue.main)` in Combine to ensure UI updates on the main thread.
- **Protocol-oriented**: Define `Observer` as a protocol with `AnyObject` constraint to enable `===` identity checks and `weak` references.

## Related Patterns

- **Mediator**: While Observer distributes communication by introducing observer and subject objects, Mediator centralizes communication through a mediator object.
- **Command**: Can be used together — Command objects can be observers that react to state changes by executing queued operations.
- **Chain of Responsibility**: Handlers in the chain can act as observers, processing events as they propagate.
