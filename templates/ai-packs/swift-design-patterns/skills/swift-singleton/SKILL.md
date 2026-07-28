---
name: swift-singleton
description: >
  Swift Singleton design pattern — Creational. Use when you need exactly one instance of a class,
  a global access point to a shared resource, or stricter control over global variables.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Creational
  source: refactoring.guru
---

# Singleton — Swift

> **Category**: Creational
> **Intent**: Ensure that a class has only one instance, while providing a global access point to this instance.

## When to Use

Use the Singleton pattern when a class in your program should have just a single instance available to all clients. This is common for shared resources such as a database connection pool, a file manager, a logging service, or a configuration store. The Singleton pattern disables all other means of creating objects of the class except the special static creation method, which either creates a new object or returns the existing one if it has already been created.

The pattern is also appropriate when you need stricter control over global variables. Unlike global variables, the Singleton pattern guarantees that there is only one instance of the class. Nothing except the Singleton class itself can replace the cached instance. This is important when you want to ensure consistency across the application, for example a single source of truth for user session data or an analytics tracker that must not be duplicated.

However, be cautious with Singleton. It has almost the same pros and cons as global variables: while super-handy, it can break the modularity of your code. The Singleton class becomes tightly coupled to all of its consumers, making unit testing harder. In modern Swift, consider whether dependency injection with a shared instance (passed explicitly rather than accessed globally) might be a better fit. If you still need the pattern, Swift's `static let` provides thread-safe lazy initialization out of the box.

## Structure

| Participant | Role |
|-------------|------|
| Singleton | Declares a static method/property (`shared`) that returns the same instance of the class. Makes the initializer private to prevent external instantiation. |
| Client | Accesses the Singleton exclusively through the static `shared` property. Never calls the initializer directly. |

## Conceptual Example

```swift
import XCTest

/// The Singleton class defines the `shared` field that lets clients access the
/// unique singleton instance.
class Singleton {

    /// The static field that controls the access to the singleton instance.
    ///
    /// This implementation let you extend the Singleton class while keeping
    /// just one instance of each subclass around.
    static var shared: Singleton = {
        let instance = Singleton()
        // ... configure the instance
        // ...
        return instance
    }()

    /// The Singleton's initializer should always be private to prevent direct
    /// construction calls with the `new` operator.
    private init() {}

    /// Finally, any singleton should define some business logic, which can be
    /// executed on its instance.
    func someBusinessLogic() -> String {
        // ...
        return "Result of the 'someBusinessLogic' call"
    }
}

/// Singletons should not be cloneable.
extension Singleton: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

/// The client code.
class Client {
    // ...
    static func someClientCode() {
        let instance1 = Singleton.shared
        let instance2 = Singleton.shared

        if (instance1 === instance2) {
            print("Singleton works, both variables contain the same instance.")
        } else {
            print("Singleton failed, variables contain different instances.")
        }
    }
    // ...
}

/// Let's see how it all works together.
class SingletonConceptual: XCTestCase {

    func testSingletonConceptual() {
        Client.someClientCode()
    }
}
```

**Output:**

```
Singleton works, both variables contain the same instance.
```

## Real-World Example

