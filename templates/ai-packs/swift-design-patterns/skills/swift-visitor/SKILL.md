---
name: swift-visitor
description: >
  Swift Visitor design pattern — Behavioral. Use when you need to add operations to object
  structures without modifying them, implement double dispatch, or separate algorithms from
  the objects they operate on. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Visitor — Swift

> **Category**: Behavioral
> **Intent**: Visitor is a behavioral design pattern that lets you separate algorithms from the objects on which they operate. It lets you define new operations without changing the classes of the elements on which it operates.

## When to Use

Use the Visitor pattern when you need to perform an operation on all elements of a complex object structure (like a tree or collection of heterogeneous objects) and you don't want to pollute element classes with these operations. The pattern suggests placing the new behavior in a separate class called a visitor, instead of integrating it into existing classes.

This pattern is particularly valuable when an object structure contains many classes with differing interfaces, and you want to perform operations that depend on their concrete types. It is also useful when operations need to change frequently while the class hierarchy remains stable — adding a new visitor is easier than modifying every element class.

Visitor relies on a technique called "double dispatch" — the element accepts a visitor and calls the visitor's method that corresponds to the element's class. This lets you execute different code depending on both the element and visitor types without complex conditionals.

## Structure

| Participant | Role |
|-------------|------|
| Visitor (Protocol) | Declares a visit method for each concrete element class. |
| ConcreteVisitor | Implements each visit method with behavior specific to that element type. |
| Element (Protocol) | Declares an `accept` method that takes a visitor. |
| ConcreteElement | Implements `accept` by calling the visitor method corresponding to its own class. |

## Conceptual Example

```swift
import XCTest

protocol Component {
    func accept(_ visitor: Visitor)
}

class ConcreteComponentA: Component {
    func accept(_ visitor: Visitor) {
        visitor.visitConcreteComponentA(element: self)
    }

    func exclusiveMethodOfConcreteComponentA() -> String {
        return "A"
    }
}

class ConcreteComponentB: Component {
    func accept(_ visitor: Visitor) {
        visitor.visitConcreteComponentB(element: self)
    }

    func specialMethodOfConcreteComponentB() -> String {
        return "B"
    }
}

protocol Visitor {
    func visitConcreteComponentA(element: ConcreteComponentA)
    func visitConcreteComponentB(element: ConcreteComponentB)
}

class ConcreteVisitor1: Visitor {
    func visitConcreteComponentA(element: ConcreteComponentA) {
        print(element.exclusiveMethodOfConcreteComponentA() + " + ConcreteVisitor1\n")
    }

    func visitConcreteComponentB(element: ConcreteComponentB) {
        print(element.specialMethodOfConcreteComponentB() + " + ConcreteVisitor1\n")
    }
}

class ConcreteVisitor2: Visitor {
    func visitConcreteComponentA(element: ConcreteComponentA) {
        print(element.exclusiveMethodOfConcreteComponentA() + " + ConcreteVisitor2\n")
    }

    func visitConcreteComponentB(element: ConcreteComponentB) {
        print(element.specialMethodOfConcreteComponentB() + " + ConcreteVisitor2\n")
    }
}

class Client {
    static func clientCode(components: [Component], visitor: Visitor) {
        components.forEach({ $0.accept(visitor) })
    }
}

class VisitorConceptual: XCTestCase {
    func test() {
        let components: [Component] = [ConcreteComponentA(), ConcreteComponentB()]

        print("The client code works with all visitors via the base Visitor interface:\n")
        let visitor1 = ConcreteVisitor1()
        Client.clientCode(components: components, visitor: visitor1)

        print("\nIt allows the same client code to work with different types of visitors:\n")
        let visitor2 = ConcreteVisitor2()
        Client.clientCode(components: components, visitor: visitor2)
    }
}
```

**Output:**
```
The client code works with all visitors via the base Visitor interface:
A + ConcreteVisitor1
B + ConcreteVisitor1

It allows the same client code to work with different types of visitors:
A + ConcreteVisitor2
B + ConcreteVisitor2
```

## Real-World Example

