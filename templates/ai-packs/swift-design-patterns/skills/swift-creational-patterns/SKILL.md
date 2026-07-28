---
name: swift-creational-patterns
description: >
  Overview of Creational design patterns in Swift. Use when choosing between
  Singleton, Factory Method, Abstract Factory, Builder, and Prototype patterns.
  Provides selection guide and links to individual pattern skills.
license: MIT
metadata:
  category: Design Patterns
  source: refactoring.guru
---

# Creational Design Patterns in Swift

> Creational patterns provide object creation mechanisms that increase flexibility and reuse of existing code.

## Overview

Creational design patterns abstract the instantiation process. They help make a system independent of how its objects are created, composed, and represented. These patterns become important as systems evolve to depend more on object composition than class inheritance.

In Swift, creational patterns leverage language features like protocols, generics, access control, and value types to provide elegant solutions for object creation challenges.

## Pattern Selection Guide

| Pattern | Use When | Swift Feature | iOS Example |
|---------|----------|---------------|-------------|
| **Singleton** | Exactly one instance needed globally | `static let shared` | `UIApplication.shared`, `FileManager.default` |
| **Factory Method** | Subclasses should decide which class to instantiate | Protocols + extensions | `URLSessionConfiguration.default` vs `.ephemeral` |
| **Abstract Factory** | Families of related objects without specifying concrete classes | Protocol families | Cross-platform UI factories, theme systems |
| **Builder** | Complex object construction with many optional parameters | Method chaining, `@resultBuilder` | `URLComponents`, `NSAttributedString` construction |
| **Prototype** | Creating objects by cloning existing instances | `NSCopying`, value types (`struct`) | `UIView` copying, `struct` value semantics |

## Quick Comparison

### When you need ONE instance globally
Use **Singleton**. Swift makes this trivial with `static let shared` and guarantees thread-safe lazy initialization.

### When you need to CREATE objects but don't know the exact type
Use **Factory Method** if you have a single product family, or **Abstract Factory** if you have multiple related product families.

### When you need to BUILD complex objects step by step
Use **Builder**. Swift's `@resultBuilder` attribute provides a DSL-like approach (SwiftUI's `ViewBuilder` is a prime example).

### When you need to COPY existing objects
Use **Prototype**. In Swift, prefer `struct` value types for automatic copying. Use `NSCopying` for reference types that need cloning.

## Decision Tree

```
Need to create objects?
├── Only one instance ever? → Singleton
├── Don't know exact type at compile time?
│   ├── One product type? → Factory Method
│   └── Family of related types? → Abstract Factory
├── Complex construction with many params? → Builder
└── Need copies of existing objects? → Prototype
```

## Individual Pattern Skills

- `/swift-singleton` — Ensures a class has only one instance with a global access point
- `/swift-factory-method` — Defines an interface for creating objects, letting subclasses decide the type
- `/swift-abstract-factory` — Creates families of related objects without specifying concrete classes
- `/swift-builder` — Constructs complex objects step by step with different representations
- `/swift-prototype` — Creates new objects by copying existing ones

## Swift-Specific Considerations

- **Value Types**: Swift's `struct` and `enum` types provide copy-on-write semantics, making Prototype pattern nearly automatic
- **Protocol-Oriented Design**: Factory patterns in Swift lean heavily on protocols rather than abstract classes
- **Access Control**: `private init()` enforces Singleton pattern at the compiler level
- **@resultBuilder**: Swift's result builder attribute enables powerful Builder pattern DSLs
- **Generics**: Enable type-safe factory patterns without runtime casting
