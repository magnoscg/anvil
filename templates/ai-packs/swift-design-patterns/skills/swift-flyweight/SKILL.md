---
name: swift-flyweight
description: Use Flyweight in Swift to share immutable intrinsic state across many lightweight product instances while keeping contextual state external.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Flyweight

## Intent

Share reusable intrinsic state by key instead of duplicating it in every high-volume object.

## When to use it

Use it only after measurement shows meaningful duplication in map annotations, rich-text attributes, icon metadata, game entities, or design tokens.

## When to avoid it

Avoid it for small collections, mutable shared state, or when lookup and cache invalidation cost more than the saved memory.

## Participants

- Flyweight containing immutable intrinsic state.
- Factory or pool returning shared values by stable key.
- Context retaining per-instance extrinsic state.

## Example

```swift
struct BadgeStyle: Equatable {
    let symbol: String
    let foreground: String
    let background: String
}

final class BadgeStylePool {
    private var styles: [String: BadgeStyle] = [:]

    func style(for tier: String) -> BadgeStyle {
        if let cached = styles[tier] {
            return cached
        }
        let created = switch tier {
        case "pro": BadgeStyle(symbol: "star", foreground: "white", background: "blue")
        default: BadgeStyle(symbol: "person", foreground: "black", background: "gray")
        }
        styles[tier] = created
        return created
    }

    var count: Int { styles.count }
}

struct MemberBadge {
    let memberName: String
    let style: BadgeStyle
}

let pool = BadgeStylePool()
let first = MemberBadge(memberName: "Ana", style: pool.style(for: "pro"))
let second = MemberBadge(memberName: "Luis", style: pool.style(for: "pro"))
precondition(first.style == second.style)
precondition(pool.count == 1)
```

## Trade-offs

Repeated state and construction cost shrink. Context is split across objects, lookup becomes part of the hot path, and shared values must remain immutable.

## Testing strategy

Test key stability, reuse, distinct keys, memory-sensitive scale, and behavior under cache reset. If used concurrently, test synchronization and value safety.

## Related patterns

Singleton enforces one instance, while Flyweight manages many shared values. Prototype copies configured state. Object pools reuse mutable resources and require different lifecycle rules.
