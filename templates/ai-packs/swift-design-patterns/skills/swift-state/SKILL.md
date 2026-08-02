---
name: swift-state
description: Use State in Swift when an object's valid behavior and transitions change with its lifecycle and branches are spreading across methods.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# State

## Intent

Represent lifecycle-specific behavior in state objects and make transitions explicit on one context.

## When to use it

Use it for media playback, downloads, onboarding, sessions, or workflows where several operations depend on the same evolving state.

## When to avoid it

Avoid it when an enum and one exhaustive switch remain clearer. State objects should not permit transitions the domain forbids.

## Participants

- Context storing the current state.
- State protocol defining lifecycle-dependent operations.
- Concrete states implementing behavior and initiating valid transitions.

## Example

```swift
protocol DownloadState {
    var name: String { get }
    func start(on download: Download)
    func cancel(on download: Download)
}

final class Download {
    private var state: any DownloadState = PendingDownloadState()

    var stateName: String { state.name }

    func transition(to next: any DownloadState) {
        state = next
    }

    func start() {
        state.start(on: self)
    }

    func cancel() {
        state.cancel(on: self)
    }
}

struct PendingDownloadState: DownloadState {
    let name = "pending"

    func start(on download: Download) {
        download.transition(to: ActiveDownloadState())
    }

    func cancel(on download: Download) {
        download.transition(to: CancelledDownloadState())
    }
}

struct ActiveDownloadState: DownloadState {
    let name = "active"

    func start(on download: Download) {}

    func cancel(on download: Download) {
        download.transition(to: CancelledDownloadState())
    }
}

struct CancelledDownloadState: DownloadState {
    let name = "cancelled"
    func start(on download: Download) {}
    func cancel(on download: Download) {}
}

let download = Download()
download.start()
download.cancel()
precondition(download.stateName == "cancelled")
```

## Trade-offs

State-specific branches and transitions become local. The number of types grows, and distributed transition calls can hide the complete state machine without a diagram or table.

## Testing strategy

Create a transition matrix covering every state and event, including ignored and invalid events. Test side effects exactly once and verify state restoration if persisted.

## Related patterns

Strategy is selected by policy rather than lifecycle. Memento captures state for restoration. Command can represent the events that drive transitions.
