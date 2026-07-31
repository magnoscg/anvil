---
name: swift-builder
description: Use Builder in Swift to assemble validated product configuration across readable steps without exposing invalid partial state.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Builder

## Intent

Separate staged assembly from the finished value and validate required choices at one construction boundary.

## When to use it

Use it for test fixtures, request payloads, campaigns, or screens with many optional values and a few required invariants.

## When to avoid it

Avoid it when a memberwise initializer with defaults is already clear. Do not let a builder create values the final type would reject.

## Participants

- Product containing valid final state.
- Builder accumulating choices.
- Build operation enforcing invariants.
- Optional director that applies a reusable recipe.

## Example

```swift
enum CampaignBuildError: Error {
    case missingTitle
    case emptyAudience
}

struct PushCampaign: Equatable {
    let title: String
    let audienceIDs: [String]
    let deepLink: String?
}

struct PushCampaignBuilder {
    private var title: String?
    private var audienceIDs: [String] = []
    private var deepLink: String?

    func titled(_ value: String) -> Self {
        var copy = self
        copy.title = value
        return copy
    }

    func sent(to IDs: [String]) -> Self {
        var copy = self
        copy.audienceIDs = IDs
        return copy
    }

    func opening(_ link: String) -> Self {
        var copy = self
        copy.deepLink = link
        return copy
    }

    func build() throws -> PushCampaign {
        guard let title, !title.isEmpty else { throw CampaignBuildError.missingTitle }
        guard !audienceIDs.isEmpty else { throw CampaignBuildError.emptyAudience }
        return PushCampaign(title: title, audienceIDs: audienceIDs, deepLink: deepLink)
    }
}

let campaign = try PushCampaignBuilder()
    .titled("Order shipped")
    .sent(to: ["user-7"])
    .opening("myapp://orders/7")
    .build()
precondition(campaign.audienceIDs == ["user-7"])
```

## Trade-offs

Call sites become readable and invalid construction is centralized. The builder duplicates product fields and can drift unless the final initializer stays authoritative.

## Testing strategy

Test each required-field failure, default, override, repeated step, and successful recipe. Compare final values, not the builder's internal state.

## Related patterns

Abstract Factory selects a family. Factory Method selects one implementation. Prototype starts from a valid existing value and changes a small part.
