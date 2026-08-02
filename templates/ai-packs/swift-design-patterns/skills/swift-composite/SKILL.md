---
name: swift-composite
description: Use Composite in Swift to treat individual and grouped product nodes uniformly while preserving tree-specific invariants.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Composite

## Intent

Represent part-whole hierarchies through one interface so clients can operate on leaves and groups uniformly.

## When to use it

Use it for folders, nested filters, product bundles, form sections, or accessibility trees with recursive aggregate behavior.

## When to avoid it

Avoid it when the structure is flat or when leaves and groups have fundamentally different operations. Uniformity should not permit invalid child mutations.

## Participants

- Component interface shared by all nodes.
- Leaf containing terminal behavior.
- Composite containing child components and aggregate behavior.
- Client operating on the component boundary.

## Example

```swift
indirect enum CartNode: Equatable {
    case item(name: String, cents: Int)
    case bundle(name: String, children: [CartNode])

    var totalCents: Int {
        switch self {
        case let .item(_, cents):
            cents
        case let .bundle(_, children):
            children.reduce(0) { $0 + $1.totalCents }
        }
    }

    var lineCount: Int {
        switch self {
        case .item:
            1
        case let .bundle(_, children):
            children.reduce(0) { $0 + $1.lineCount }
        }
    }
}

let starterKit = CartNode.bundle(name: "Starter kit", children: [
    .item(name: "Sensor", cents: 2500),
    .bundle(name: "Cables", children: [
        .item(name: "USB-C", cents: 900),
        .item(name: "Lightning", cents: 1100)
    ])
])

precondition(starterKit.totalCents == 4500)
precondition(starterKit.lineCount == 3)
```

## Trade-offs

Recursive operations become concise and new clients ignore node shape. A too-general component interface can hide operations that only make sense for composites.

## Testing strategy

Test one leaf, an empty composite, one nesting level, deep nesting, ordering, and aggregate invariants. Generate random trees when totals or traversal are critical.

## Related patterns

Iterator traverses a composite. Visitor adds operations across node variants. Decorator wraps one component rather than owning a collection of peers.
