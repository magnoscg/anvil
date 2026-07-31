---
name: swift-behavioral-patterns
description: Choose a Swift behavioral pattern by identifying responsibility flow, state change, interchangeable policy, history, notifications, or operations over stable models.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Behavioral Patterns in Swift

## Intent

Make collaboration and changing behavior explicit without concentrating every branch in one feature object.

## When to use it

Use a behavioral pattern when requests move through handlers, actions need identity, traversal must be encapsulated, peers need coordination, state requires history, events have observers, behavior changes by state or policy, a workflow has stable steps, or operations vary over stable element types.

## When to avoid it

Avoid protocol networks around a small switch. Start from the responsibility that changes and add one boundary, not a catalogue of patterns.

## Participants

- Context or client initiating behavior.
- Collaborators that own distinct decisions.
- Message, state, command, strategy, or visitor that makes collaboration explicit.

## Example

```swift
struct Purchase: Equatable {
    let cents: Int
    let country: String
}

protocol PurchasePolicy {
    func rejection(for purchase: Purchase) -> String?
}

struct MaximumAmountPolicy: PurchasePolicy {
    let limit: Int

    func rejection(for purchase: Purchase) -> String? {
        purchase.cents > limit ? "Amount exceeds limit" : nil
    }
}

struct CountryPolicy: PurchasePolicy {
    let supported: Set<String>

    func rejection(for purchase: Purchase) -> String? {
        supported.contains(purchase.country) ? nil : "Country is unsupported"
    }
}

struct PurchaseEvaluator {
    let policies: [any PurchasePolicy]

    func evaluate(_ purchase: Purchase) -> [String] {
        policies.compactMap { $0.rejection(for: purchase) }
    }
}

let evaluator = PurchaseEvaluator(policies: [
    MaximumAmountPolicy(limit: 10_000),
    CountryPolicy(supported: ["ES", "PT"])
])
precondition(evaluator.evaluate(Purchase(cents: 12_000, country: "ES")) == ["Amount exceeds limit"])
```

## Trade-offs

Responsibilities become replaceable and testable. Indirection makes sequence and ownership harder to see unless names and composition stay close to the product flow.

## Testing strategy

Test collaborators through their contracts, then add focused integration tests for ordering, cancellation, state transitions, duplicate events, and failure propagation.

## Related patterns

Chain routes requests. Command gives actions identity. Iterator encapsulates traversal. Mediator coordinates peers. Memento stores history. Observer broadcasts events. State and Strategy vary behavior. Template Method fixes sequence. Visitor varies operations.
