---
name: swift-mediator
description: >
  Swift Mediator design pattern -- Behavioral. Use when reducing chaotic dependencies between objects,
  coordinating multiple UI components, or centralizing communication between view controllers.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Mediator -- Swift

> **Category**: Behavioral
> **Intent**: Let you reduce chaotic dependencies between objects. The pattern restricts direct communications between the objects and forces them to collaborate only via a mediator object.

## When to Use

The Mediator pattern is appropriate when it is hard to change some of the classes because they are tightly coupled to many other classes. The pattern lets you extract all the relationships between classes into a separate class, isolating any changes to a specific component from the rest of the components.

Use Mediator when you find yourself creating tons of component subclasses just to reuse some basic behavior in various contexts. Since all relations between components are contained within the mediator, it is easy to define entirely new ways for these components to collaborate by introducing new mediator classes without having to change the components themselves.

In iOS development, the Mediator pattern is invaluable for coordinating multiple view controllers or UI components that need to communicate without knowing about each other. Common use cases include multi-screen flows (login, onboarding), dashboard screens where multiple widgets update based on shared state changes, and notification systems where likes/comments propagate across feed, detail, and profile screens.

## Structure

| Participant | Role |
|-------------|------|
| Mediator (Protocol) | Declares the communication interface, typically a single notification method that components use to inform the mediator about events. |
| Concrete Mediator | Encapsulates relations between various components. Keeps references to all managed components and coordinates their interaction. |
| Base Component | Provides basic functionality of storing a reference to the mediator. Components communicate through the mediator rather than directly. |
| Concrete Components | Implement specific functionality. Each component only knows about the mediator, not about other components. |

## Conceptual Example

```swift
import XCTest

/// The Mediator interface declares a method used by components to notify the
/// mediator about various events. The Mediator may react to these events and
/// pass the execution to other components.
protocol Mediator: AnyObject {

    func notify(sender: BaseComponent, event: String)
}

/// Concrete Mediators implement cooperative behavior by coordinating several
/// components.
class ConcreteMediator: Mediator {

    private var component1: Component1
    private var component2: Component2

    init(_ component1: Component1, _ component2: Component2) {
        self.component1 = component1
        self.component2 = component2

        component1.update(mediator: self)
        component2.update(mediator: self)
    }

    func notify(sender: BaseComponent, event: String) {
        if event == "A" {
            print("Mediator reacts on A and triggers following operations:")
            self.component2.doC()
        }
        else if (event == "D") {
            print("Mediator reacts on D and triggers following operations:")
            self.component1.doB()
            self.component2.doC()
        }
    }
}

/// The Base Component provides the basic functionality of storing a mediator's
/// instance inside component objects.
class BaseComponent {

    fileprivate weak var mediator: Mediator?

    init(mediator: Mediator? = nil) {
        self.mediator = mediator
    }

    func update(mediator: Mediator) {
        self.mediator = mediator
    }
}

/// Concrete Components implement various functionality. They don't depend on
/// other components. They also don't depend on any concrete mediator classes.
class Component1: BaseComponent {

    func doA() {
        print("Component 1 does A.")
        mediator?.notify(sender: self, event: "A")
    }

    func doB() {
        print("Component 1 does B.\n")
        mediator?.notify(sender: self, event: "B")
    }
}

class Component2: BaseComponent {

    func doC() {
        print("Component 2 does C.")
        mediator?.notify(sender: self, event: "C")
    }

    func doD() {
        print("Component 2 does D.")
        mediator?.notify(sender: self, event: "D")
    }
}

/// Let's see how it all works together.
class MediatorConceptual: XCTestCase {

    func testMediatorConceptual() {

        let component1 = Component1()
        let component2 = Component2()

        let mediator = ConcreteMediator(component1, component2)
        print("Client triggers operation A.")
        component1.doA()

        print("\nClient triggers operation D.")
        component2.doD()

        print(mediator)
    }
}
```

**Output:**
```
Client triggers operation A.
Component 1 does A.
Mediator reacts on A and triggers following operations:
Component 2 does C.

Client triggers operation D.
Component 2 does D.
Mediator reacts on D and triggers following operations:
Component 1 does B.

Component 2 does C.
```

## Real-World Example

