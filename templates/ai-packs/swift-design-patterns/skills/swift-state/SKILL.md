---
name: swift-state
description: >
  Swift State design pattern — Behavioral. Use when object behavior changes based on internal
  state, implementing state machines, or replacing complex conditionals with state objects.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# State — Swift

> **Category**: Behavioral
> **Intent**: State is a behavioral design pattern that allows an object to change the behavior when its internal state changes. The object will appear to change its class.

## When to Use

Use the State pattern when you have an object that behaves differently depending on its current state, the number of states is large, and the state-specific code changes frequently. The pattern suggests extracting all state-specific code into a set of distinct classes, allowing the original object to delegate behavior to the current state object rather than implementing all behaviors itself.

This pattern is particularly valuable when your code has massive conditionals that switch behavior based on the current values of fields. With State, you move branches of these conditionals into methods of corresponding state classes. At the same time, you can introduce new states without changing existing state classes or the context.

Consider the State pattern when building features like document workflows (Draft -> Review -> Published), connection managers (Connecting -> Connected -> Disconnected), media players (Playing -> Paused -> Stopped), or any entity with a finite number of well-defined states and transitions.

## Structure

| Participant | Role |
|-------------|------|
| Context | Stores a reference to the current state object and delegates state-specific work to it. Communicates with the state via the State protocol. |
| State (Protocol) | Declares the interface for state-specific behavior. |
| ConcreteState | Implements behavior associated with a particular state. May trigger state transitions via the context. |

## Conceptual Example

```swift
import XCTest

class Context {
    private var state: State

    init(_ state: State) {
        self.state = state
        transitionTo(state: state)
    }

    func transitionTo(state: State) {
        print("Context: Transition to " + String(describing: state))
        self.state = state
        self.state.update(context: self)
    }

    func request1() {
        state.handle1()
    }

    func request2() {
        state.handle2()
    }
}

protocol State: AnyObject {
    func update(context: Context)
    func handle1()
    func handle2()
}

class BaseState: State {
    private(set) weak var context: Context?

    func update(context: Context) {
        self.context = context
    }

    func handle1() {}
    func handle2() {}
}

class ConcreteStateA: BaseState {
    override func handle1() {
        print("ConcreteStateA handles request1.")
        print("ConcreteStateA wants to change the state of the context.\n")
        context?.transitionTo(state: ConcreteStateB())
    }

    override func handle2() {
        print("ConcreteStateA handles request2.\n")
    }
}

class ConcreteStateB: BaseState {
    override func handle1() {
        print("ConcreteStateB handles request1.\n")
    }

    override func handle2() {
        print("ConcreteStateB handles request2.")
        print("ConcreteStateB wants to change the state of the context.\n")
        context?.transitionTo(state: ConcreteStateA())
    }
}

class StateConceptual: XCTestCase {
    func test() {
        let context = Context(ConcreteStateA())
        context.request1()
        context.request2()
    }
}
```

**Output:**
```
Context: Transition to ConcreteStateA
ConcreteStateA handles request1.
ConcreteStateA wants to change the state of the context.
Context: Transition to ConcreteStateB
ConcreteStateB handles request2.
ConcreteStateB wants to change the state of the context.
Context: Transition to ConcreteStateA
```

## Real-World Example

