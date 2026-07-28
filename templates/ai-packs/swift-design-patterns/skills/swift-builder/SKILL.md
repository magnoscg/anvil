---
name: swift-builder
description: >
  Swift Builder design pattern — Creational. Use when you need to construct complex objects step by
  step, eliminate telescoping constructors, or build different representations of the same object.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Creational
  source: refactoring.guru
---

# Builder — Swift

> **Category**: Creational
> **Intent**: Construct complex objects step by step, allowing the same construction process to produce different representations.

## When to Use

Use the Builder pattern to get rid of a "telescoping constructor." Say you have a constructor with ten optional parameters. Calling such a beast is very inconvenient, so you overload the constructor and create several shorter versions with fewer parameters. These constructors still refer to the main one, passing default values into any omitted parameters. The Builder pattern lets you build objects step by step, using only those steps that you actually need. After implementing the pattern, you do not have to cram dozens of parameters into your constructors anymore.

The pattern is also valuable when you want your code to be able to create different representations of some product, for example stone and wooden houses. The construction of such products involves similar steps that differ only in the details. The Builder interface defines all possible construction steps, and concrete builders implement these steps to construct particular representations. A director class guides the order of construction, while concrete builders provide the implementation for specific product types.

Builder is especially useful for constructing composite trees or other complex object structures. The pattern lets you defer execution of some construction steps without breaking the final product. You can call steps recursively, which is handy when you need to build an object tree. A builder does not expose the unfinished product while running construction steps, preventing the client code from fetching an incomplete result.

## Structure

| Participant | Role |
|-------------|------|
| Builder (protocol) | Declares construction steps common to all types of builders. |
| Concrete Builder | Provides specific implementations of the construction steps. May produce products that do not follow a common interface. |
| Product | The resulting object. Products constructed by different builders do not have to belong to the same class hierarchy or interface. |
| Director | Defines the order in which to call construction steps, enabling reusable construction configurations. |
| Client | Associates a builder with the director, initiates construction, and retrieves the product from the builder. |

## Conceptual Example

```swift
import XCTest

protocol Builder {
    func producePartA()
    func producePartB()
    func producePartC()
}

class ConcreteBuilder1: Builder {
    private var product = Product1()

    func reset() {
        product = Product1()
    }

    func producePartA() {
        product.add(part: "PartA1")
    }

    func producePartB() {
        product.add(part: "PartB1")
    }

    func producePartC() {
        product.add(part: "PartC1")
    }

    func retrieveProduct() -> Product1 {
        let result = self.product
        reset()
        return result
    }
}

class Director {
    private var builder: Builder?

    func update(builder: Builder) {
        self.builder = builder
    }

    func buildMinimalViableProduct() {
        builder?.producePartA()
    }

    func buildFullFeaturedProduct() {
        builder?.producePartA()
        builder?.producePartB()
        builder?.producePartC()
    }
}

class Product1 {
    private var parts = [String]()

    func add(part: String) {
        self.parts.append(part)
    }

    func listParts() -> String {
        return "Product parts: " + parts.joined(separator: ", ") + "\n"
    }
}

class Client {
    static func someClientCode(director: Director) {
        let builder = ConcreteBuilder1()
        director.update(builder: builder)

        print("Standard basic product:")
        director.buildMinimalViableProduct()
        print(builder.retrieveProduct().listParts())

        print("Standard full featured product:")
        director.buildFullFeaturedProduct()
        print(builder.retrieveProduct().listParts())

        print("Custom product:")
        builder.producePartA()
        builder.producePartC()
        print(builder.retrieveProduct().listParts())
    }
}

class BuilderConceptual: XCTestCase {
    func testBuilderConceptual() {
        let director = Director()
        Client.someClientCode(director: director)
    }
}
```

**Output:**

```
Standard basic product:
Product parts: PartA1

Standard full featured product:
Product parts: PartA1, PartB1, PartC1

Custom product:
Product parts: PartA1, PartC1
```

## Real-World Example

