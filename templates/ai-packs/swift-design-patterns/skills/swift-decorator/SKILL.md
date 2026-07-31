---
name: swift-decorator
description: Use Decorator in Swift to add composable behavior around a capability without expanding subclasses or changing the wrapped implementation.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Decorator

## Intent

Wrap an object with the same capability and add behavior before or after forwarding the call.

## When to use it

Use it for caching, metrics, retry policy, redaction, filtering, or logging that should compose around several implementations.

## When to avoid it

Avoid it when order is unclear, wrappers need hidden knowledge of each other, or one explicit coordinator would explain the flow better.

## Participants

- Component protocol.
- Concrete component providing core behavior.
- Decorators retaining another component and preserving the interface.

## Example

```swift
protocol SearchProviding {
    func results(for query: String) -> [String]
}

struct CatalogSearch: SearchProviding {
    let products: [String]

    func results(for query: String) -> [String] {
        products.filter { $0.lowercased().contains(query.lowercased()) }
    }
}

struct DeduplicatingSearch: SearchProviding {
    let wrapped: any SearchProviding

    func results(for query: String) -> [String] {
        var seen = Set<String>()
        return wrapped.results(for: query).filter { seen.insert($0).inserted }
    }
}

struct LimitingSearch: SearchProviding {
    let wrapped: any SearchProviding
    let limit: Int

    func results(for query: String) -> [String] {
        Array(wrapped.results(for: query).prefix(limit))
    }
}

let search = LimitingSearch(
    wrapped: DeduplicatingSearch(
        wrapped: CatalogSearch(products: ["Lamp", "Lamp", "Laptop"])
    ),
    limit: 1
)
precondition(search.results(for: "la") == ["Lamp"])
```

## Trade-offs

Behavior composes without subclass multiplication and wrappers are testable in isolation. Runtime stacks can be hard to inspect and order changes semantics.

## Testing strategy

Contract-test forwarding, then verify each decorator's added behavior and combinations in both meaningful orders. Include failure and cancellation when wrapping asynchronous work.

## Related patterns

Proxy controls access and may manage identity. Adapter changes the interface. Chain of Responsibility chooses which handler acts instead of every wrapper participating.
