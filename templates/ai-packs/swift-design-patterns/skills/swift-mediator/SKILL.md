---
name: swift-mediator
description: Use Mediator in Swift to centralize interaction rules between peer components without making them reference each other directly.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Mediator

## Intent

Move coordination among peer components into one object so each component reports events without knowing every collaborator.

## When to use it

Use it for form sections, playback controls, checkout inputs, or feature modules with interaction rules that otherwise create a reference graph.

## When to avoid it

Avoid it when parent-owned bindings or one direct callback express the relationship clearly. Split a mediator once it accumulates unrelated workflows.

## Participants

- Mediator receiving component events.
- Colleagues that expose narrow state updates.
- Coordination policy that decides downstream changes.

## Example

```swift
enum CheckoutEvent {
    case countryChanged(String)
    case giftToggled(Bool)
}

final class ShippingSection {
    private(set) var availableMethods: [String] = []

    func show(methods: [String]) {
        availableMethods = methods
    }
}

final class MessageSection {
    private(set) var isVisible = false

    func setVisible(_ visible: Bool) {
        isVisible = visible
    }
}

final class CheckoutMediator {
    let shipping: ShippingSection
    let message: MessageSection

    init(shipping: ShippingSection, message: MessageSection) {
        self.shipping = shipping
        self.message = message
    }

    func receive(_ event: CheckoutEvent) {
        switch event {
        case let .countryChanged(country):
            shipping.show(methods: country == "ES" ? ["Standard", "Express"] : ["Standard"])
        case let .giftToggled(enabled):
            message.setVisible(enabled)
        }
    }
}

let shipping = ShippingSection()
let message = MessageSection()
let mediator = CheckoutMediator(shipping: shipping, message: message)
mediator.receive(.giftToggled(true))
precondition(message.isVisible)
```

## Trade-offs

Peers remain independent and interaction rules have one test surface. The mediator can become a large procedural controller if component ownership is not bounded.

## Testing strategy

Test each event, state combination, event order, and ignored transition with recording colleagues. Verify colleagues never require one another directly.

## Related patterns

Observer broadcasts without central coordination policy. Facade coordinates a client request into a subsystem. State organizes behavior around one context's lifecycle.
