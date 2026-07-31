---
name: swift-singleton
description: Evaluate and contain Singleton-style lifecycle in Swift, preferring explicit ownership while protecting the rare process-wide service.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Singleton

## Intent

Provide one well-defined process-wide instance when the resource itself has one lifecycle, while keeping feature code dependent on an interface.

## When to use it

Use it sparingly for a true process resource such as a low-level registry or system coordinator whose duplicate instances would be incorrect.

## When to avoid it

Avoid it for ordinary repositories, API clients, session state, analytics, or convenience access. Global mutable state hides dependencies and couples tests.

## Participants

- Single process-owned instance.
- Capability protocol consumed by features.
- Composition root that injects the shared instance.

## Example

```swift
protocol AppMetadataProviding {
    func value(for key: String) -> String?
}

struct AppMetadata: AppMetadataProviding, Sendable {
    static let shared = AppMetadata(values: [
        "supportEmail": "help@example.com"
    ])

    private let values: [String: String]

    init(values: [String: String]) {
        self.values = values
    }

    func value(for key: String) -> String? {
        values[key]
    }
}

struct HelpViewModel {
    private let metadata: any AppMetadataProviding

    init(metadata: any AppMetadataProviding = AppMetadata.shared) {
        self.metadata = metadata
    }

    var contactText: String {
        metadata.value(for: "supportEmail") ?? "Unavailable"
    }
}

let model = HelpViewModel(metadata: AppMetadata(values: ["supportEmail": "test@example.com"]))
precondition(model.contactText == "test@example.com")
```

## Trade-offs

One lifecycle is easy to locate and default injection stays convenient. The instance can still become an implicit service locator; immutable state and explicit injection limit the damage.

## Testing strategy

Test features with injected fakes, not by mutating the shared instance. Verify initialization is deterministic and add concurrency tests if the singleton owns mutable state.

## Related patterns

Dependency Injection exposes ownership. Facade simplifies access but does not require one instance. Flyweight shares many immutable values by key rather than enforcing one global object.
