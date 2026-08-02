---
name: swift-template-method
description: Use Template Method in Swift when a class-based workflow has a stable sequence but a small set of controlled variant steps.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Template Method

## Intent

Define the invariant order of a workflow once while allowing subclasses to replace named steps.

## When to use it

Use it in an existing class hierarchy for import, export, migration, or test harness flows whose sequencing must remain fixed.

## When to avoid it

Prefer composition in new Swift code when policies need runtime replacement or independent testing. Avoid fragile base classes with many hooks and hidden call-order requirements.

## Participants

- Abstract base class defining the final template method.
- Primitive operations and optional hooks.
- Concrete subclasses implementing variant steps.

## Example

```swift
import Foundation

class ProfileImportWorkflow {
    final func run(raw: String) -> [String] {
        let fields = parse(raw: raw)
        let valid = validate(fields: fields)
        return persist(fields: valid)
    }

    func parse(raw: String) -> [String] {
        fatalError("Subclass must parse input")
    }

    func validate(fields: [String]) -> [String] {
        fields.filter { !$0.isEmpty }
    }

    func persist(fields: [String]) -> [String] {
        fields
    }
}

final class CSVProfileImport: ProfileImportWorkflow {
    override func parse(raw: String) -> [String] {
        raw.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
    }

    override func validate(fields: [String]) -> [String] {
        super.validate(fields: fields).map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

let imported = CSVProfileImport().run(raw: "Ana, ana@example.com")
precondition(imported == ["Ana", "ana@example.com"])
```

## Trade-offs

Sequence is protected and common behavior is reused. Inheritance couples variants to base-class internals, and hooks can violate assumptions if their contracts are vague.

## Testing strategy

Test the invariant step order with a recording subclass, each concrete override, base defaults, and failure propagation. Keep hook preconditions documented.

## Related patterns

Strategy composes replaceable algorithms. Factory Method often appears as a template hook. Command represents each step when workflows need queuing or undo.
