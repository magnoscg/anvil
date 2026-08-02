---
name: swift-iterator
description: Use Iterator in Swift to expose ordered traversal without revealing collection storage or cursor rules.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Iterator

## Intent

Encapsulate traversal state and order behind Swift's `Sequence` and `IteratorProtocol` contracts.

## When to use it

Use it for pagination windows, filtered domain traversal, tree walks, or generated values where exposing storage would couple callers.

## When to avoid it

Avoid a custom iterator when an array and standard lazy operations are sufficient. Iterators are single-pass unless the sequence creates a fresh iterator.

## Participants

- Sequence that creates traversal state.
- Iterator holding the cursor.
- Elements returned in a documented order.
- Client using `for-in` or iterator operations.

## Example

```swift
struct PageWindow: Sequence {
    let totalItems: Int
    let pageSize: Int

    func makeIterator() -> PageWindowIterator {
        PageWindowIterator(totalItems: totalItems, pageSize: pageSize)
    }
}

struct PageWindowIterator: IteratorProtocol {
    let totalItems: Int
    let pageSize: Int
    private var offset = 0

    init(totalItems: Int, pageSize: Int) {
        self.totalItems = totalItems
        self.pageSize = max(pageSize, 1)
    }

    mutating func next() -> Range<Int>? {
        guard offset < totalItems else { return nil }
        let end = min(offset + pageSize, totalItems)
        defer { offset = end }
        return offset..<end
    }
}

let pages = Array(PageWindow(totalItems: 7, pageSize: 3))
precondition(pages == [0..<3, 3..<6, 6..<7])
```

## Trade-offs

Storage and traversal evolve independently, and clients gain standard sequence operations. Cursor invalidation, mutation during traversal, and single-pass behavior need explicit contracts.

## Testing strategy

Test empty, one-element, exact-boundary, partial-final, repeated iteration, and invalid input cases. For trees, verify order and cycle policy.

## Related patterns

Composite supplies recursive structures to traverse. Visitor performs operations during traversal. Memento can capture a cursor when resumable traversal is required.
