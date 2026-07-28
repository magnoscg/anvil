---
name: swift-composite
description: >
  Swift Composite design pattern — Structural. Use when working with tree structures, treating
  individual objects and compositions uniformly, building view hierarchies, or implementing
  recursive part-whole structures. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Composite — Swift

> **Category**: Structural
> **Intent**: Composite is a structural design pattern that lets you compose objects into tree structures and then work with these structures as if they were individual objects.

## When to Use

Use the Composite pattern when you have to implement a tree-like object structure. The pattern provides two basic element types that share a common interface: simple leaves and complex containers. A container can hold both leaves and other containers, letting you construct complex nested recursive tree structures.

This pattern is ideal when you want client code to treat both simple and complex elements uniformly. All elements share a common interface, so the client doesn't need to know whether it's working with a simple object or a complex tree. This is especially useful when building UI hierarchies, file systems, organization charts, or any recursive data structure.

In iOS, the Composite pattern is fundamental — UIKit's entire view hierarchy (`UIView` containing subviews) is a Composite. SwiftUI's `Group`, `VStack`, and `@ViewBuilder` also leverage this concept.

## Structure

| Participant | Role |
|-------------|------|
| Component (Protocol) | Declares the interface common to both simple and complex objects. May include default implementations for child management. |
| Leaf | Represents end objects with no children. Does the actual work. |
| Composite | Stores child components and delegates work to them. Collects results from children. |

## Conceptual Example

```swift
import XCTest

protocol Component {
    var parent: Component? { get set }
    func add(component: Component)
    func remove(component: Component)
    func isComposite() -> Bool
    func operation() -> String
}

extension Component {
    func add(component: Component) {}
    func remove(component: Component) {}
    func isComposite() -> Bool { return false }
}

class Leaf: Component {
    var parent: Component?
    func operation() -> String { return "Leaf" }
}

class Composite: Component {
    var parent: Component?
    private var children = [Component]()

    func add(component: Component) {
        var item = component
        item.parent = self
        children.append(item)
    }

    func remove(component: Component) {}

    func isComposite() -> Bool { return true }

    func operation() -> String {
        let result = children.map({ $0.operation() })
        return "Branch(" + result.joined(separator: " ") + ")"
    }
}

class Client {
    static func someClientCode(component: Component) {
        print("Result: " + component.operation())
    }

    static func moreComplexClientCode(leftComponent: Component, rightComponent: Component) {
        if leftComponent.isComposite() {
            leftComponent.add(component: rightComponent)
        }
        print("Result: " + leftComponent.operation())
    }
}

class CompositeConceptual: XCTestCase {
    func testCompositeConceptual() {
        print("Client: I've got a simple component:")
        Client.someClientCode(component: Leaf())

        let tree = Composite()
        let branch1 = Composite()
        branch1.add(component: Leaf())
        branch1.add(component: Leaf())

        let branch2 = Composite()
        branch2.add(component: Leaf())
        branch2.add(component: Leaf())

        tree.add(component: branch1)
        tree.add(component: branch2)

        print("\nClient: Now I've got a composite tree:")
        Client.someClientCode(component: tree)

        print("\nClient: I don't need to check the components classes even when managing the tree:")
        Client.moreComplexClientCode(leftComponent: tree, rightComponent: Leaf())
    }
}
```

**Output:**
```
Client: I've got a simple component:
Result: Leaf

Client: Now I've got a composite tree:
Result: Branch(Branch(Leaf Leaf) Branch(Leaf Leaf))

Client: I don't need to check the components classes even when managing the tree:
Result: Branch(Branch(Leaf Leaf) Branch(Leaf Leaf) Leaf)
```

## Real-World Example