```swift
import Foundation
import XCTest

class BaseQueryBuilder<Model: DomainModel> {
    typealias Predicate = (Model) -> (Bool)

    func limit(_ limit: Int) -> BaseQueryBuilder<Model> {
        return self
    }

    func filter(_ predicate: @escaping Predicate) -> BaseQueryBuilder<Model> {
        return self
    }

    func fetch() -> [Model] {
        preconditionFailure("Should be overridden in subclasses.")
    }
}

class RealmQueryBuilder<Model: DomainModel>: BaseQueryBuilder<Model> {
    enum Query {
        case filter(Predicate)
        case limit(Int)
    }

    fileprivate var operations = [Query]()

    @discardableResult
    override func limit(_ limit: Int) -> RealmQueryBuilder<Model> {
        operations.append(Query.limit(limit))
        return self
    }

    @discardableResult
    override func filter(_ predicate: @escaping Predicate) -> RealmQueryBuilder<Model> {
        operations.append(Query.filter(predicate))
        return self
    }

    override func fetch() -> [Model] {
        print("RealmQueryBuilder: Initializing RealmDataProvider with \(operations.count) operations:")
        return RealmProvider().fetch(operations)
    }
}

class CoreDataQueryBuilder<Model: DomainModel>: BaseQueryBuilder<Model> {
    enum Query {
        case filter(Predicate)
        case limit(Int)
        case includesPropertyValues(Bool)
    }

    fileprivate var operations = [Query]()

    override func limit(_ limit: Int) -> CoreDataQueryBuilder<Model> {
        operations.append(Query.limit(limit))
        return self
    }

    override func filter(_ predicate: @escaping Predicate) -> CoreDataQueryBuilder<Model> {
        operations.append(Query.filter(predicate))
        return self
    }

    func includesPropertyValues(_ toggle: Bool) -> CoreDataQueryBuilder<Model> {
        operations.append(Query.includesPropertyValues(toggle))
        return self
    }

    override func fetch() -> [Model] {
        print("CoreDataQueryBuilder: Initializing CoreDataProvider with \(operations.count) operations.")
        return CoreDataProvider().fetch(operations)
    }
}

class RealmProvider {
    func fetch<Model: DomainModel>(_ operations: [RealmQueryBuilder<Model>.Query]) -> [Model] {
        print("RealmProvider: Retrieving data from Realm...")

        for item in operations {
            switch item {
            case .filter(_):
                print("RealmProvider: executing the 'filter' operation.")
                break
            case .limit(_):
                print("RealmProvider: executing the 'limit' operation.")
                break
            }
        }

        return []
    }
}

class CoreDataProvider {
    func fetch<Model: DomainModel>(_ operations: [CoreDataQueryBuilder<Model>.Query]) -> [Model] {
        print("CoreDataProvider: Retrieving data from CoreData...")

        for item in operations {
            switch item {
            case .filter(_):
                print("CoreDataProvider: executing the 'filter' operation.")
                break
            case .limit(_):
                print("CoreDataProvider: executing the 'limit' operation.")
                break
            case .includesPropertyValues(_):
                print("CoreDataProvider: executing the 'includesPropertyValues' operation.")
                break
            }
        }

        return []
    }
}

protocol DomainModel {
}

private struct User: DomainModel {
    let id: Int
    let age: Int
    let email: String
}

class BuilderRealWorld: XCTestCase {
    func testBuilderRealWorld() {
        print("Client: Start fetching data from Realm")
        clientCode(builder: RealmQueryBuilder<User>())

        print()

        print("Client: Start fetching data from CoreData")
        clientCode(builder: CoreDataQueryBuilder<User>())
    }

    fileprivate func clientCode(builder: BaseQueryBuilder<User>) {
        let results = builder.filter({ $0.age < 20 })
            .limit(1)
            .fetch()

        print("Client: I have fetched: " + String(results.count) + " records.")
    }
}
```

**Output:**

```
Client: Start fetching data from Realm
RealmQueryBuilder: Initializing RealmDataProvider with 2 operations:
RealmProvider: Retrieving data from Realm...
RealmProvider: executing the 'filter' operation.
RealmProvider: executing the 'limit' operation.
Client: I have fetched: 0 records.

Client: Start fetching data from CoreData
CoreDataQueryBuilder: Initializing CoreDataProvider with 2 operations.
CoreDataProvider: Retrieving data from CoreData...
CoreDataProvider: executing the 'filter' operation.
CoreDataProvider: executing the 'limit' operation.
Client: I have fetched: 0 records.
```

## iOS Framework Usage

- **UIKit**: `NSAttributedString` construction often uses builder-like patterns with `NSMutableAttributedString` where you add attributes step by step. `UIAlertController` is built incrementally by adding actions and text fields. `NSFetchRequest` in Core Data is a builder where you configure predicates, sort descriptors, fetch limits, and batch sizes before executing.
- **SwiftUI**: SwiftUI's modifier chains (`.font()`, `.foregroundColor()`, `.padding()`, `.frame()`) are the quintessential builder pattern in modern Apple development. Each modifier returns a new modified view, enabling fluent step-by-step construction. `Animation` and `Transaction` objects are similarly built through chained configuration.
- **Foundation**: `URLComponents` is a builder for constructing URLs step by step (scheme, host, path, query items). `DateComponents` builds dates incrementally. `URLRequest` is configured step by step with HTTP method, headers, body, and cache policy before being passed to `URLSession`.

## Swift-Specific Notes

- Swift's **fluent API / method chaining** (returning `self` or `Self`) is the idiomatic way to implement Builder, as demonstrated in the real-world example with `builder.filter(...).limit(...).fetch()`.
- The `@resultBuilder` attribute (formerly `@_functionBuilder`) is Swift's compile-time builder pattern, used extensively in SwiftUI's `ViewBuilder`, `SceneBuilder`, and custom DSLs. It transforms declarative closure syntax into sequential builder method calls.
- Swift structs with default parameter values on `init` can often replace simple Builders. If all parameters are known at construction time and have reasonable defaults, a struct with named parameters achieves the same readability without the Builder overhead.
- Use `@discardableResult` on builder methods to suppress unused return value warnings when the chaining style is optional.
- Generics allow type-safe builders: `BaseQueryBuilder<Model: DomainModel>` ensures the builder and its products are type-consistent, as shown in the real-world example.
- For immutable products, have the builder accumulate configuration and produce the final product only in a `build()` or `fetch()` terminal method. This prevents partially-constructed objects from leaking.

## Related Patterns

- **Abstract Factory**: Abstract Factory returns products immediately; Builder lets you construct products step by step. Builder gives you fine-grained control over the construction process.
- **Composite**: Builder is often used to construct Composite trees, since the construction steps can be programmed to work recursively.
- **Bridge**: The director class plays the role of the abstraction, while different builders act as implementations.
- **Singleton**: Builder, Abstract Factory, and Prototype can all be implemented as Singletons when only one instance of the factory/builder is needed.
