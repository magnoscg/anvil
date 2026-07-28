---
name: swift-structural-patterns
description: >
  Overview of Structural design patterns in Swift. Use when choosing between
  Adapter, Bridge, Composite, Decorator, Facade, Flyweight, and Proxy patterns.
  Provides selection guide and links to individual pattern skills.
license: MIT
metadata:
  category: Design Patterns
  source: refactoring.guru
---

# Structural Design Patterns in Swift

> Structural patterns explain how to assemble objects and classes into larger structures, while keeping these structures flexible and efficient.

## Overview

Structural design patterns are concerned with how classes and objects are composed to form larger structures. Structural class patterns use inheritance to compose interfaces or implementations, while structural object patterns describe ways to compose objects to realize new functionality.

In Swift, structural patterns benefit from protocol extensions, generics, property wrappers, and Swift's powerful type system.

## Pattern Selection Guide

| Pattern | Use When | Swift Feature | iOS Example |
|---------|----------|---------------|-------------|
| **Adapter** | Making incompatible interfaces work together | Protocol conformance, extensions | Wrapping C APIs, bridging ObjC/Swift |
| **Bridge** | Separating abstraction from implementation to vary independently | Protocols as abstractions | Cross-platform rendering, driver abstractions |
| **Composite** | Treating individual objects and compositions uniformly (tree structures) | Recursive protocols | `UIView` subview hierarchy, file systems |
| **Decorator** | Adding behavior dynamically without modifying existing code | Protocol extensions, wrapping | `InputStream` decorators, middleware chains |
| **Facade** | Providing a simplified interface to a complex subsystem | Wrapper classes/structs | `URLSession` (facades networking), `AVPlayer` |
| **Flyweight** | Sharing common state between many objects to save memory | Shared caches, `NSCache` | `UIFont`, `UIColor` system colors, string interning |
| **Proxy** | Providing a placeholder/surrogate to control access to another object | Lazy properties, protocol conformance | Lazy image loading, access control wrappers |

## Quick Comparison

### When interfaces DON'T match
Use **Adapter** to make an existing class work with an interface it wasn't designed for.

### When you need to VARY abstraction and implementation independently
Use **Bridge** to split a large class or set of closely related classes into two separate hierarchies.

### When you have TREE structures
Use **Composite** to treat leaves and containers uniformly. UIKit's view hierarchy is the classic example.

### When you need to ADD responsibilities dynamically
Use **Decorator** to wrap objects with additional behavior. Prefer this over subclassing for flexible combinations.

### When you need to SIMPLIFY a complex API
Use **Facade** to provide a clean interface to a messy subsystem.

### When MEMORY is critical with many similar objects
Use **Flyweight** to share common state. Swift value types and copy-on-write help here.

### When you need to CONTROL access to an object
Use **Proxy** for lazy loading, access control, logging, or caching.

## Decision Tree

```
Need to compose or structure objects?
├── Interface mismatch? → Adapter
├── Need abstraction + implementation to vary? → Bridge
├── Tree/hierarchy structure? → Composite
├── Add behavior without changing class? → Decorator
├── Complex subsystem needs simple API? → Facade
├── Many similar objects eating memory? → Flyweight
└── Need to control access/lazy load? → Proxy
```

## Individual Pattern Skills

- `/swift-adapter` — Makes incompatible interfaces compatible through wrapping
- `/swift-bridge` — Separates abstraction from implementation so both can vary
- `/swift-composite` — Composes objects into tree structures for part-whole hierarchies
- `/swift-decorator` — Attaches additional responsibilities to objects dynamically
- `/swift-facade` — Provides a simplified interface to a complex subsystem
- `/swift-flyweight` — Shares common state among many objects to reduce memory usage
- `/swift-proxy` — Provides a surrogate or placeholder to control access to another object

## Swift-Specific Considerations

- **Protocol Extensions**: Enable Decorator-like behavior without wrapper classes
- **Property Wrappers**: `@propertyWrapper` is essentially a built-in Proxy/Decorator mechanism
- **Extensions**: Swift extensions can act as lightweight Adapters by adding protocol conformance to existing types
- **Value Types**: `struct` with copy-on-write provides natural Flyweight optimization
- **Generics**: Enable type-safe structural patterns without runtime casting
- **@dynamicMemberLookup**: Can implement Proxy pattern with dot-syntax forwarding
