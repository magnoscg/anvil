---
name: swift-iterator
description: >
  Swift Iterator design pattern -- Behavioral. Use when traversing custom collections,
  implementing multiple traversal strategies, or hiding collection internals from clients.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Iterator -- Swift

> **Category**: Behavioral
> **Intent**: Let you traverse elements of a collection without exposing its underlying representation (list, stack, tree, etc.).

## When to Use

The Iterator pattern is appropriate when your collection has a complex data structure under the hood, but you want to hide its complexity from clients. The iterator encapsulates the details of working with a complex data structure, providing the client with several simple methods of accessing the collection elements.

Use Iterator when you want your code to be able to traverse different data structures, or when types of these structures are unknown beforehand. The pattern provides a couple of generic interfaces for both collections and iterators, enabling your code to work with any collection type as long as it conforms to the expected protocols.

In Swift, the Iterator pattern is deeply embedded in the language through the `Sequence` and `IteratorProtocol` protocols. Any type conforming to `Sequence` automatically gains access to `for-in` loops, `map`, `filter`, `reduce`, and dozens of other functional operations. Custom iterators are most valuable when you have tree structures, graphs, or other non-linear data structures that need multiple traversal orders (in-order, pre-order, post-order, breadth-first).

## Structure

| Participant | Role |
|-------------|------|
| Iterator (Protocol) | Declares operations required for traversing a collection: fetching the next element, retrieving the current position, restarting iteration, etc. In Swift, this is `IteratorProtocol` with its `next()` method. |
| Concrete Iterator | Implements a specific algorithm for traversing a collection. Tracks its own traversal progress independently. |
| Collection (Protocol) | Declares methods for obtaining iterators compatible with the collection. In Swift, this is `Sequence` with its `makeIterator()` method. |
| Concrete Collection | Returns new instances of a particular concrete iterator class each time the client requests one. |

## Conceptual Example

```swift
import XCTest

/// This is a collection that we're going to iterate through using an iterator
/// that conforms to IteratorProtocol.
class WordsCollection {

    fileprivate lazy var items = [String]()

    func append(_ item: String) {
        self.items.append(item)
    }
}

extension WordsCollection: Sequence {

    func makeIterator() -> WordsIterator {
        return WordsIterator(self)
    }
}

/// Concrete Iterators implement various traversal algorithms. These classes
/// store the current traversal position at all times.
class WordsIterator: IteratorProtocol {

    private let collection: WordsCollection
    private var index = 0

    init(_ collection: WordsCollection) {
        self.collection = collection
    }

    func next() -> String? {
        defer { index += 1 }
        return index < collection.items.count ? collection.items[index] : nil
    }
}


/// This is another collection that we'll provide AnyIterator for traversing its
/// items.
class NumbersCollection {

    fileprivate lazy var items = [Int]()

    func append(_ item: Int) {
        self.items.append(item)
    }
}

extension NumbersCollection: Sequence {

    func makeIterator() -> AnyIterator<Int> {
        var index = self.items.count - 1

        return AnyIterator {
            defer { index -= 1 }
            return index >= 0 ? self.items[index] : nil
        }
    }
}

/// Client does not know the internal representation of a given sequence.
class Client {

    static func clientCode<S: Sequence>(sequence: S) {
        for item in sequence {
            print(item)
        }
    }
}

/// Let's see how it all works together.
class IteratorConceptual: XCTestCase {

    func testIteratorProtocol() {

        let words = WordsCollection()
        words.append("First")
        words.append("Second")
        words.append("Third")

        print("Straight traversal using IteratorProtocol:")
        Client.clientCode(sequence: words)
    }

    func testAnyIterator() {

        let numbers = NumbersCollection()
        numbers.append(1)
        numbers.append(2)
        numbers.append(3)

        print("\nReverse traversal using AnyIterator:")
        Client.clientCode(sequence: numbers)
    }
}
```

**Output:**
```
Straight traversal using IteratorProtocol:
First
Second
Third

Reverse traversal using AnyIterator:
3
2
1
```

## Real-World Example

