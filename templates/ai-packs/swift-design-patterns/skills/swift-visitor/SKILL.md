---
name: swift-visitor
description: Use Visitor in Swift when operations change frequently across a stable closed family of product element types.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Visitor

## Intent

Add operations across a stable set of heterogeneous elements without placing every operation inside those element types.

## When to use it

Use it for analytics export, validation, rendering, or diagnostics over a stable syntax tree or closed product-event model.

## When to avoid it

Avoid it when element types change often; each new element forces every visitor to change. Swift enum pattern matching is usually clearer for a small closed model.

## Participants

- Element protocol exposing `accept`.
- Concrete elements dispatching to their matching visit method.
- Visitor protocol declaring one operation per element type.
- Concrete visitors implementing an operation.

## Example

```swift
protocol AnalyticsElement {
    func accept(_ visitor: any AnalyticsVisitor) -> String
}

struct PurchaseEvent: AnalyticsElement {
    let cents: Int

    func accept(_ visitor: any AnalyticsVisitor) -> String {
        visitor.visit(self)
    }
}

struct ScreenEvent: AnalyticsElement {
    let name: String

    func accept(_ visitor: any AnalyticsVisitor) -> String {
        visitor.visit(self)
    }
}

protocol AnalyticsVisitor {
    func visit(_ event: PurchaseEvent) -> String
    func visit(_ event: ScreenEvent) -> String
}

struct DebugAnalyticsVisitor: AnalyticsVisitor {
    func visit(_ event: PurchaseEvent) -> String {
        "purchase cents=\(event.cents)"
    }

    func visit(_ event: ScreenEvent) -> String {
        "screen name=\(event.name)"
    }
}

let events: [any AnalyticsElement] = [
    ScreenEvent(name: "checkout"),
    PurchaseEvent(cents: 1299)
]
let output = events.map { $0.accept(DebugAnalyticsVisitor()) }
precondition(output == ["screen name=checkout", "purchase cents=1299"])
```

## Trade-offs

New operations are localized and double dispatch selects element-specific behavior. Adding an element has high fan-out, and visitors may need more element data than the model should expose.

## Testing strategy

Test every visitor-element pair, traversal order, aggregation, and unknown-version behavior for persisted models. A compile-time exhaustive test matrix helps reveal missing cases.

## Related patterns

Composite provides trees commonly visited. Iterator controls traversal. Strategy varies one algorithm without double dispatch. Enum switches are the simpler closed-world alternative.
