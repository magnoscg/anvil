---
name: swift-strategy
description: >
  Swift Strategy design pattern — Behavioral. Use when you need interchangeable algorithms,
  runtime behavior swapping, or replacing complex conditionals with strategy objects.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Strategy — Swift

> **Category**: Behavioral
> **Intent**: Strategy is a behavioral design pattern that turns a set of behaviors into objects and makes them interchangeable inside the original context object.

## When to Use

Use the Strategy pattern when you want to use different variants of an algorithm within an object and be able to switch from one algorithm to another during runtime. The pattern lets you isolate the code, internal data, and dependencies of various algorithms from the rest of the code, providing a simple interface for executing and switching between them.

This pattern is ideal when you have a class with a massive conditional operator that switches between different variants of the same algorithm. Strategy lets you extract all algorithms into separate classes that implement a common interface. The original object delegates execution to one of these objects instead of implementing all variants itself.

In Swift, closures often serve as lightweight strategies — `Array.sort(by:)` is a classic example. Use the full class-based pattern when strategies carry state, need multiple methods, or benefit from protocol conformance for dependency injection and testing.

## Structure

| Participant | Role |
|-------------|------|
| Context | Maintains a reference to a strategy object and delegates algorithmic work to it. |
| Strategy (Protocol) | Declares the interface common to all concrete strategies. |
| ConcreteStrategyA/B | Implements different variations of an algorithm the context uses. |

## Conceptual Example

```swift
import XCTest

class Context {
    private var strategy: Strategy

    init(strategy: Strategy) {
        self.strategy = strategy
    }

    func update(strategy: Strategy) {
        self.strategy = strategy
    }

    func doSomeBusinessLogic() {
        print("Context: Sorting data using the strategy (not sure how it'll do it)\n")
        let result = strategy.doAlgorithm(["a", "b", "c", "d", "e"])
        print(result.joined(separator: ","))
    }
}

protocol Strategy {
    func doAlgorithm<T: Comparable>(_ data: [T]) -> [T]
}

class ConcreteStrategyA: Strategy {
    func doAlgorithm<T: Comparable>(_ data: [T]) -> [T] {
        return data.sorted()
    }
}

class ConcreteStrategyB: Strategy {
    func doAlgorithm<T: Comparable>(_ data: [T]) -> [T] {
        return data.sorted(by: >)
    }
}

class StrategyConceptual: XCTestCase {
    func test() {
        let context = Context(strategy: ConcreteStrategyA())
        print("Client: Strategy is set to normal sorting.\n")
        context.doSomeBusinessLogic()

        print("\nClient: Strategy is set to reverse sorting.\n")
        context.update(strategy: ConcreteStrategyB())
        context.doSomeBusinessLogic()
    }
}
```

**Output:**
```
Client: Strategy is set to normal sorting.
Context: Sorting data using the strategy (not sure how it'll do it)
a,b,c,d,e
Client: Strategy is set to reverse sorting.
Context: Sorting data using the strategy (not sure how it'll do it)
e,d,c,b,a
```

## Real-World Example

```swift
import XCTest

class StrategyRealWorld: XCTestCase {
    func test() {
        let controller = ListController()
        let memoryStorage = MemoryStorage<User>()
        memoryStorage.add(usersFromNetwork())

        clientCode(use: controller, with: memoryStorage)
        clientCode(use: controller, with: CoreDataStorage())
        clientCode(use: controller, with: RealmStorage())
    }

    func clientCode(use controller: ListController, with dataSource: DataSource) {
        controller.update(dataSource: dataSource)
        controller.displayModels()
    }

    private func usersFromNetwork() -> [User] {
        let firstUser = User(id: 1, username: "username1")
        let secondUser = User(id: 2, username: "username2")
        return [firstUser, secondUser]
    }
}

class ListController {
    private var dataSource: DataSource?

    func update(dataSource: DataSource) {
        self.dataSource = dataSource
    }

    func displayModels() {
        guard let dataSource = dataSource else { return }
        let models = dataSource.loadModels() as [User]
        print("\nListController: Displaying models...")
        models.forEach({ print($0) })
    }
}

protocol DataSource {
    func loadModels<T: DomainModel>() -> [T]
}

class MemoryStorage<Model>: DataSource {
    private lazy var items = [Model]()

    func add(_ items: [Model]) {
        self.items.append(contentsOf: items)
    }

    func loadModels<T: DomainModel>() -> [T] {
        guard T.self == User.self else { return [] }
        return items as! [T]
    }
}

class CoreDataStorage: DataSource {
    func loadModels<T: DomainModel>() -> [T] {
        guard T.self == User.self else { return [] }
        return [User(id: 3, username: "username3"),
                User(id: 4, username: "username4")] as! [T]
    }
}

class RealmStorage: DataSource {
    func loadModels<T: DomainModel>() -> [T] {
        guard T.self == User.self else { return [] }
        return [User(id: 5, username: "username5"),
                User(id: 6, username: "username6")] as! [T]
    }
}

protocol DomainModel {
    var id: Int { get }
}

struct User: DomainModel {
    var id: Int
    var username: String
}
```

**Output:**
```
ListController: Displaying models...
User(id: 1, username: "username1")
User(id: 2, username: "username2")
ListController: Displaying models...
User(id: 3, username: "username3")
User(id: 4, username: "username4")
ListController: Displaying models...
User(id: 5, username: "username5")
User(id: 6, username: "username6")
```

## iOS Framework Usage

- **UIKit**: `UICollectionViewLayout` subclasses (flow layout, compositional layout) are strategies for arranging collection view cells. `UIViewPropertyAnimator` timing curves are animation strategies.
- **SwiftUI**: `ButtonStyle`, `ToggleStyle`, `LabelStyle` protocols are Strategy pattern — swap visual strategies for standard controls. `Animation` types (`.easeIn`, `.spring`) are timing strategies.
- **Foundation**: `JSONEncoder.DateEncodingStrategy`, `JSONEncoder.KeyEncodingStrategy`, `JSONDecoder.DateDecodingStrategy` — named strategies for serialization behavior. `sort(by:)` accepts a closure strategy.

## Swift-Specific Notes

- **Closures as strategies**: For simple, single-method strategies, Swift closures replace the full pattern: `func process(using strategy: (Data) -> Result)`.
- **Protocol-oriented**: Define strategies as protocols for complex, multi-method strategies that benefit from conformance checking and dependency injection.
- **Generics**: Combine with generics for type-safe strategies: `protocol SortStrategy { func sort<T: Comparable>(_ items: [T]) -> [T] }`.
- **Enums**: For a fixed set of strategies, use enums: `enum CompressionStrategy { case fast, balanced, best }` with computed properties for behavior.
- **Default implementations**: Protocol extensions can provide default strategy behavior that concrete strategies selectively override.

## Related Patterns

- **State**: Both change behavior at runtime. Strategy makes objects completely independent and unaware of each other. State may know about other states and trigger transitions.
- **Template Method**: Template Method uses inheritance to vary parts of an algorithm; Strategy uses composition to vary the entire algorithm.
- **Command**: Both encapsulate actions, but Command encapsulates a request with all needed info, while Strategy describes different ways of doing the same thing.
