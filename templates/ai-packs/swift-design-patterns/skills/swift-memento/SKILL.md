---
name: swift-memento
description: >
  Swift Memento design pattern -- Behavioral. Use when implementing undo/redo,
  saving and restoring object state, or creating snapshots for rollback.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Memento -- Swift

> **Category**: Behavioral
> **Intent**: Let you save and restore the previous state of an object without revealing the details of its implementation.

## When to Use

The Memento pattern is appropriate when you need to produce snapshots of an object's state to be able to restore a previous state. The pattern suggests storing the copy of the object's state in a special object called a memento, making the full state accessible only to the object that produced it.

Use Memento when direct access to the object's fields/getters/setters violates its encapsulation. The pattern makes the object itself responsible for creating a snapshot of its state, so no other object can read the snapshot, making the original object's state safe and secure.

In iOS development, the Memento pattern is essential for implementing undo/redo in text editors, drawing apps, and form wizards. It is also useful for saving view controller state during navigation (so users can return to the exact state they left), persisting editor drafts, and creating checkpoint/rollback mechanisms in multi-step processes like checkout flows or configuration wizards.

## Structure

| Participant | Role |
|-------------|------|
| Originator | Can produce snapshots of its own state and restore its state from snapshots when needed. |
| Memento | A value object that acts as a snapshot of the originator's state. It is common practice to make the memento immutable and pass data to it only once, via the constructor. |
| Caretaker | Knows not only "when" and "why" to capture the originator's state, but also when the state should be restored. Stores a stack of mementos. When the originator has to go back in time, the caretaker fetches the topmost memento and passes it to the originator's restore method. |

## Conceptual Example

```swift
import XCTest

/// The Originator holds some important state that may change over time. It also
/// defines a method for saving the state inside a memento and another method
/// for restoring the state from it.
class Originator {

    /// For the sake of simplicity, the originator's state is stored inside a
    /// single variable.
    private var state: String

    init(state: String) {
        self.state = state
        print("Originator: My initial state is: \(state)")
    }

    /// The Originator's business logic may affect its internal state.
    /// Therefore, the client should backup the state before launching methods
    /// of the business logic via the save() method.
    func doSomething() {
        print("Originator: I'm doing something important.")
        state = generateRandomString()
        print("Originator: and my state has changed to: \(state)")
    }

    private func generateRandomString() -> String {
        return String(UUID().uuidString.suffix(4))
    }

    /// Saves the current state inside a memento.
    func save() -> Memento {
        return ConcreteMemento(state: state)
    }

    /// Restores the Originator's state from a memento object.
    func restore(memento: Memento) {
        guard let memento = memento as? ConcreteMemento else { return }
        self.state = memento.state
        print("Originator: My state has changed to: \(state)")
    }
}

/// The Memento interface provides a way to retrieve the memento's metadata,
/// such as creation date or name. However, it doesn't expose the Originator's
/// state.
protocol Memento {

    var name: String { get }
    var date: Date { get }
}

/// The Concrete Memento contains the infrastructure for storing the
/// Originator's state.
class ConcreteMemento: Memento {

    /// The Originator uses this method when restoring its state.
    private(set) var state: String
    private(set) var date: Date

    init(state: String) {
        self.state = state
        self.date = Date()
    }

    /// The rest of the methods are used by the Caretaker to display metadata.
    var name: String { return state + " " + date.description.suffix(14).prefix(8) }
}

/// The Caretaker doesn't depend on the Concrete Memento class. Therefore, it
/// doesn't have access to the originator's state, stored inside the memento. It
/// works with all mementos via the base Memento interface.
class Caretaker {

    private lazy var mementos = [Memento]()
    private var originator: Originator

    init(originator: Originator) {
        self.originator = originator
    }

    func backup() {
        print("\nCaretaker: Saving Originator's state...\n")
        mementos.append(originator.save())
    }

    func undo() {

        guard !mementos.isEmpty else { return }
        let removedMemento = mementos.removeLast()

        print("Caretaker: Restoring state to: " + removedMemento.name)
        originator.restore(memento: removedMemento)
    }

    func showHistory() {
        print("Caretaker: Here's the list of mementos:\n")
        mementos.forEach({ print($0.name) })
    }
}

/// Let's see how it all works together.
class MementoConceptual: XCTestCase {

    func testMementoConceptual() {

        let originator = Originator(state: "Super-duper-super-puper-super.")
        let caretaker = Caretaker(originator: originator)

        caretaker.backup()
        originator.doSomething()

        caretaker.backup()
        originator.doSomething()

        caretaker.backup()
        originator.doSomething()

        print("\n")
        caretaker.showHistory()

        print("\nClient: Now, let's rollback!\n\n")
        caretaker.undo()

        print("\nClient: Once more!\n\n")
        caretaker.undo()
    }
}
```

**Output:**
```
Originator: My initial state is: Super-duper-super-puper-super.

Caretaker: Saving Originator's state...

Originator: I'm doing something important.
Originator: and my state has changed to: 1923

Caretaker: Saving Originator's state...

Originator: I'm doing something important.
Originator: and my state has changed to: 74FB

Caretaker: Saving Originator's state...

Originator: I'm doing something important.
Originator: and my state has changed to: 3681


Caretaker: Here's the list of mementos:

Super-duper-super-puper-super. 11:45:44
1923 11:45:44
74FB 11:45:44

Client: Now, let's rollback!

Caretaker: Restoring state to: 74FB 11:45:44
Originator: My state has changed to: 74FB

Client: Once more!

Caretaker: Restoring state to: 1923 11:45:44
Originator: My state has changed to: 1923
```

