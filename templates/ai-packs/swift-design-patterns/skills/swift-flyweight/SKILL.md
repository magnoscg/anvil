---
name: swift-flyweight
description: >
  Swift Flyweight design pattern -- Structural. Use when sharing common state between many objects,
  reducing memory with cached immutable data, or optimizing table/collection view cell rendering.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Flyweight -- Swift

> **Category**: Structural
> **Intent**: Fit more objects into available RAM by sharing common parts of state between multiple objects instead of keeping all data in each object.

## When to Use

The Flyweight pattern is appropriate when your application needs to spawn a huge number of similar objects that share a significant portion of their state. The pattern extracts the repeating intrinsic state from objects and shares it, dramatically reducing memory consumption.

Use Flyweight when you can split an object's state into intrinsic (shared, immutable) and extrinsic (unique, context-dependent) parts. The intrinsic state is stored inside the flyweight and the extrinsic state is passed to methods. This is especially effective in iOS when rendering large lists, maps with thousands of pins, or particle systems where many objects share visual properties.

In Swift, the Flyweight pattern pairs well with value types for extrinsic state (structs passed to flyweight methods) and reference types for the shared intrinsic state (class instances cached in a factory). Swift's `NSCache` or custom dictionaries serve as natural flyweight factories. Consider this pattern when profiling reveals high memory usage from many similar objects.

## Structure

| Participant | Role |
|-------------|------|
| Flyweight | Contains the intrinsic state (shared portion) that can be shared across multiple contexts. Accepts extrinsic state via method parameters. |
| Flyweight Factory | Manages a pool of existing flyweights. Returns an existing flyweight matching requested state or creates a new one if none exists. |
| Context | Contains the extrinsic state, unique across all original objects. When paired with a flyweight, represents the full state of the original object. |
| Client | Calculates or stores extrinsic state and passes it to flyweight methods. |

## Conceptual Example

```swift
import XCTest

/// The Flyweight stores a common portion of the state (also called intrinsic
/// state) that belongs to multiple real business entities. The Flyweight
/// accepts the rest of the state (extrinsic state, unique for each entity) via
/// its method parameters.
class Flyweight {

    private let sharedState: [String]

    init(sharedState: [String]) {
        self.sharedState = sharedState
    }

    func operation(uniqueState: [String]) {
        print("Flyweight: Displaying shared (\(sharedState)) and unique (\(uniqueState)) state.\n")
    }
}

/// The Flyweight Factory creates and manages the Flyweight objects. It ensures
/// that flyweights are shared correctly. When the client requests a flyweight,
/// the factory either returns an existing instance or creates a new one, if it
/// doesn't exist yet.
class FlyweightFactory {

    private var flyweights: [String: Flyweight]

    init(states: [[String]]) {

        var flyweights = [String: Flyweight]()

        for state in states {
            flyweights[state.key] = Flyweight(sharedState: state)
        }

        self.flyweights = flyweights
    }

    /// Returns an existing Flyweight with a given state or creates a new one.
    func flyweight(for state: [String]) -> Flyweight {

        let key = state.key

        guard let foundFlyweight = flyweights[key] else {

            print("FlyweightFactory: Can't find a flyweight, creating new one.\n")
            let flyweight = Flyweight(sharedState: state)
            flyweights.updateValue(flyweight, forKey: key)
            return flyweight
        }
        print("FlyweightFactory: Reusing existing flyweight.\n")
        return foundFlyweight
    }

    func printFlyweights() {
        print("FlyweightFactory: I have \(flyweights.count) flyweights:\n")
        for item in flyweights {
            print(item.key)
        }
    }
}

extension Array where Element == String {

    /// Returns a Flyweight's string hash for a given state.
    var key: String {
        return self.joined()
    }
}


class FlyweightConceptual: XCTestCase {

    func testFlyweight() {

        let factory = FlyweightFactory(states:
        [
            ["Chevrolet", "Camaro2018", "pink"],
            ["Mercedes Benz", "C300", "black"],
            ["Mercedes Benz", "C500", "red"],
            ["BMW", "M5", "red"],
            ["BMW", "X6", "white"]
        ])

        factory.printFlyweights()

        addCarToPoliceDatabase(factory,
                "CL234IR",
                "James Doe",
                "BMW",
                "M5",
                "red")

        addCarToPoliceDatabase(factory,
                "CL234IR",
                "James Doe",
                "BMW",
                "X1",
                "red")

        factory.printFlyweights()
    }

    func addCarToPoliceDatabase(
            _ factory: FlyweightFactory,
            _ plates: String,
            _ owner: String,
            _ brand: String,
            _ model: String,
            _ color: String) {

        print("Client: Adding a car to database.\n")

        let flyweight = factory.flyweight(for: [brand, model, color])

        flyweight.operation(uniqueState: [plates, owner])
    }
}
```

**Output:**
```
FlyweightFactory: I have 5 flyweights:

Mercedes BenzC500red
ChevroletCamaro2018pink
Mercedes BenzC300black
BMWX6white
BMWM5red
Client: Adding a car to database.

FlyweightFactory: Reusing existing flyweight.

Flyweight: Displaying shared (["BMW", "M5", "red"]) and unique (["CL234IR", "James Doe"]) state.

Client: Adding a car to database.

FlyweightFactory: Can't find a flyweight, creating new one.

Flyweight: Displaying shared (["BMW", "X1", "red"]) and unique (["CL234IR", "James Doe"]) state.

FlyweightFactory: I have 6 flyweights:

Mercedes BenzC500red
BMWX1red
ChevroletCamaro2018pink
Mercedes BenzC300black
BMWX6white
BMWM5red
```

