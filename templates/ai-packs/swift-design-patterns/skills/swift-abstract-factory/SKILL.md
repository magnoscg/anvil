---
name: swift-abstract-factory
description: Use Abstract Factory in Swift to construct compatible families of product collaborators without branching throughout the feature.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Abstract Factory

## Intent

Create a family of related products through one boundary so incompatible variants cannot be mixed accidentally.

## When to use it

Use it when white-label apps, experiments, platforms, or environments require several coordinated implementations that must change together.

## When to avoid it

Avoid it for one independent dependency or when variants are data that fit a configuration value. Adding a new product to every family is deliberately expensive.

## Participants

- Abstract factory declaring the family.
- Product protocols representing each role.
- Concrete factories that return a coherent variant.
- Client that consumes only the abstract family.

## Example

```swift
protocol PricePresenter {
    func text(for cents: Int) -> String
}

protocol CheckoutCopy {
    var primaryAction: String { get }
}

protocol CheckoutExperienceFactory {
    func makePricePresenter() -> any PricePresenter
    func makeCopy() -> any CheckoutCopy
}

struct ConsumerPricePresenter: PricePresenter {
    func text(for cents: Int) -> String {
        "Total: \(cents) cents"
    }
}

struct ConsumerCopy: CheckoutCopy {
    let primaryAction = "Buy now"
}

struct BusinessPricePresenter: PricePresenter {
    func text(for cents: Int) -> String {
        "Net: \(cents) cents"
    }
}

struct BusinessCopy: CheckoutCopy {
    let primaryAction = "Create order"
}

struct ConsumerCheckoutFactory: CheckoutExperienceFactory {
    func makePricePresenter() -> any PricePresenter { ConsumerPricePresenter() }
    func makeCopy() -> any CheckoutCopy { ConsumerCopy() }
}

struct BusinessCheckoutFactory: CheckoutExperienceFactory {
    func makePricePresenter() -> any PricePresenter { BusinessPricePresenter() }
    func makeCopy() -> any CheckoutCopy { BusinessCopy() }
}

struct CheckoutSummary {
    let price: String
    let action: String

    init(cents: Int, factory: any CheckoutExperienceFactory) {
        price = factory.makePricePresenter().text(for: cents)
        action = factory.makeCopy().primaryAction
    }
}

let summary = CheckoutSummary(cents: 1299, factory: BusinessCheckoutFactory())
precondition(summary.action == "Create order")
```

## Trade-offs

Families remain consistent and clients lose variant branches. Introducing a new family is easy; adding a new product role requires every factory to change.

## Testing strategy

Create a contract test for each family, assert product compatibility, and test the client against a small fake factory that makes mismatches visible.

## Related patterns

Factory Method creates one role. Builder assembles one complex product. Bridge separates two dimensions that should vary independently rather than as fixed families.