## Real-World Example

```swift
import XCTest

class MementoRealWorld: XCTestCase {

    /// State and Command are often used together when the previous state of the
    /// object should be restored in case of failure of some operation.
    ///
    /// Note: UndoManager can be used as an alternative.

    func test() {

        let textView = UITextView()
        let undoStack = UndoStack(textView)

        textView.text = "First Change"
        undoStack.save()

        textView.text = "Second Change"
        undoStack.save()

        textView.text = (textView.text ?? "") + " & Third Change"
        textView.textColor = .red
        undoStack.save()

        print(undoStack)

        print("Client: Perform Undo operation 2 times\n")
        undoStack.undo()
        undoStack.undo()

        print(undoStack)
    }
}

class UndoStack: CustomStringConvertible {

    private lazy var mementos = [Memento]()
    private let textView: UITextView

    init(_ textView: UITextView) {
        self.textView = textView
    }

    func save() {
        mementos.append(textView.memento)
    }

    func undo() {
        guard !mementos.isEmpty else { return }
        textView.restore(with: mementos.removeLast())
    }

    var description: String {
        return mementos.reduce("", { $0 + $1.description })
    }
}

protocol Memento: CustomStringConvertible {

    var text: String { get }
    var date: Date { get }
}

extension UITextView {

    var memento: Memento {
        return TextViewMemento(text: text,
                               textColor: textColor,
                               selectedRange: selectedRange)
    }

    func restore(with memento: Memento) {
        guard let textViewMemento = memento as? TextViewMemento else { return }

        text = textViewMemento.text
        textColor = textViewMemento.textColor
        selectedRange = textViewMemento.selectedRange
    }

    struct TextViewMemento: Memento {

        let text: String
        let date = Date()

        let textColor: UIColor?
        let selectedRange: NSRange

        var description: String {
            let time = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond],
                                                       from: date)
            let color = String(describing: textColor)
            return "Text: \(text)\n" + "Date: \(time.description)\n"
                + "Color: \(color)\n" + "Range: \(selectedRange)\n\n"
        }
    }
}
```

**Output:**
```
Text: First Change
Date: hour: 12 minute: 21 second: 50 nanosecond: 821737051 isLeapMonth: false
Color: nil
Range: {12, 0}

Text: Second Change
Date: hour: 12 minute: 21 second: 50 nanosecond: 826483011 isLeapMonth: false
Color: nil
Range: {13, 0}

Text: Second Change & Third Change
Date: hour: 12 minute: 21 second: 50 nanosecond: 829187035 isLeapMonth: false
Color: Optional(UIExtendedSRGBColorSpace 1 0 0 1)
Range: {28, 0}


Client: Perform Undo operation 2 times

Text: First Change
Date: hour: 12 minute: 21 second: 50 nanosecond: 821737051 isLeapMonth: false
Color: nil
Range: {12, 0}
```

## iOS Framework Usage

- **UIKit**: `UndoManager` (accessible via `UIResponder.undoManager`) is Apple's built-in Memento + Command hybrid. It manages undo/redo stacks for text editing, drawing operations, and Core Data changes. `NSCoder` and `NSKeyedArchiver` serialize object state into memento-like archives.
- **SwiftUI**: `@SceneStorage` saves and restores view state across scene sessions, acting as an automatic memento. `NavigationPath` with `Codable` support allows saving and restoring the entire navigation stack. `@AppStorage` persists individual values as lightweight mementos.
- **Foundation/Combine**: `Codable` protocol enables any conforming type to serialize its state into a memento (JSON, plist, binary). `UserDefaults` acts as a persistent caretaker. Core Data's `NSManagedObjectContext` supports `rollback()` and `undo()`, which are Memento pattern implementations at the persistence layer.

## Swift-Specific Notes

- Use Swift structs for memento objects to get immutability by default -- all `let` properties cannot be changed after initialization, which is exactly the semantics a memento needs.
- Leverage `private(set)` access control (as shown in `ConcreteMemento`) to allow the originator to read the memento's state while preventing the caretaker from modifying it, enforcing encapsulation at the language level.
- Swift's `Codable` protocol is a natural serialization mechanism for mementos. Conforming to `Codable` lets you persist mementos to disk (JSON, plist) or transmit them over the network for remote state recovery.
- Nest the memento type inside the originator or use `fileprivate` to restrict access, leveraging Swift's access control to ensure only the originator can create and read concrete memento contents.
- Combine the Memento pattern with Swift's value-type semantics: since structs are copied on assignment, simply storing a struct-based model in an array creates implicit snapshots without explicit memento classes.

## Related Patterns

- **Command**: Can be used together with Memento for implementing undo. Commands perform operations, while mementos save the state just before a command executes, enabling rollback on failure.
- **Iterator**: Can be used alongside Memento to capture the current iteration state and restore it later for resumable traversals.
- **Prototype**: Can serve as a simpler alternative to Memento if the state you need to store in history is simple. Cloning the originator is sometimes easier than managing separate memento objects.
