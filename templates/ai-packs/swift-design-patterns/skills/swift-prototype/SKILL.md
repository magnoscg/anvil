---
name: swift-prototype
description: >
  Swift Prototype design pattern — Creational. Use when you need to clone existing objects without
  coupling to their concrete classes, reduce subclass proliferation, or create pre-configured object
  templates. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Creational
  source: refactoring.guru
---

# Prototype — Swift

> **Category**: Creational
> **Intent**: Copy existing objects without making your code dependent on their classes.

## When to Use

Use the Prototype pattern when your code should not depend on the concrete classes of objects that you need to copy. This happens frequently when your code works with objects passed from third-party code via some interface. The concrete classes of these objects are unknown, and you could not depend on them even if you wanted to. The Prototype pattern provides the client code with a general interface for working with all objects that support cloning. This interface makes the client code independent from the concrete classes of objects that it clones.

The pattern is also valuable when you want to reduce the number of subclasses that only differ in the way they initialize their respective objects. Suppose you have a complex class that requires laborious configuration before it can be used. There are several common ways to configure this class, and this configuration code is scattered through your app. To reduce the duplication, you create several subclasses and put every common configuration code into their constructors. The Prototype pattern lets you use a set of pre-built objects configured in various ways as prototypes. Instead of instantiating a subclass that matches some configuration, the client can simply look for an appropriate prototype and clone it.

Consider Prototype whenever object creation is expensive (database queries, network requests, complex calculations) and you have an existing instance that is close to what you need. Cloning and then tweaking is often far cheaper than constructing from scratch. This is especially relevant for objects with deeply nested structures, where a deep copy via the Prototype pattern preserves the complete state without requiring knowledge of every internal detail.

## Structure

| Participant | Role |
|-------------|------|
| Prototype (protocol) | Declares the cloning interface. In Swift, this is typically the `NSCopying` protocol or a custom `clone()` method. |
| Concrete Prototype | Implements the cloning method. Handles copying its own fields, including private and internal ones, to the new instance. Must handle deep vs. shallow copy semantics. |
| Client | Produces a copy of any object that follows the prototype interface, without coupling to the object's concrete class. |
| Prototype Registry (optional) | Stores a catalog of frequently used prototypes for convenient access. Typically implemented as a dictionary mapping names/keys to pre-configured prototype instances. |

## Conceptual Example

```swift
import XCTest

class BaseClass: NSCopying, Equatable {

    private var intValue = 1
    private var stringValue = "Value"

    required init(intValue: Int = 1, stringValue: String = "Value") {
        self.intValue = intValue
        self.stringValue = stringValue
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let prototype = type(of: self).init()
        prototype.intValue = intValue
        prototype.stringValue = stringValue
        print("Values defined in BaseClass have been cloned!")
        return prototype
    }

    static func == (lhs: BaseClass, rhs: BaseClass) -> Bool {
        return lhs.intValue == rhs.intValue && lhs.stringValue == rhs.stringValue
    }
}

class SubClass: BaseClass {

    private var boolValue = true

    func copy() -> Any {
        return copy(with: nil)
    }

    override func copy(with zone: NSZone?) -> Any {
        guard let prototype = super.copy(with: zone) as? SubClass else {
            return SubClass()
        }
        prototype.boolValue = boolValue
        print("Values defined in SubClass have been cloned!")
        return prototype
    }
}

class Client {
    static func someClientCode() {
        let original = SubClass(intValue: 2, stringValue: "Value2")

        guard let copy = original.copy() as? SubClass else {
            XCTAssert(false)
            return
        }

        XCTAssert(copy == original)
        print("The original object is equal to the copied object!")
    }
}

class PrototypeConceptual: XCTestCase {
    func testPrototype_NSCopying() {
        Client.someClientCode()
    }
}
```

**Output:**

```
Values defined in BaseClass have been cloned!
Values defined in SubClass have been cloned!
The original object is equal to the copied object!
```

## Real-World Example

