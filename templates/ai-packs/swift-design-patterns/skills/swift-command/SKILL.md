---
name: swift-command
description: >
  Swift Command design pattern -- Behavioral. Use when encapsulating requests as objects,
  implementing undo/redo, queuing operations, or scheduling deferred execution.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Command -- Swift

> **Category**: Behavioral
> **Intent**: Turn a request into a stand-alone object that contains all information about the request. This transformation lets you pass requests as method arguments, delay or queue a request's execution, and support undoable operations.

## When to Use

The Command pattern is appropriate when you want to parametrize objects with operations. Command turns a specific method call into a stand-alone object, allowing you to pass commands as method arguments, store them, switch executed commands at runtime, and more.

Use Command when you want to queue operations, schedule their execution, or execute them remotely. As with any other object, a command can be serialized (converted to a string) and stored in a database or sent over a network. This makes it ideal for task queues, operation histories, and undo/redo stacks in iOS applications.

In Swift, the Command pattern shines for implementing Siri Shortcuts, Home automation sequences, background task scheduling, and operation queues. The Foundation framework's `Operation` and `OperationQueue` classes are a built-in Command implementation. The pattern also maps naturally to closures in Swift -- a closure capturing its context is essentially a lightweight command object.

## Structure

| Participant | Role |
|-------------|------|
| Command (Protocol) | Declares the interface for executing an operation, typically a single `execute()` method. |
| Concrete Command | Implements the execution interface. Defines a binding between a Receiver and an action. Calls corresponding operations on the Receiver. |
| Receiver | Knows how to perform the operations associated with carrying out a request. Any class may serve as a Receiver. |
| Invoker | Asks the command to carry out the request. Does not know the concrete command class -- works with commands only through the Command interface. |
| Client | Creates Concrete Command objects and sets their receivers. |

## Conceptual Example

```swift
import XCTest

/// The Command interface declares a method for executing a command.
protocol Command {
    func execute()
}

/// Some commands can implement simple operations on their own.
class SimpleCommand: Command {
    private var payload: String

    init(_ payload: String) {
        self.payload = payload
    }

    func execute() {
        print("SimpleCommand: See, I can do simple things like printing (" + payload + ")")
    }
}

/// However, some commands can delegate more complex operations to other
/// objects, called "receivers."
class ComplexCommand: Command {
    private var receiver: Receiver

    /// Context data, required for launching the receiver's methods.
    private var a: String
    private var b: String

    /// Complex commands can accept one or several receiver objects along with
    /// any context data via the constructor.
    init(_ receiver: Receiver, _ a: String, _ b: String) {
        self.receiver = receiver
        self.a = a
        self.b = b
    }

    /// Commands can delegate to any methods of a receiver.
    func execute() {
        print("ComplexCommand: Complex stuff should be done by a receiver object.\n")
        receiver.doSomething(a)
        receiver.doSomethingElse(b)
    }
}

/// The Receiver classes contain some important business logic. They know how to
/// perform all kinds of operations, associated with carrying out a request. In
/// fact, any class may serve as a Receiver.
class Receiver {
    func doSomething(_ a: String) {
        print("Receiver: Working on (" + a + ")\n")
    }

    func doSomethingElse(_ b: String) {
        print("Receiver: Also working on (" + b + ")\n")
    }
}

/// The Invoker is associated with one or several commands. It sends a request
/// to the command.
class Invoker {
    private var onStart: Command?
    private var onFinish: Command?

    /// Initialize commands.
    func setOnStart(_ command: Command) {
        onStart = command
    }

    func setOnFinish(_ command: Command) {
        onFinish = command
    }

    /// The Invoker does not depend on concrete command or receiver classes. The
    /// Invoker passes a request to a receiver indirectly, by executing a
    /// command.
    func doSomethingImportant() {
        print("Invoker: Does anybody want something done before I begin?")
        onStart?.execute()
        print("Invoker: ...doing something really important...")
        print("Invoker: Does anybody want something done after I finish?")
        onFinish?.execute()
    }
}

/// Let's see how it all comes together.
class CommandConceptual: XCTestCase {
    func test() {
        let invoker = Invoker()
        invoker.setOnStart(SimpleCommand("Say Hi!"))

        let receiver = Receiver()
        invoker.setOnFinish(ComplexCommand(receiver, "Send email", "Save report"))
        invoker.doSomethingImportant()
    }
}
```

**Output:**
```
Invoker: Does anybody want something done before I begin?
SimpleCommand: See, I can do simple things like printing (Say Hi!)
Invoker: ...doing something really important...
Invoker: Does anybody want something done after I finish?
ComplexCommand: Complex stuff should be done by a receiver object.

Receiver: Working on (Send email)

Receiver: Also working on (Save report)
```

## Real-World Example