```swift
import Foundation
import XCTest

protocol Notification: CustomStringConvertible {
    func accept(visitor: NotificationPolicy) -> Bool
}

struct Email: Notification {
    let emailOfSender: String
    var description: String { return "Email" }

    func accept(visitor: NotificationPolicy) -> Bool {
        return visitor.isTurnedOn(for: self)
    }
}

struct SMS: Notification {
    let phoneNumberOfSender: String
    var description: String { return "SMS" }

    func accept(visitor: NotificationPolicy) -> Bool {
        return visitor.isTurnedOn(for: self)
    }
}

struct Push: Notification {
    let usernameOfSender: String
    var description: String { return "Push" }

    func accept(visitor: NotificationPolicy) -> Bool {
        return visitor.isTurnedOn(for: self)
    }
}

protocol NotificationPolicy: CustomStringConvertible {
    func isTurnedOn(for email: Email) -> Bool
    func isTurnedOn(for sms: SMS) -> Bool
    func isTurnedOn(for push: Push) -> Bool
}

class NightPolicyVisitor: NotificationPolicy {
    func isTurnedOn(for email: Email) -> Bool { return false }
    func isTurnedOn(for sms: SMS) -> Bool { return true }
    func isTurnedOn(for push: Push) -> Bool { return false }
    var description: String { return "Night Policy Visitor" }
}

class DefaultPolicyVisitor: NotificationPolicy {
    func isTurnedOn(for email: Email) -> Bool { return true }
    func isTurnedOn(for sms: SMS) -> Bool { return true }
    func isTurnedOn(for push: Push) -> Bool { return true }
    var description: String { return "Default Policy Visitor" }
}

class BlackListVisitor: NotificationPolicy {
    private var bannedEmails = [String]()
    private var bannedPhones = [String]()
    private var bannedUsernames = [String]()

    init(emails: [String], phones: [String], usernames: [String]) {
        self.bannedEmails = emails
        self.bannedPhones = phones
        self.bannedUsernames = usernames
    }

    func isTurnedOn(for email: Email) -> Bool {
        return bannedEmails.contains(email.emailOfSender)
    }

    func isTurnedOn(for sms: SMS) -> Bool {
        return bannedPhones.contains(sms.phoneNumberOfSender)
    }

    func isTurnedOn(for push: Push) -> Bool {
        return bannedUsernames.contains(push.usernameOfSender)
    }

    var description: String { return "Black List Visitor" }
}

class VisitorRealWorld: XCTestCase {
    func testVisitorRealWorld() {
        let email = Email(emailOfSender: "some@email.com")
        let sms = SMS(phoneNumberOfSender: "+3806700000")
        let push = Push(usernameOfSender: "Spammer")

        let notifications: [Notification] = [email, sms, push]

        clientCode(handle: notifications, with: DefaultPolicyVisitor())
        clientCode(handle: notifications, with: NightPolicyVisitor())
    }

    func clientCode(handle notifications: [Notification], with policy: NotificationPolicy) {
        let blackList = BlackListVisitor(
            emails: ["banned@email.com"],
            phones: ["000000000", "1234325232"],
            usernames: ["Spammer"]
        )

        print("\nClient: Using \(policy.description) and \(blackList.description)")

        notifications.forEach { item in
            guard !item.accept(visitor: blackList) else {
                print("\tWARNING: " + item.description + " is in a black list")
                return
            }

            if item.accept(visitor: policy) {
                print("\t" + item.description + " notification will be shown")
            } else {
                print("\t" + item.description + " notification will be silenced")
            }
        }
    }
}
```

**Output:**
```
Client: Using Default Policy Visitor and Black List Visitor
    Email notification will be shown
    SMS notification will be shown
    WARNING: Push is in a black list

Client: Using Night Policy Visitor and Black List Visitor
    Email notification will be silenced
    SMS notification will be shown
    WARNING: Push is in a black list
```

## iOS Framework Usage

- **UIKit**: The responder chain uses a form of double dispatch. `UIAccessibility` uses visitor-like inspection to traverse view hierarchies.
- **SwiftUI**: `ViewModifier` acts like a visitor — it visits views and applies transformations without modifying the view types themselves. `PreferenceKey` collects data by visiting the view tree.
- **Foundation**: `NSCoder` / `Codable` use visitor-like patterns — `encode(to encoder: Encoder)` accepts an encoder (visitor) that extracts data from each element.

## Swift-Specific Notes

- **Protocol-based visitors**: Define `Visitor` as a protocol. Each `visit` method takes a specific concrete element type, enabling type-safe double dispatch.
- **Enum alternative**: For a closed set of element types, Swift enums with `switch` statements can replace the Visitor pattern entirely — the compiler enforces exhaustiveness.
- **Protocol extensions**: Can provide default visitor implementations for common cases, with concrete visitors overriding only specific methods.
- **Generics limitation**: Swift's type system doesn't support generic method dispatch on the element's concrete type, so the double-dispatch mechanism (accept/visit) is still necessary for heterogeneous collections.
- **Value types**: Swift structs work well as elements since visitors typically read (not mutate) element data. Use `mutating` if the visitor needs to modify elements.

## Related Patterns

- **Composite**: Visitor can be used to execute an operation over an entire Composite tree. The visitor visits each node in the composite structure.
- **Iterator**: You can use Visitor together with Iterator to traverse complex data structures and execute operations on elements, even when they are of different types.
- **Strategy**: Visitor is similar to Strategy, but operates across a structure of objects rather than being injected into a single context.
