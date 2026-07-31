---
name: swift-prototype
description: Use Prototype in Swift to derive a new configured value from a valid existing instance while making identity and copy depth explicit.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Prototype

## Intent

Create a new product by copying a known-valid instance and applying controlled differences.

## When to use it

Use it for duplicating user presets, dashboard layouts, editing drafts, or expensive configurations whose valid baseline already exists.

## When to avoid it

Avoid it when construction is simple or copied reference state would make ownership ambiguous. Swift structs already copy values; add a prototype API only when it expresses product intent.

## Participants

- Prototype that knows how to derive a copy.
- Concrete value containing the copied configuration.
- Client that supplies the deliberate differences.

## Example

```swift
struct DashboardCard: Equatable {
    let id: String
    var title: String
    var metricKey: String
    var accent: String

    func duplicated(newID: String, title newTitle: String? = nil) -> DashboardCard {
        DashboardCard(
            id: newID,
            title: newTitle ?? title,
            metricKey: metricKey,
            accent: accent
        )
    }
}

let revenue = DashboardCard(
    id: "revenue",
    title: "Revenue",
    metricKey: "revenue.month",
    accent: "green"
)

let forecast = revenue.duplicated(newID: "forecast", title: "Forecast")
precondition(forecast.id != revenue.id)
precondition(forecast.metricKey == revenue.metricKey)
```

## Trade-offs

Duplication preserves complex defaults and gives cloning a domain name. It can also hide stale fields or accidentally retain identity, delegates, caches, and other reference state.

## Testing strategy

Assert which fields are copied, regenerated, or reset. For reference members, prove whether the copy is intentionally shallow or deep and test later mutation.

## Related patterns

Builder constructs through steps. Memento captures state for restoration without creating a new domain identity. Copy-on-write is a storage technique, not a construction policy.