```swift
import UIKit
import XCTest

protocol Component {
    func accept<T: Theme>(theme: T)
}

extension Component where Self: UIViewController {
    func accept<T: Theme>(theme: T) {
        view.accept(theme: theme)
        view.subviews.forEach({ $0.accept(theme: theme) })
    }
}

extension UIView: Component {}
extension UIViewController: Component {}

extension Component where Self: UIView {
    func accept<T: Theme>(theme: T) {
        print("\t\(description): has applied \(theme.description)")
        backgroundColor = theme.backgroundColor
    }
}

extension Component where Self: UILabel {
    func accept<T: LabelTheme>(theme: T) {
        print("\t\(description): has applied \(theme.description)")
        backgroundColor = theme.backgroundColor
        textColor = theme.textColor
    }
}

extension Component where Self: UIButton {
    func accept<T: ButtonTheme>(theme: T) {
        print("\t\(description): has applied \(theme.description)")
        backgroundColor = theme.backgroundColor
        setTitleColor(theme.textColor, for: .normal)
        setTitleColor(theme.highlightedColor, for: .highlighted)
    }
}

protocol Theme: CustomStringConvertible {
    var backgroundColor: UIColor { get }
}

protocol ButtonTheme: Theme {
    var textColor: UIColor { get }
    var highlightedColor: UIColor { get }
}

protocol LabelTheme: Theme {
    var textColor: UIColor { get }
}

struct DefaultButtonTheme: ButtonTheme {
    var textColor = UIColor.red
    var highlightedColor = UIColor.white
    var backgroundColor = UIColor.orange
    var description: String { return "Default Button Theme" }
}

struct NightButtonTheme: ButtonTheme {
    var textColor = UIColor.white
    var highlightedColor = UIColor.red
    var backgroundColor = UIColor.black
    var description: String { return "Night Button Theme" }
}

class CompositeRealWorld: XCTestCase {
    func testCompositeRealWorld() {
        print("Client: Applying 'default' theme for 'UIButton'")
        apply(theme: DefaultButtonTheme(), for: UIButton())

        print("\nClient: Applying 'night' theme for 'UIButton'")
        apply(theme: NightButtonTheme(), for: UIButton())
    }

    func apply<T: Theme>(theme: T, for component: Component) {
        component.accept(theme: theme)
    }
}
```

**Output:**
```
Client: Applying 'default' theme for 'UIButton'
UIButton: has applied Default Button Theme

Client: Applying 'night' theme for 'UIButton'
UIButton: has applied Night Button Theme
```

## iOS Framework Usage

- **UIKit**: `UIView` is the canonical Composite — every view contains subviews, forming a tree. `addSubview()`, `removeFromSuperview()`, `subviews` property. `UIStackView` is a specialized composite.
- **SwiftUI**: `Group`, `VStack`, `HStack`, `ZStack` are composites. `@ViewBuilder` enables tree construction via result builders. `ForEach` generates leaf/composite combinations.
- **Foundation**: `FileManager` works with directory trees (directories as composites, files as leaves). `NSCompoundPredicate` composes predicates into trees.

## Swift-Specific Notes

- **Protocol with default implementations**: Use protocol extensions to provide default no-op implementations for child management methods, so leaves don't need to implement them.
- **Recursive enums**: Swift's `indirect enum` provides a lightweight alternative for simple composites: `indirect enum Expression { case value(Int); case add(Expression, Expression) }`.
- **Value types**: For immutable trees, use struct-based composites. For mutable trees with parent references, use classes to avoid copy-on-write overhead.
- **Result builders**: SwiftUI's `@ViewBuilder` is essentially a compile-time Composite builder — it collects heterogeneous views into a tree structure.
- **Generics**: Use generics to create type-safe composites: `class TreeNode<T> { var value: T; var children: [TreeNode<T>] }`.

## Related Patterns

- **Decorator**: Both have similar structure diagrams (recursive composition), but Decorator adds responsibilities to objects while Composite just "sums up" children's results.
- **Iterator**: You can use Iterator to traverse Composite trees.
- **Visitor**: You can use Visitor to execute an operation over an entire Composite tree.
- **Chain of Responsibility**: Often used with Composite — leaf components pass requests up through the parent chain.
