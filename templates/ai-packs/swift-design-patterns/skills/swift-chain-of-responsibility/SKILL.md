---
name: swift-chain-of-responsibility
description: Use Chain of Responsibility in Swift to pass a request through ordered handlers until one handles or rejects it.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Chain of Responsibility

## Intent

Decouple a request from the specific handler by evaluating an ordered sequence of candidate handlers.

## When to use it

Use it for validation, deep-link routing, support escalation, input handling, or middleware where order is a product rule.

## When to avoid it

Avoid it when every handler must run—that is a pipeline—or when the eventual handler must be statically obvious. Never leave an unhandled request silent.

## Participants

- Request passed through the chain.
- Handler contract returning handled or pass-through outcome.
- Concrete handlers.
- Chain that owns order and fallback.

## Example

```swift
enum RouteResult: Equatable {
    case handled(screen: String)
    case pass
}

protocol DeepLinkHandler {
    func handle(_ path: String) -> RouteResult
}

struct OrderLinkHandler: DeepLinkHandler {
    func handle(_ path: String) -> RouteResult {
        guard path.hasPrefix("/orders/") else { return .pass }
        return .handled(screen: "order-detail")
    }
}

struct ProfileLinkHandler: DeepLinkHandler {
    func handle(_ path: String) -> RouteResult {
        path == "/profile" ? .handled(screen: "profile") : .pass
    }
}

struct DeepLinkChain {
    let handlers: [any DeepLinkHandler]

    func route(_ path: String) -> RouteResult {
        for handler in handlers {
            let result = handler.handle(path)
            if result != .pass { return result }
        }
        return .handled(screen: "not-found")
    }
}

let chain = DeepLinkChain(handlers: [OrderLinkHandler(), ProfileLinkHandler()])
precondition(chain.route("/profile") == .handled(screen: "profile"))
```

## Trade-offs

Handlers remain small and order is configurable. Behavior can become order-dependent, and tracing why a request passed through several handlers needs explicit diagnostics.

## Testing strategy

Test each handler's handle/pass boundary, full ordering, fallback, duplicate matches, and short-circuit behavior. Keep a table of product routes as an acceptance test.

## Related patterns

Decorator has every wrapper participate. Strategy selects one policy directly. Command represents the request as an object before routing or queuing it.
