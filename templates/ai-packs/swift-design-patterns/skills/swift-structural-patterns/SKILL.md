---
name: swift-structural-patterns
description: Choose a Swift structural pattern by identifying incompatible boundaries, independent dimensions, tree composition, wrapping, or controlled access.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Structural Patterns in Swift

## Intent

Arrange existing types into a clearer boundary without changing the product behavior they ultimately provide.

## When to use it

Use a structural pattern when integrating a legacy API, separating two variation axes, representing a tree, layering behavior, simplifying a subsystem, sharing immutable state, or controlling access.

## When to avoid it

Avoid wrappers that only forward every member. Prefer a small protocol, extension, or direct composition when no structural pressure exists.

## Participants

- Client-facing capability.
- Existing component or subsystem that performs the work.
- Structural type that adapts, composes, decorates, coordinates, shares, or guards access.

## Example

```swift
protocol OfferSource {
    func offers() -> [String]
}

struct NetworkOfferSource: OfferSource {
    func offers() -> [String] {
        ["Weekend", "Members"]
    }
}

struct FilteringOfferSource: OfferSource {
    let wrapped: any OfferSource
    let blocked: Set<String>

    func offers() -> [String] {
        wrapped.offers().filter { !blocked.contains($0) }
    }
}

struct OffersScreenModel {
    private let source: any OfferSource

    init(source: any OfferSource) {
        self.source = source
    }

    var rows: [String] {
        source.offers().map { "Offer: \($0)" }
    }
}

let source = FilteringOfferSource(wrapped: NetworkOfferSource(), blocked: ["Members"])
precondition(OffersScreenModel(source: source).rows == ["Offer: Weekend"])
```

## Trade-offs

Composition isolates change and makes boundaries testable. Too many near-empty layers obscure control flow and ownership.

## Testing strategy

Contract-test the client-facing capability, verify forwarding and transformations, and include identity, ordering, error, and lifecycle cases at the boundary.

## Related patterns

Adapter changes an interface. Bridge separates dimensions. Composite models trees. Decorator layers behavior. Facade simplifies a subsystem. Flyweight shares intrinsic state. Proxy controls access.