```swift
import XCTest

/// Singleton Design Pattern
///
/// Intent: Ensure that class has a single instance, and provide a global point
/// of access to it.

class SingletonRealWorld: XCTestCase {

    func testSingletonRealWorld() {

        /// There are two view controllers.
        ///
        /// MessagesListVC displays a list of last messages from a user's chats.
        /// ChatVC displays a chat with a friend.
        ///
        /// FriendsChatService fetches messages from a server and provides all
        /// subscribers (view controllers in our example) with new and removed
        /// messages.
        ///
        /// FriendsChatService is used by both view controllers. It can be
        /// implemented as an instance of a class as well as a global variable.
        ///
        /// In this example, it is important to have only one instance that
        /// performs resource-intensive work.

        let listVC = MessagesListVC()
        let chatVC = ChatVC()

        listVC.startReceiveMessages()
        chatVC.startReceiveMessages()

        /// ... add view controllers to the navigation stack ...
    }
}


class BaseVC: UIViewController, MessageSubscriber {

    func accept(new messages: [Message]) {
        /// Handles new messages in the base class
    }

    func accept(removed messages: [Message]) {
        /// Handles removed messages in the base class
    }

    func startReceiveMessages() {

        /// The singleton can be injected as a dependency. However, from an
        /// informational perspective, this example calls FriendsChatService
        /// directly to illustrate the intent of the pattern, which is: "...to
        /// provide the global point of access to the instance..."

        FriendsChatService.shared.add(subscriber: self)
    }
}

class MessagesListVC: BaseVC {

    override func accept(new messages: [Message]) {
        print("MessagesListVC accepted 'new messages'")
        /// Handles new messages in the child class
    }

    override func accept(removed messages: [Message]) {
        print("MessagesListVC accepted 'removed messages'")
        /// Handles removed messages in the child class
    }

    override func startReceiveMessages() {
        print("MessagesListVC starts receive messages")
        super.startReceiveMessages()
    }
}

class ChatVC: BaseVC {

    override func accept(new messages: [Message]) {
        print("ChatVC accepted 'new messages'")
        /// Handles new messages in the child class
    }

    override func accept(removed messages: [Message]) {
        print("ChatVC accepted 'removed messages'")
        /// Handles removed messages in the child class
    }

    override func startReceiveMessages() {
        print("ChatVC starts receive messages")
        super.startReceiveMessages()
    }
}

/// Protocol for call-back events

protocol MessageSubscriber {

    func accept(new messages: [Message])
    func accept(removed messages: [Message])
}

/// Protocol for communication with a message service

protocol MessageService {

    func add(subscriber: MessageSubscriber)
}

/// Message domain model

struct Message {

    let id: Int
    let text: String
}


class FriendsChatService: MessageService {

    static let shared = FriendsChatService()

    private var subscribers = [MessageSubscriber]()

    func add(subscriber: MessageSubscriber) {

        /// In this example, fetching starts again by adding a new subscriber
        subscribers.append(subscriber)

        /// Please note, the first subscriber will receive messages again when
        /// the second subscriber is added
        startFetching()
    }

    func startFetching() {

        /// Set up the network stack, establish a connection...
        /// ...and retrieve data from a server

        let newMessages = [Message(id: 0, text: "Text0"),
                           Message(id: 5, text: "Text5"),
                           Message(id: 10, text: "Text10")]

        let removedMessages = [Message(id: 1, text: "Text0")]

        /// Send updated data to subscribers
        receivedNew(messages: newMessages)
        receivedRemoved(messages: removedMessages)
    }
}

private extension FriendsChatService {

    func receivedNew(messages: [Message]) {

        subscribers.forEach { item in
            item.accept(new: messages)
        }
    }

    func receivedRemoved(messages: [Message]) {

        subscribers.forEach { item in
            item.accept(removed: messages)
        }
    }
}
```

**Output:**

```
MessagesListVC starts receive messages
MessagesListVC accepted 'new messages'
MessagesListVC accepted 'removed messages'
ChatVC starts receive messages
MessagesListVC accepted 'new messages'
ChatVC accepted 'new messages'
MessagesListVC accepted 'removed messages'
ChatVC accepted 'removed messages'
```

## iOS Framework Usage

- **UIKit**: `UIApplication.shared` is the canonical Singleton in iOS development. Other examples include `UIScreen.main`, `UIDevice.current`, and `UIMenuController.shared`. The `NotificationCenter.default` and `UserDefaults.standard` are also Singletons used throughout UIKit apps.
- **SwiftUI**: SwiftUI favors the `@EnvironmentObject` and `@Environment` property wrappers for shared state, which act as a form of dependency injection. However, Singletons still appear as `@Observable` classes accessed via environment. `ModelContainer` in SwiftData is often configured once and shared app-wide.
- **Foundation**: `FileManager.default`, `URLSession.shared`, `ProcessInfo.processInfo`, `NotificationCenter.default`, and `OperationQueue.main` are all Foundation Singletons. `JSONDecoder` and `JSONEncoder` are not Singletons but are often used as shared instances for performance.

## Swift-Specific Notes

- Swift's `static let` provides thread-safe lazy initialization automatically via Grand Central Dispatch (`dispatch_once` under the hood). You do not need manual locking or double-checked locking in Swift.
- Use `private init()` to prevent external instantiation. Mark the class `final` to prevent subclassing if that is not intended.
- For testability, prefer injecting the singleton instance via protocol-based dependency injection rather than accessing `.shared` directly. Define a protocol for the service and make the Singleton conform to it.
- In Swift concurrency, if the Singleton holds mutable state, consider making it an `actor` instead of a `class` to get compile-time data race safety. Alternatively, mark it `@MainActor` if it interacts with UI.
- With `@Observable` (iOS 17+), a Singleton can be observed by SwiftUI views via `@Environment`, reducing the need for Combine publishers or manual notification dispatch.
- Memory management: Singletons live for the entire lifetime of the application. Be careful with strong reference cycles in subscribers or delegates held by the Singleton. Use `[weak self]` or weak delegate references.

## Related Patterns

- **Abstract Factory**: Concrete factory classes are often implemented as Singletons because a single factory object is usually sufficient.
- **Facade**: A Facade object can often be turned into a Singleton since a single facade is typically enough.
- **Prototype**: Prototype registries can be implemented as Singletons for centralized access to pre-configured prototype instances.