## Real-World Example

```swift
import XCTest
import UIKit

class FlyweightRealWorld: XCTestCase {

    func testFlyweightRealWorld() {

        let maineCoon = Animal(name: "Maine Coon",
                               country: "USA",
                               type: .cat)

        let sphynx = Animal(name: "Sphynx",
                            country: "Egypt",
                            type: .cat)

        let bulldog = Animal(name: "Bulldog",
                             country: "England",
                             type: .dog)

        print("Client: I created a number of objects to display")

        print("Client: Let's show animals for the 1st time\n")
        display(animals: [maineCoon, sphynx, bulldog])

        print("\nClient: I have a new dog, let's show it the same way!\n")

        let germanShepherd = Animal(name: "German Shepherd",
                              country: "Germany",
                              type: .dog)

        display(animals: [germanShepherd])
    }
}

extension FlyweightRealWorld {

    func display(animals: [Animal]) {

        let cells = loadCells(count: animals.count)

        for index in 0..<animals.count {
            cells[index].update(with: animals[index])
        }
    }

    func loadCells(count: Int) -> [Cell] {
        return Array(repeating: Cell(), count: count)
    }
}

enum Type: String {
    case cat
    case dog
}

class Cell {

    private var animal: Animal?

    func update(with animal: Animal) {
        self.animal = animal
        let type = animal.type.rawValue
        let photos = "photos \(animal.appearance.photos.count)"
        print("Cell: Updating an appearance of a \(type)-cell: \(photos)\n")
    }
}

struct Animal: Equatable {

    let name: String
    let country: String
    let type: Type

    var appearance: Appearance {
        return AppearanceFactory.appearance(for: type)
    }
}

struct Appearance: Equatable {

    let photos: [UIImage]
    let backgroundColor: UIColor
}

extension Animal: CustomStringConvertible {

    var description: String {
        return "\(name), \(country), \(type.rawValue) + \(appearance.description)"
    }
}

extension Appearance: CustomStringConvertible {

    var description: String {
        return "photos: \(photos.count), \(backgroundColor)"
    }
}

class AppearanceFactory {

    private static var cache = [Type: Appearance]()

    static func appearance(for key: Type) -> Appearance {

        guard cache[key] == nil else {
            print("AppearanceFactory: Reusing an existing \(key.rawValue)-appearance.")
            return cache[key]!
        }

        print("AppearanceFactory: Can't find a cached \(key.rawValue)-object, creating a new one.")

        switch key {
        case .cat:
            cache[key] = catInfo
        case .dog:
            cache[key] = dogInfo
        }

        return cache[key]!
    }
}

extension AppearanceFactory {

    private static var catInfo: Appearance {
        return Appearance(photos: [UIImage()], backgroundColor: .red)
    }

    private static var dogInfo: Appearance {
        return Appearance(photos: [UIImage(), UIImage()], backgroundColor: .blue)
    }
}
```

**Output:**
```
Client: I created a number of objects to display
Client: Let's show animals for the 1st time

AppearanceFactory: Can't find a cached cat-object, creating a new one.
Cell: Updating an appearance of a cat-cell: photos 1

AppearanceFactory: Reusing an existing cat-appearance.
Cell: Updating an appearance of a cat-cell: photos 1

AppearanceFactory: Can't find a cached dog-object, creating a new one.
Cell: Updating an appearance of a dog-cell: photos 2


Client: I have a new dog, let's show it the same way!

AppearanceFactory: Reusing an existing dog-appearance.
Cell: Updating an appearance of a dog-cell: photos 2
```

## iOS Framework Usage

- **UIKit**: `UITableView` and `UICollectionView` cell reuse (`dequeueReusableCell(withIdentifier:)`) is the most prominent Flyweight implementation in iOS. Cells are shared objects whose extrinsic state (content) is set via `cellForRowAt`.
- **SwiftUI**: `ViewModifier` and the view builder system internally share and deduplicate view descriptions. The diffing engine avoids creating new view instances when the body hasn't changed, acting as an implicit flyweight system.
- **Foundation/Combine**: `NSAttributedString` uses shared font descriptors and paragraph styles. `NSCache` provides a built-in eviction-aware flyweight factory. String interning in `NSString` shares identical string instances.

## Swift-Specific Notes

- Use Swift structs for extrinsic state since they are value types with copy-on-write semantics, naturally separating unique per-context data from shared flyweight state.
- Leverage `NSCache` as a flyweight factory when you want automatic memory pressure eviction, or use a plain `[Key: Flyweight]` dictionary when you need deterministic lifetimes.
- Computed properties (like `appearance` in the real-world example) elegantly defer flyweight lookup to access time, keeping the context struct lightweight and avoiding upfront allocation.
- Combine with Swift enums as cache keys (e.g., `Type.cat`, `Type.dog`) to get type-safe, hashable keys without string manipulation overhead.
- When the shared state includes images or large data, consider using `weak` references in the factory dictionary so flyweights are deallocated when no context holds them, preventing memory leaks.

## Related Patterns

- **Composite**: The Flyweight pattern shows how to make lots of little objects, whereas Composite shows how to make a tree structure from them.
- **Singleton**: The Flyweight Factory is often implemented as a Singleton since a single factory is sufficient for most use cases.
- **Strategy**: Flyweight objects often resemble shared Strategy objects, but flyweights represent state while strategies represent behavior.