```swift
import Foundation
import XCTest

class DelayedOperation: Operation, @unchecked Sendable {
    private var delay: TimeInterval

    init(_ delay: TimeInterval = 0) {
        self.delay = delay
    }

    override var isExecuting : Bool {
        get { return _executing }
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    private var _executing : Bool = false

    override var isFinished : Bool {
        get { return _finished }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    private var _finished : Bool = false

    override func start() {
        guard delay > 0 else {
            _start()
            return
        }

        let deadline = DispatchTime.now() + delay
        DispatchQueue(label: "").asyncAfter(deadline: deadline) {
            self._start()
        }
    }

    private func _start() {
        guard !self.isCancelled else {
            print("\(self): operation is canceled")
            self.isFinished = true
            return
        }

        self.isExecuting = true
        self.main()
        self.isExecuting = false
        self.isFinished = true
    }
}

class WindowOperation: DelayedOperation, @unchecked Sendable {
    override func main() {
        print("\(self): Windows are closed via HomeKit.")
    }

    override var description: String { return "WindowOperation" }
}

class DoorOperation: DelayedOperation, @unchecked Sendable {
    override func main() {
        print("\(self): Doors are closed via HomeKit.")
    }

    override var description: String { return "DoorOperation" }
}

class TaxiOperation: DelayedOperation, @unchecked Sendable {
    override func main() {
        print("\(self): Taxi is ordered via Uber")
    }

    override var description: String { return "TaxiOperation" }
}

class CommandRealWorld: XCTestCase {
    func testCommandRealWorld() {
        prepareTestEnvironment {
            let siri = SiriShortcuts.shared

            print("User: Hey Siri, I am leaving my home")
            siri.perform(.leaveHome)

            print("User: Hey Siri, I am leaving my work in 3 minutes")
            siri.perform(.leaveWork, delay: 3)

            print("User: Hey Siri, I am still working")
            siri.cancel(.leaveWork)
        }
    }
}

extension CommandRealWorld {
    struct ExecutionTime {
        static let max: TimeInterval = 5
        static let waiting: TimeInterval = 4
    }

    func prepareTestEnvironment(_ execution: () -> ()) {
        let expectation = self.expectation(description: "Expectation for async operations")

        let deadline = DispatchTime.now() + ExecutionTime.waiting
        DispatchQueue.main.asyncAfter(deadline: deadline) { expectation.fulfill() }

        execution()

        wait(for: [expectation], timeout: ExecutionTime.max)
    }
}

class SiriShortcuts {
    static let shared = SiriShortcuts()
    private lazy var queue = OperationQueue()

    private init() {}

    enum Action: String {
        case leaveHome
        case leaveWork
    }

    func perform(_ action: Action, delay: TimeInterval = 0) {
        print("Siri: performing \(action)-action\n")
        switch action {
        case .leaveHome:
            add(operation: WindowOperation(delay))
            add(operation: DoorOperation(delay))
        case .leaveWork:
            add(operation: TaxiOperation(delay))
        }
    }

    func cancel(_ action: Action) {
        print("Siri: canceling \(action)-action\n")
        switch action {
        case .leaveHome:
            cancelOperation(with: WindowOperation.self)
            cancelOperation(with: DoorOperation.self)
        case .leaveWork:
            cancelOperation(with: TaxiOperation.self)
        }
    }

    private func cancelOperation(with operationType: Operation.Type) {
        queue.operations.filter { operation in
            return type(of: operation) == operationType
        }.forEach({ $0.cancel() })
    }

    private func add(operation: Operation) {
        queue.addOperation(operation)
    }
}
```

**Output:**
```
User: Hey Siri, I am leaving my home
Siri: performing leaveHome-action

User: Hey Siri, I am leaving my work in 3 minutes
Siri: performing leaveWork-action

User: Hey Siri, I am still working
Siri: canceling leaveWork-action

DoorOperation: Doors are closed via HomeKit.
WindowOperation: Windows are closed via HomeKit.
TaxiOperation: operation is canceled
```

## iOS Framework Usage

- **UIKit**: `UIUndoManager` is the canonical Command pattern in UIKit. Each undoable action is registered as a command that can be reversed. `Target-Action` mechanism (`addTarget(_:action:for:)`) is also a command pattern where the selector represents the command.
- **SwiftUI**: `Button(action:)` closures, `onTapGesture`, and `task {}` modifiers encapsulate commands. `UndoManager` integration via `@Environment(\.undoManager)` brings Command pattern undo/redo to SwiftUI views.
- **Foundation/Combine**: `Operation` and `OperationQueue` are the built-in Command infrastructure. `BlockOperation` is a closure-based command. In Combine, `Deferred` publishers act as lazy commands that execute only when subscribed to.

## Swift-Specific Notes

- Swift closures are lightweight command objects. For simple cases, `() -> Void` closures can replace full command classes, stored in arrays for undo stacks or queued for deferred execution.
- Use Swift enums with associated values to represent a finite set of commands (like `Action.leaveHome` in the real-world example), providing type-safe command dispatching with exhaustive switch statements.
- Foundation's `Operation` class provides built-in support for dependencies (`addDependency`), cancellation (`cancel()`), and KVO-based state tracking -- use it as your command base class for complex task orchestration.
- Combine `async/await` with the Command pattern by making `execute()` an `async throws` method, enabling commands that perform network requests or database operations with structured concurrency.
- Mark command classes as `@unchecked Sendable` when they manage their own thread safety (as in the real-world example), or prefer actors for commands that need isolation in Swift's strict concurrency model.

## Related Patterns

- **Chain of Responsibility**: Handlers in a chain can be implemented as Commands, where each handler wraps a specific operation.
- **Memento**: Can be used together with Command for implementing undo. Commands perform operations on the target object, while mementos save the state of that object just before a command gets executed.
- **Strategy**: Both encapsulate algorithms/behavior, but Commands typically have a wider scope (including receivers, undo) while Strategies replace interchangeable algorithms.