```swift
import XCTest

class StateRealWorld: XCTestCase {
    func test() {
        print("Client: I'm starting working with a location tracker")
        let tracker = LocationTracker()

        print()
        tracker.startTracking()

        print()
        tracker.pauseTracking(for: 2)

        print()
        tracker.makeCheckIn()

        print()
        tracker.findMyChildren()

        print()
        tracker.stopTracking()
    }
}

class LocationTracker {
    private lazy var trackingState: TrackingState = EnabledTrackingState(tracker: self)

    func startTracking() { trackingState.startTracking() }
    func stopTracking() { trackingState.stopTracking() }
    func pauseTracking(for time: TimeInterval) { trackingState.pauseTracking(for: time) }
    func makeCheckIn() { trackingState.makeCheckIn() }
    func findMyChildren() { trackingState.findMyChildren() }

    func update(state: TrackingState) {
        trackingState = state
    }
}

protocol TrackingState {
    func startTracking()
    func stopTracking()
    func pauseTracking(for time: TimeInterval)
    func makeCheckIn()
    func findMyChildren()
}

class EnabledTrackingState: TrackingState {
    private weak var tracker: LocationTracker?

    init(tracker: LocationTracker?) { self.tracker = tracker }

    func startTracking() {
        print("EnabledTrackingState: startTracking is invoked")
        print("EnabledTrackingState: tracking location....1")
        print("EnabledTrackingState: tracking location....2")
        print("EnabledTrackingState: tracking location....3")
    }

    func stopTracking() {
        print("EnabledTrackingState: Received 'stop tracking'")
        print("EnabledTrackingState: Changing state to 'disabled'...")
        tracker?.update(state: DisabledTrackingState(tracker: tracker))
        tracker?.stopTracking()
    }

    func pauseTracking(for time: TimeInterval) {
        print("EnabledTrackingState: Received 'pause tracking' for \(time) seconds")
        print("EnabledTrackingState: Changing state to 'disabled'...")
        tracker?.update(state: DisabledTrackingState(tracker: tracker))
        tracker?.pauseTracking(for: time)
    }

    func makeCheckIn() {
        print("EnabledTrackingState: performing check-in at the current location")
    }

    func findMyChildren() {
        print("EnabledTrackingState: searching for children...")
    }
}

class DisabledTrackingState: TrackingState {
    private weak var tracker: LocationTracker?

    init(tracker: LocationTracker?) { self.tracker = tracker }

    func startTracking() {
        print("DisabledTrackingState: Received 'start tracking'")
        print("DisabledTrackingState: Changing state to 'enabled'...")
        tracker?.update(state: EnabledTrackingState(tracker: tracker))
    }

    func pauseTracking(for time: TimeInterval) {
        print("DisabledTrackingState: Pause tracking for \(time) seconds")
        for i in 0...Int(time) {
            print("DisabledTrackingState: pause...\(i)")
        }
        print("DisabledTrackingState: Time is over")
        print("DisabledTrackingState: Returning to 'enabled state'...\n")
        tracker?.update(state: EnabledTrackingState(tracker: tracker))
        tracker?.startTracking()
    }

    func stopTracking() {
        print("DisabledTrackingState: Received 'stop tracking'")
        print("DisabledTrackingState: Do nothing...")
    }

    func makeCheckIn() {
        print("DisabledTrackingState: Received 'make check-in'")
        print("DisabledTrackingState: Changing state to 'enabled'...")
        tracker?.update(state: EnabledTrackingState(tracker: tracker))
        tracker?.makeCheckIn()
    }

    func findMyChildren() {
        print("DisabledTrackingState: Received 'find my children'")
        print("DisabledTrackingState: Changing state to 'enabled'...")
        tracker?.update(state: EnabledTrackingState(tracker: tracker))
        tracker?.findMyChildren()
    }
}
```

## iOS Framework Usage

- **UIKit**: `UIGestureRecognizer` uses states (Possible, Began, Changed, Ended, Cancelled, Failed). `UIViewController` lifecycle is state-driven (viewDidLoad -> viewWillAppear -> viewDidAppear...).
- **SwiftUI**: State management with `@State`, `@Binding`, `@Observable` drives view behavior changes. Enums with views in `switch` statements implement lightweight State pattern.
- **Foundation**: `URLSessionTask` states (Running, Suspended, Canceling, Completed). `Operation` states (Ready, Executing, Finished, Cancelled).

## Swift-Specific Notes

- **Enums with associated values**: Swift enums provide an elegant, type-safe alternative to class-based State hierarchies: `enum ConnectionState { case connecting(URL), connected(Socket), disconnected(Error?) }`.
- **Protocol-oriented**: Define `State` as a protocol for class-based implementations when states need mutable back-references to the context.
- **Memory management**: Use `weak` references from state to context to avoid retain cycles when states hold context references.
- **Value type approach**: For simple state machines, prefer enum-based states. For complex behavior per state, use the protocol/class approach from the pattern.
- **Exhaustive switching**: Swift's compiler-enforced `switch` exhaustiveness catches missing state handling at compile time.

## Related Patterns

- **Strategy**: Both patterns are based on composition — they change behavior by delegating to helpers. Strategy makes objects independent and unaware of each other, while State allows dependencies between states and lets them transition freely.
- **Singleton**: State objects are often implemented as Singletons when they don't contain instance-specific data.
- **Flyweight**: State objects without instance-specific data can be shared as Flyweights.
