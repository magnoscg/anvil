---
name: swift-factory-method
description: Use Factory Method in Swift to defer one product choice while keeping the consuming workflow stable and testable.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Factory Method

## Intent

Define a construction point that variants can change without duplicating the workflow that consumes the product.

## When to use it

Use it when an iOS flow is stable but export, storage, transport, or presentation implementations vary by edition, environment, or test.

## When to avoid it

Avoid it when a passed dependency or closure expresses the choice directly. Do not create a subclass hierarchy solely to rename an initializer.

## Participants

- Product protocol used by the workflow.
- Concrete products implementing the capability.
- Creator that exposes the factory method and owns the stable operation.

## Example

```swift
protocol ReceiptExporter {
    func export(orderID: String) -> String
}

struct TextReceiptExporter: ReceiptExporter {
    func export(orderID: String) -> String {
        "Receipt for \(orderID)"
    }
}

struct JSONReceiptExporter: ReceiptExporter {
    func export(orderID: String) -> String {
        "{\"orderID\":\"\(orderID)\"}"
    }
}

protocol ReceiptFlow {
    func makeExporter() -> any ReceiptExporter
}

extension ReceiptFlow {
    func finish(orderID: String) -> String {
        makeExporter().export(orderID: orderID)
    }
}

struct SupportReceiptFlow: ReceiptFlow {
    func makeExporter() -> any ReceiptExporter {
        TextReceiptExporter()
    }
}

struct AutomationReceiptFlow: ReceiptFlow {
    func makeExporter() -> any ReceiptExporter {
        JSONReceiptExporter()
    }
}

precondition(SupportReceiptFlow().finish(orderID: "A-42") == "Receipt for A-42")
```

## Trade-offs

The workflow is closed to repeated branching and products are replaceable. The cost is an additional protocol and creator type for a choice that may remain simple.

## Testing strategy

Contract-test every product and verify each creator selects the expected behavior. Test the shared workflow once with a deterministic product.

## Related patterns

Abstract Factory coordinates several product choices. Strategy injects behavior after construction. Template Method can provide the stable workflow around a factory hook.
