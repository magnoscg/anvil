---
name: swift-behavioral-patterns
description: >
  Overview of Behavioral design patterns in Swift. Use when choosing between
  Chain of Responsibility, Command, Iterator, Mediator, Memento, Observer,
  State, Strategy, Template Method, and Visitor patterns.
  Provides selection guide and links to individual pattern skills.
license: MIT
metadata:
  category: Design Patterns
  source: refactoring.guru
---

# Behavioral Design Patterns in Swift

> Behavioral patterns are concerned with algorithms and the assignment of responsibilities between objects.

## Overview

Behavioral design patterns describe not just patterns of objects or classes but also the patterns of communication between them. These patterns characterize complex control flow that's difficult to follow at runtime. They shift your focus away from flow of control to let you concentrate on the way objects are interconnected.

In Swift, behavioral patterns leverage closures, protocol-oriented programming, Combine framework, and async/await for elegant implementations.

## Pattern Selection Guide

| Pattern | Use When | Swift Feature | iOS Example |
|---------|----------|---------------|-------------|
| **Chain of Responsibility** | Multiple handlers should try processing a request in order | Protocol chains, linked lists | `UIResponder` chain, middleware pipelines |
| **Command** | Encapsulating requests as objects for queuing, undo, or logging | Closures, `Codable` commands | `UndoManager`, `Operation`/`OperationQueue` |
| **Iterator** | Traversing a collection without exposing internals | `Sequence`/`IteratorProtocol` | `for-in` loops, custom collections |
| **Mediator** | Reducing chaotic dependencies between objects | Central coordinator object | `NotificationCenter`, `UINavigationController` |
| **Memento** | Capturing and restoring object state without violating encapsulation | `Codable`, `NSCoding` | `UserDefaults`, state restoration, undo |
| **Observer** | Notifying multiple objects about state changes | `Combine`, `NotificationCenter`, KVO | `@Published`, `ObservableObject`, `@Observable` |
| **State** | Object behavior changes based on internal state | Enum with associated values, protocols | `UIGestureRecognizer` states, connection states |
| **Strategy** | Interchangeable algorithms at runtime | Closures, protocol conformance | `sort(by:)`, `JSONEncoder` date strategies |
| **Template Method** | Defining algorithm skeleton with customizable steps | Protocol with default implementations | `UIViewController` lifecycle, `Hashable` |
| **Visitor** | Adding operations to object structures without modifying them | Protocol + double dispatch | Syntax tree walkers, serialization |

## Quick Comparison

### When REQUESTS need to be processed by a CHAIN of handlers
Use **Chain of Responsibility**. UIKit's responder chain is the canonical iOS example.

### When you need to ENCAPSULATE actions as objects
Use **Command** for undo/redo, queuing, scheduling, or logging operations.

### When you need to TRAVERSE a collection
Use **Iterator**. Swift's `Sequence` and `IteratorProtocol` make this a first-class language feature.

### When objects have TOO MANY direct connections
Use **Mediator** to centralize communication. Coordinator pattern in iOS is a Mediator variant.

### When you need to SAVE and RESTORE state
Use **Memento**. Swift's `Codable` protocol makes serialization trivial.

### When objects need to REACT to changes in other objects
Use **Observer**. In modern Swift, prefer Combine's `@Published` or Observation framework's `@Observable`.

### When behavior CHANGES based on STATE
Use **State** pattern. Swift enums with associated values provide a particularly elegant implementation.

### When you need INTERCHANGEABLE algorithms
Use **Strategy**. In Swift, closures often replace the full class hierarchy — `sort(by:)` is Strategy in action.

### When an ALGORITHM has fixed steps but variable implementations
Use **Template Method**. Swift protocols with default implementations are ideal for this.

### When you need to ADD operations to complex object structures
Use **Visitor** for operations across heterogeneous type hierarchies without modifying them.

## Decision Tree

```
Need to manage behavior/communication?
├── Request handled by chain of objects? → Chain of Responsibility
├── Encapsulate action as object? → Command
├── Traverse collection elements? → Iterator
├── Reduce coupling between many objects? → Mediator
├── Save/restore object state? → Memento
├── React to state changes? → Observer
├── Behavior varies by internal state? → State
├── Swap algorithms at runtime? → Strategy
├── Fixed algorithm, variable steps? → Template Method
└── Add operations without modifying classes? → Visitor
```

## Individual Pattern Skills

- `/swift-chain-of-responsibility` — Passes requests along a chain of handlers
- `/swift-command` — Encapsulates requests as objects with execute/undo support
- `/swift-iterator` — Traverses collections without exposing internal structure
- `/swift-mediator` — Reduces chaotic dependencies via a central coordinator
- `/swift-memento` — Captures and restores object state without breaking encapsulation
- `/swift-observer` — Notifies dependents automatically when state changes
- `/swift-state` — Alters behavior when internal state changes
- `/swift-strategy` — Defines interchangeable algorithm families
- `/swift-template-method` — Defines algorithm skeleton with customizable steps
- `/swift-visitor` — Adds operations to structures without modifying their classes

## Swift-Specific Considerations

- **Closures**: Replace many class-based behavioral patterns (Strategy, Command, Observer)
- **Combine Framework**: Provides reactive Observer implementation with `Publisher`/`Subscriber`
- **Observation Framework** (`@Observable`): Modern Swift alternative to KVO and Combine for state observation
- **`Sequence`/`IteratorProtocol`**: First-class language support for Iterator pattern
- **Enums with Associated Values**: Natural fit for State and Command patterns
- **`async/await`**: Enables modern implementations of Chain of Responsibility and Command
- **Protocol Default Implementations**: Enable Template Method without abstract classes
- **`Codable`**: Simplifies Memento pattern for state serialization