```swift
import XCTest

class IteratorRealWorld: XCTestCase {

    func test() {

        let tree = Tree(1)
        tree.left = Tree(2)
        tree.right = Tree(3)

        print("Tree traversal: Inorder")
        clientCode(iterator: tree.iterator(.inOrder))

        print("\nTree traversal: Preorder")
        clientCode(iterator: tree.iterator(.preOrder))

        print("\nTree traversal: Postorder")
        clientCode(iterator: tree.iterator(.postOrder))
    }

    func clientCode<T>(iterator: AnyIterator<T>) {
        while case let item? = iterator.next() {
            print(item)
        }
    }
}

class Tree<T> {

    var value: T
    var left: Tree<T>?
    var right: Tree<T>?

    init(_ value: T) {
        self.value = value
    }

    typealias Block = (T) -> ()

    enum IterationType {
        case inOrder
        case preOrder
        case postOrder
    }

    func iterator(_ type: IterationType) -> AnyIterator<T> {
        var items = [T]()
        switch type {
        case .inOrder:
            inOrder { items.append($0) }
        case .preOrder:
            preOrder { items.append($0) }
        case .postOrder:
            postOrder { items.append($0) }
        }

        /// Note:
        /// AnyIterator is used to hide the type signature of an internal
        /// iterator.
        return AnyIterator(items.makeIterator())
    }

    private func inOrder(_ body: Block) {
        left?.inOrder(body)
        body(value)
        right?.inOrder(body)
    }

    private func preOrder(_ body: Block) {
        body(value)
        left?.preOrder(body)
        right?.preOrder(body)
    }

    private func postOrder(_ body: Block) {
        left?.postOrder(body)
        right?.postOrder(body)
        body(value)
    }
}
```

**Output:**
```
Tree traversal: Inorder
2
1
3

Tree traversal: Preorder
1
2
3

Tree traversal: Postorder
2
3
1
```

## iOS Framework Usage

- **UIKit**: `UIPageViewController` iterates through view controllers using a data source protocol that provides `viewControllerBefore` and `viewControllerAfter` -- essentially a bidirectional iterator. `NSFetchedResultsController` iterates over Core Data results with section-aware traversal.
- **SwiftUI**: `ForEach` operates on any `RandomAccessCollection`, using its iterator to produce views. `List` similarly iterates through `Identifiable` elements. The `@FetchRequest` property wrapper returns an iterable `FetchedResults<T>` that conforms to `RandomAccessCollection`.
- **Foundation/Combine**: All Swift collections conform to `Sequence`. `NSEnumerator` is the Objective-C legacy iterator. Combine's `Publishers.Sequence` creates a publisher from any `Sequence`, bridging the iterator world to reactive streams. `FileManager.enumerator(at:)` provides a directory tree iterator.

## Swift-Specific Notes

- Conform to `Sequence` (requires only `makeIterator()`) to unlock the entire Swift iteration ecosystem: `for-in`, `map`, `filter`, `reduce`, `flatMap`, `compactMap`, `contains`, `first(where:)`, `prefix`, `dropFirst`, and more.
- Use `AnyIterator<T>` to create type-erased iterators from closures, which is perfect for hiding complex traversal logic (as shown in the tree example) without exposing a concrete iterator type.
- For bidirectional or random-access traversal, conform to `BidirectionalCollection` or `RandomAccessCollection` respectively, which extends `Sequence` with index-based access.
- Swift's `lazy` property on sequences (`collection.lazy.filter { ... }.map { ... }`) chains iterators without creating intermediate arrays, making it ideal for large datasets or expensive transformations.
- Use generics on both your collection and iterator types (like `Tree<T>`) to create reusable data structures that work with any element type while maintaining full type safety.

## Related Patterns

- **Composite**: Iterators are often used to traverse Composite trees. An iterator provides a flat view over a recursive tree structure.
- **Factory Method**: Polymorphic iterators rely on factory methods (`makeIterator()`) to instantiate the appropriate iterator subclass for a given collection.
- **Memento**: Can be used alongside Iterator to capture the current iteration state and roll back to it if needed, enabling restartable or checkpointed traversals.
