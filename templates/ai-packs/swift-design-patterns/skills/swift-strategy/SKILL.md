---
name: swift-strategy
description: Use Strategy in Swift to inject one interchangeable product policy while keeping the context and input model stable.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Strategy

## Intent

Encapsulate interchangeable algorithms behind one capability and let the context delegate the policy choice.

## When to use it

Use it for ranking, pricing, validation, formatting, recommendation, or retry policy selected by product configuration or experiment.

## When to avoid it

Avoid it when a pure function or enum switch at the composition root is clearer. The context should not inspect concrete strategy types.

## Participants

- Strategy protocol.
- Concrete strategies implementing alternative policies.
- Context that supplies input and consumes the result.

## Example

```swift
struct SearchItem: Equatable {
    let name: String
    let popularity: Int
    let distanceMeters: Int
}

protocol SearchRankingStrategy {
    func rank(_ items: [SearchItem]) -> [SearchItem]
}

struct PopularityRanking: SearchRankingStrategy {
    func rank(_ items: [SearchItem]) -> [SearchItem] {
        items.sorted { $0.popularity > $1.popularity }
    }
}

struct DistanceRanking: SearchRankingStrategy {
    func rank(_ items: [SearchItem]) -> [SearchItem] {
        items.sorted { $0.distanceMeters < $1.distanceMeters }
    }
}

struct SearchResults {
    let ranking: any SearchRankingStrategy

    func present(_ items: [SearchItem]) -> [String] {
        ranking.rank(items).map(\.name)
    }
}

let items = [
    SearchItem(name: "Near", popularity: 2, distanceMeters: 100),
    SearchItem(name: "Popular", popularity: 9, distanceMeters: 800)
]
precondition(SearchResults(ranking: PopularityRanking()).present(items) == ["Popular", "Near"])
```

## Trade-offs

Policies are independently testable and contexts lose conditional branches. Callers must choose correctly, and many tiny strategies can obscure simple product rules.

## Testing strategy

Use shared contract cases plus boundary cases unique to each algorithm. Verify determinism, stable tie-breaking, empty input, and composition-root selection.

## Related patterns

State changes with lifecycle and owns transitions. Template Method varies selected steps through inheritance. Bridge supports two independent dimensions, one of which may resemble strategy.
