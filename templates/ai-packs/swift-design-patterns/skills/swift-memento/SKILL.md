---
name: swift-memento
description: Use Memento in Swift to capture and restore product state without exposing the originator's internal representation to history management.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Memento

## Intent

Capture a restorable snapshot while keeping validation and internal state ownership inside the originator.

## When to use it

Use it for draft restoration, editor undo checkpoints, multi-step form recovery, or resumable product configuration.

## When to avoid it

Avoid it for irreversible external side effects or very large state copied on every keystroke. Commands or persisted events may model those cases better.

## Participants

- Originator that creates and restores snapshots.
- Memento containing the approved state representation.
- Caretaker storing history without interpreting it.

## Example

```swift
struct DraftSnapshot: Equatable {
    fileprivate let title: String
    fileprivate let body: String
}

final class ArticleDraft {
    private(set) var title: String
    private(set) var body: String

    init(title: String, body: String) {
        self.title = title
        self.body = body
    }

    func edit(title: String, body: String) {
        self.title = title
        self.body = body
    }

    func snapshot() -> DraftSnapshot {
        DraftSnapshot(title: title, body: body)
    }

    func restore(_ snapshot: DraftSnapshot) {
        title = snapshot.title
        body = snapshot.body
    }
}

var history: [DraftSnapshot] = []
let draft = ArticleDraft(title: "First", body: "Text")
history.append(draft.snapshot())
draft.edit(title: "Second", body: "Changed")
draft.restore(history.removeLast())
precondition(draft.title == "First")
```

## Trade-offs

History does not reach into private mutation rules and restoration is deterministic. Snapshots consume storage, versioning persisted mementos is hard, and external effects remain outside the snapshot.

## Testing strategy

Round-trip every state, restore multiple checkpoints, test schema evolution for persisted snapshots, and verify excluded transient state is rebuilt safely.

## Related patterns

Command records operations and can implement inverse actions. Prototype creates a new identity from existing state. Event sourcing retains domain events rather than opaque snapshots.
