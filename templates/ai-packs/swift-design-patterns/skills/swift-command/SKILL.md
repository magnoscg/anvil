---
name: swift-command
description: Use Command in Swift to give a user action identity so it can be queued, logged, retried, composed, or undone.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Command

## Intent

Encapsulate an action and its inputs behind an executable value, separating the invoker from the receiver.

## When to use it

Use it for editor actions, offline queues, shortcuts, undoable operations, or audit trails where actions need storage or lifecycle.

## When to avoid it

Avoid it for a direct one-line callback with no identity or lifecycle. Do not serialize commands that capture unstable object references.

## Participants

- Command protocol.
- Concrete command storing action inputs.
- Receiver that owns domain mutation.
- Invoker that schedules or records commands.

## Example

```swift
protocol EditingCommand {
    func execute()
    func undo()
}

final class NoteEditor {
    private(set) var text: String = ""

    func append(_ value: String) {
        text += value
    }

    func removeLast(_ count: Int) {
        text.removeLast(min(count, text.count))
    }
}

struct AppendTextCommand: EditingCommand {
    let editor: NoteEditor
    let text: String

    func execute() {
        editor.append(text)
    }

    func undo() {
        editor.removeLast(text.count)
    }
}

final class CommandHistory {
    private var executed: [any EditingCommand] = []

    func run(_ command: any EditingCommand) {
        command.execute()
        executed.append(command)
    }

    func undoLast() {
        executed.popLast()?.undo()
    }
}

let editor = NoteEditor()
let history = CommandHistory()
history.run(AppendTextCommand(editor: editor, text: "Hello"))
history.undoLast()
precondition(editor.text.isEmpty)
```

## Trade-offs

Actions become queueable and testable, and invokers stay generic. Command count grows and undo requires a precise model of side effects and failure.

## Testing strategy

Verify execute, undo, repeated execution, ordering, partial failure, idempotency, and serialization boundaries. Test receiver invariants independently.

## Related patterns

Memento can supply snapshots for undo. Chain routes a command among handlers. Strategy represents policy without action history.