```swift
import XCTest

class PrototypeRealWorld: XCTestCase {

    func testPrototypeRealWorld() {

        let author = Author(id: 10, username: "Ivan_83")
        let page = Page(title: "My First Page", contents: "Hello world!", author: author)

        page.add(comment: Comment(message: "Keep it up!"))

        guard let anotherPage = page.copy() as? Page else {
            XCTFail("Page was not copied")
            return
        }

        XCTAssert(anotherPage.comments.isEmpty)
        XCTAssert(author.pagesCount == 2)

        print("Original title: " + page.title)
        print("Copied title: " + anotherPage.title)
        print("Count of pages: " + String(author.pagesCount))
    }
}

private class Author {

    private var id: Int
    private var username: String
    private var pages = [Page]()

    init(id: Int, username: String) {
        self.id = id
        self.username = username
    }

    func add(page: Page) {
        pages.append(page)
    }

    var pagesCount: Int {
        return pages.count
    }
}

private class Page: NSCopying {

    private(set) var title: String
    private(set) var contents: String
    private weak var author: Author?
    private(set) var comments = [Comment]()

    init(title: String, contents: String, author: Author?) {
        self.title = title
        self.contents = contents
        self.author = author
        author?.add(page: self)
    }

    func add(comment: Comment) {
        comments.append(comment)
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return Page(title: "Copy of '" + title + "'", contents: contents, author: author)
    }
}

private struct Comment {
    let date = Date()
    let message: String
}
```

**Output:**

```
Original title: My First Page
Copied title: Copy of 'My First Page'
Count of pages: 2
```

## iOS Framework Usage

- **UIKit**: `NSCopying` is the standard Prototype protocol throughout Apple's frameworks. `UIColor`, `NSAttributedString`, `UIImage`, `UIBezierPath`, and `NSMutableArray`/`NSMutableDictionary` all conform to `NSCopying`. `UIPasteboard` uses copying semantics to transfer data. `UIView` does not conform to `NSCopying` directly, but `NSKeyedArchiver`/`NSKeyedUnarchiver` round-tripping is used as a deep-copy mechanism for views and view controllers from storyboards/nibs.
- **SwiftUI**: SwiftUI's value-type architecture (structs for `View`, `State`, etc.) makes explicit cloning less necessary since structs are copied on assignment. However, when working with reference types (classes) inside `@Observable` or `ObservableObject`, the Prototype pattern is still relevant for duplicating model state without shared references.
- **Foundation**: `NSCopying` and `NSMutableCopying` are the Prototype interfaces throughout Foundation. `NSURLRequest` / `NSMutableURLRequest`, `NSPredicate`, `NSIndexPath`, `NSDateComponents`, and `NSCalendar` all support copying. `PropertyListSerialization` round-tripping is another form of deep cloning for property list types.

## Swift-Specific Notes

- Swift value types (structs and enums) get copy semantics for free -- assignment creates an independent copy via copy-on-write (COW). For value types, the Prototype pattern is unnecessary since `let copy = original` already produces a clone. The pattern is primarily needed for **reference types** (classes).
- For classes, implement `NSCopying` (Objective-C interop) or define a custom `func clone() -> Self` method. A `required init` copy initializer is another Swift-idiomatic approach: `required init(copying other: MyClass)`.
- Be deliberate about **deep vs. shallow copy**. The real-world example demonstrates a shallow copy where the cloned `Page` shares the same `Author` reference (via `weak var`), but starts with an empty comments array. Document your copy semantics explicitly.
- `Codable` round-tripping (`JSONEncoder` then `JSONDecoder`) provides a quick deep-clone mechanism for `Codable` types, though it is slower than manual copying and loses non-codable properties.
- When using actors or `Sendable` types in Swift concurrency, cloning is essential for safely transferring mutable state across isolation boundaries. The `Sendable` protocol effectively requires value semantics or explicit copying.
- Memory management: be careful with strong reference cycles in cloned objects. In the real-world example, `author` is `weak` to avoid retain cycles when multiple pages reference the same author.

## Related Patterns

- **Abstract Factory**: Can use Prototype internally to compose factory methods, cloning prototype instances rather than constructing new objects from scratch.
- **Composite**: Designs that make heavy use of Composite and Decorator can often benefit from Prototype for duplicating complex object trees.
- **Memento**: Can serve as a simpler alternative to Prototype when you need to store and restore object state, provided the object has no external resource links.
- **Singleton**: Prototype registries (catalogs of pre-configured prototypes) can be implemented as Singletons for centralized access.