```swift
import XCTest

class MediatorRealWorld: XCTestCase {

    func test() {

        let newsArray = [News(id: 1, title: "News1", likesCount: 1),
                         News(id: 2, title: "News2", likesCount: 2)]

        let numberOfGivenLikes = newsArray.reduce(0, { $0 + $1.likesCount })

        let mediator = ScreenMediator()

        let feedVC = NewsFeedViewController(mediator, newsArray)
        let newsDetailVC = NewsDetailViewController(mediator, newsArray.first!)
        let profileVC = ProfileViewController(mediator, numberOfGivenLikes)

        mediator.update([feedVC, newsDetailVC, profileVC])

        feedVC.userLikedAllNews()
        feedVC.userDislikedAllNews()
    }
}

class NewsFeedViewController: ScreenUpdatable {

    private var newsArray: [News]
    private weak var mediator: ScreenUpdatable?

    init(_ mediator: ScreenUpdatable?, _ newsArray: [News]) {
        self.newsArray = newsArray
        self.mediator = mediator
    }

    func likeAdded(to news: News) {

        print("News Feed: Received a liked news model with id \(news.id)")

        for var item in newsArray {
            if item == news {
                item.likesCount += 1
            }
        }
    }

    func likeRemoved(from news: News) {

        print("News Feed: Received a disliked news model with id \(news.id)")

        for var item in newsArray {
            if item == news {
                item.likesCount -= 1
            }
        }
    }

    func userLikedAllNews() {
        print("\n\nNews Feed: User LIKED all news models")
        print("News Feed: I am telling to mediator about it...\n")
        newsArray.forEach({ mediator?.likeAdded(to: $0) })
    }

    func userDislikedAllNews() {
        print("\n\nNews Feed: User DISLIKED all news models")
        print("News Feed: I am telling to mediator about it...\n")
        newsArray.forEach({ mediator?.likeRemoved(from: $0) })
    }
}

class NewsDetailViewController: ScreenUpdatable {

    private var news: News
    private weak var mediator: ScreenUpdatable?

    init(_ mediator: ScreenUpdatable?, _ news: News) {
        self.news = news
        self.mediator = mediator
    }

    func likeAdded(to news: News) {
        print("News Detail: Received a liked news model with id \(news.id)")
        if self.news == news {
            self.news.likesCount += 1
        }
    }

    func likeRemoved(from news: News) {
        print("News Detail: Received a disliked news model with id \(news.id)")
        if self.news == news {
            self.news.likesCount -= 1
        }
    }
}

class ProfileViewController: ScreenUpdatable {

    private var numberOfGivenLikes: Int
    private weak var mediator: ScreenUpdatable?

    init(_ mediator: ScreenUpdatable?, _ numberOfGivenLikes: Int) {
        self.numberOfGivenLikes = numberOfGivenLikes
        self.mediator = mediator
    }

    func likeAdded(to news: News) {
        print("Profile: Received a liked news model with id \(news.id)")
        numberOfGivenLikes += 1
    }

    func likeRemoved(from news: News) {
        print("Profile: Received a disliked news model with id \(news.id)")
        numberOfGivenLikes -= 1
    }
}

protocol ScreenUpdatable: AnyObject {

    func likeAdded(to news: News)

    func likeRemoved(from news: News)
}

class ScreenMediator: ScreenUpdatable {

    private var screens: [ScreenUpdatable]?

    func update(_ screens: [ScreenUpdatable]) {
        self.screens = screens
    }

    func likeAdded(to news: News) {
        print("Screen Mediator: Received a liked news model with id \(news.id)")
        screens?.forEach({ $0.likeAdded(to: news) })
    }

    func likeRemoved(from news: News) {
        print("ScreenMediator: Received a disliked news model with id \(news.id)")
        screens?.forEach({ $0.likeRemoved(from: news) })
    }
}

struct News: Equatable {

    let id: Int

    let title: String

    var likesCount: Int

    static func == (left: News, right: News) -> Bool {
        return left.id == right.id
    }
}
```

**Output:**
```
News Feed: User LIKED all news models
News Feed: I am telling to mediator about it...

Screen Mediator: Received a liked news model with id 1
News Feed: Received a liked news model with id 1
News Detail: Received a liked news model with id 1
Profile: Received a liked news model with id 1
Screen Mediator: Received a liked news model with id 2
News Feed: Received a liked news model with id 2
News Detail: Received a liked news model with id 2
Profile: Received a liked news model with id 2


News Feed: User DISLIKED all news models
News Feed: I am telling to mediator about it...

ScreenMediator: Received a disliked news model with id 1
News Feed: Received a disliked news model with id 1
News Detail: Received a disliked news model with id 1
Profile: Received a disliked news model with id 1
ScreenMediator: Received a disliked news model with id 2
News Feed: Received a disliked news model with id 2
News Detail: Received a disliked news model with id 2
Profile: Received a disliked news model with id 2
```

## iOS Framework Usage

- **UIKit**: `UINavigationController` and `UITabBarController` act as mediators between their child view controllers, managing transitions and communication. The Coordinator pattern (widely used in iOS) is a specialized mediator that manages navigation flow between view controllers.
- **SwiftUI**: `@EnvironmentObject` and `ObservableObject` serve as implicit mediators. A shared `ViewModel` published via `@EnvironmentObject` lets multiple views react to state changes without direct references to each other. The `onChange(of:)` modifier enables views to respond to changes mediated through shared state.
- **Foundation/Combine**: `NotificationCenter` is the quintessential mediator in Apple's frameworks -- components post notifications without knowing who observes them. Combine's `Subject` (particularly `PassthroughSubject` and `CurrentValueSubject`) acts as a typed mediator that multiple subscribers can observe.

## Swift-Specific Notes

- Use `weak` references from components to the mediator (as shown with `fileprivate weak var mediator`) to prevent retain cycles, since the mediator holds strong references to all components.
- Swift protocols with `AnyObject` constraint (`: AnyObject` or the legacy `: class`) ensure the mediator protocol can only be adopted by reference types, enabling `weak` storage.
- Consider using Combine's `PassthroughSubject` as a modern mediator implementation -- components send values to the subject, and other components subscribe to it, replacing the manual notification dispatch.
- In SwiftUI, the mediator role is often absorbed by a shared `@Observable` (Swift 5.9+) or `ObservableObject` class that multiple views observe, making the pattern implicit rather than explicit.
- Use Swift enums for event types instead of raw strings (`event: String`), which provides compile-time safety and exhaustive switch handling in the mediator's dispatch logic.

## Related Patterns

- **Facade**: Both organize collaboration between many tightly coupled classes, but Facade defines a simplified interface without adding new functionality, while Mediator centralizes communication between components.
- **Observer**: The boundary between Mediator and Observer is often blurry. Mediator can be implemented using Observer -- the mediator plays the publisher role and components act as subscribers.
- **Chain of Responsibility**: Passes a request sequentially along a chain, while Mediator eliminates direct connections between senders and receivers, forcing them to communicate indirectly through the mediator.
