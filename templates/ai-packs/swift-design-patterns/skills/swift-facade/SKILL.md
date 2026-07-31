---
name: swift-facade
description: Use Facade in Swift to expose one task-oriented boundary over a complicated app subsystem while keeping lower-level capabilities available internally.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Facade

## Intent

Offer a small task-oriented API that coordinates several subsystem components in the correct order.

## When to use it

Use it at feature boundaries such as checkout, onboarding, import, media preparation, or account deletion where callers should not orchestrate low-level services.

## When to avoid it

Avoid a facade that becomes a universal service object. Keep it aligned to one workflow and do not hide failures callers must handle distinctly.

## Participants

- Facade exposing the product operation.
- Subsystem services with narrower responsibilities.
- Client that depends on the facade rather than their coordination details.

## Example

```swift
struct InventoryService {
    func reserve(productID: String) -> String {
        "reservation:\(productID)"
    }
}

struct PaymentService {
    func charge(cents: Int) -> String {
        "payment:\(cents)"
    }
}

struct ReceiptService {
    func create(reservation: String, payment: String) -> String {
        "receipt[\(reservation)|\(payment)]"
    }
}

struct CheckoutFacade {
    let inventory: InventoryService
    let payments: PaymentService
    let receipts: ReceiptService

    func purchase(productID: String, cents: Int) -> String {
        let reservation = inventory.reserve(productID: productID)
        let payment = payments.charge(cents: cents)
        return receipts.create(reservation: reservation, payment: payment)
    }
}

let checkout = CheckoutFacade(
    inventory: InventoryService(),
    payments: PaymentService(),
    receipts: ReceiptService()
)
precondition(checkout.purchase(productID: "sensor", cents: 2500) == "receipt[reservation:sensor|payment:2500]")
```

## Trade-offs

Call sites are stable and orchestration has one owner. The facade can conceal coupling or grow into a god object if unrelated workflows accumulate.

## Testing strategy

Use recording subsystem doubles to verify order, inputs, failure propagation, compensation, and idempotency. Keep unit tests for each subsystem separate.

## Related patterns

Mediator coordinates peer components over time. Adapter translates a boundary. Application services often act as domain-specific facades.
