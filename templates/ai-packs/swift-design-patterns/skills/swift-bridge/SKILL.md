---
name: swift-bridge
description: Use Bridge in Swift when an abstraction and its implementation dimension must evolve independently without a multiplying type hierarchy.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Bridge

## Intent

Separate an abstraction from the implementation mechanism it delegates to so both dimensions can vary independently.

## When to use it

Use it when message types vary independently from delivery channels, or presentation models vary independently from rendering backends.

## When to avoid it

Avoid it when only one dimension changes or a simple injected closure is enough. Do not introduce two hierarchies in anticipation of hypothetical variants.

## Participants

- Abstraction defining product-level behavior.
- Refined abstraction representing a product variant.
- Implementor protocol for the independent mechanism.
- Concrete implementors.

## Example

```swift
protocol MessageChannel {
    func deliver(subject: String, body: String) -> String
}

struct PushChannel: MessageChannel {
    func deliver(subject: String, body: String) -> String {
        "push[\(subject)]:\(body)"
    }
}

struct EmailChannel: MessageChannel {
    func deliver(subject: String, body: String) -> String {
        "email[\(subject)]:\(body)"
    }
}

struct OrderMessage {
    let channel: any MessageChannel

    func shipped(orderID: String) -> String {
        channel.deliver(subject: "Order shipped", body: "Track \(orderID) in the app")
    }
}

struct SecurityMessage {
    let channel: any MessageChannel

    func newLogin(city: String) -> String {
        channel.deliver(subject: "New login", body: "Access detected in \(city)")
    }
}

let message = OrderMessage(channel: PushChannel()).shipped(orderID: "A-42")
precondition(message == "push[Order shipped]:Track A-42 in the app")
```

## Trade-offs

New abstractions and implementors compose without a Cartesian product of types. Clients must understand two collaborating concepts and their compatibility rules.

## Testing strategy

Contract-test every implementor, then test each abstraction with a recording implementor. Include formatting, ordering, failure, and unsupported combination cases.

## Related patterns

Abstract Factory creates fixed compatible families. Strategy swaps one behavior within an abstraction. Adapter translates an existing incompatible implementor.
