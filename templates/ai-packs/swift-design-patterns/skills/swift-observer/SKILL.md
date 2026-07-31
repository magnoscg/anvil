---
name: swift-observer
description: Use Observer in Swift to publish domain events to multiple independent subscribers with explicit lifetime, delivery, and ordering rules.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Observer

## Intent

Notify an open set of subscribers when an event occurs without coupling the publisher to their concrete reactions.

## When to use it

Use it for domain events, UI state streams, analytics fan-out, or cache invalidation where several independent consumers react to one fact.

## When to avoid it

Avoid it for a required request-response collaborator or when ordering and failure must be coordinated. Hidden event graphs make product behavior difficult to trace.

## Participants

- Subject that owns subscriptions and publishes events.
- Event value carrying immutable facts.
- Observers with explicit registration and removal lifetime.

## Example

```swift
enum AccountEvent: Equatable {
    case signedIn(userID: String)
    case signedOut
}

final class AccountEventCenter {
    typealias Observer = (AccountEvent) -> Void

    private var nextID = 0
    private var observers: [Int: Observer] = [:]

    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> Int {
        defer { nextID += 1 }
        observers[nextID] = observer
        return nextID
    }

    func unsubscribe(_ ID: Int) {
        observers[ID] = nil
    }

    func publish(_ event: AccountEvent) {
        for observer in observers.values {
            observer(event)
        }
    }
}

let center = AccountEventCenter()
var received: [AccountEvent] = []
let token = center.subscribe { received.append($0) }
center.publish(.signedIn(userID: "user-7"))
center.unsubscribe(token)
center.publish(.signedOut)
precondition(received == [.signedIn(userID: "user-7")])
```

## Trade-offs

Publishers and subscribers evolve independently. Subscription lifetime, thread or actor delivery, ordering, backpressure, and observer failures become part of the contract.

## Testing strategy

Test zero and many observers, removal, duplicate registration, reentrant publication, ordering guarantees, and deallocation. Use deterministic schedulers for asynchronous delivery.

## Related patterns

Mediator coordinates reactions rather than broadcasting. Command gives a requested action identity; an event records something that already happened. AsyncSequence is often the native delivery boundary.
