---
name: swift-creational-patterns
description: Choose a Swift creational pattern by locating construction variability, ownership, and lifecycle before adding abstraction.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Creational Patterns in Swift

## Intent

Move construction decisions out of product flows when object shape, family, configuration, or lifecycle varies independently from use.

## When to use it

Use a creational pattern when tests need controlled collaborators, several product variants share a flow, construction requires validated steps, or one lifecycle owner must be explicit.

## When to avoid it

Avoid an abstraction when a direct initializer is stable and readable. Swift value types, default arguments, and dependency injection often solve the problem with less machinery.

## Participants

- The product consumed by the feature.
- Construction policy that decides which product or configuration to create.
- Client code that depends on the resulting capability, not its assembly details.

## Example

```swift
enum AppEnvironment {
    case preview
    case production
}

struct FeedConfiguration: Equatable {
    let baseURL: String
    let pageSize: Int
    let usesFixtures: Bool
}

struct FeedConfigurationFactory {
    func make(for environment: AppEnvironment) -> FeedConfiguration {
        switch environment {
        case .preview:
            FeedConfiguration(
                baseURL: "fixture://feed",
                pageSize: 6,
                usesFixtures: true
            )
        case .production:
            FeedConfiguration(
                baseURL: "https://api.example.com/feed",
                pageSize: 30,
                usesFixtures: false
            )
        }
    }
}

let preview = FeedConfigurationFactory().make(for: .preview)
precondition(preview.usesFixtures)
```

## Trade-offs

Construction becomes testable and consistent, but each extra layer creates naming and navigation cost. Keep policy close to the variation it owns.

## Testing strategy

Test every supported variant, invalid configuration, deterministic defaults, and ownership boundary. Assert observable products rather than private factory steps.

## Related patterns

Factory Method selects one product. Abstract Factory creates a coherent family. Builder validates staged assembly. Prototype derives a new value from an existing one. Singleton constrains lifecycle and should be rare.
