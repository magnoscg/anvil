---
name: swift-chain-of-responsibility
description: >
  Swift Chain of Responsibility design pattern -- Behavioral. Use when processing requests through
  a pipeline of handlers, implementing validation chains, or building middleware stacks.
  Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Behavioral
  source: refactoring.guru
---

# Chain of Responsibility -- Swift

> **Category**: Behavioral
> **Intent**: Let you pass requests along a chain of handlers. Upon receiving a request, each handler decides either to process the request or to pass it to the next handler in the chain.

## When to Use

The Chain of Responsibility pattern is appropriate when your program needs to process different kinds of requests in various ways, but the exact types of requests and their sequences are unknown beforehand. The pattern lets you link several handlers into one chain and, upon receiving a request, ask each handler whether it can process it.

Use Chain of Responsibility when the set of handlers and their order may change at runtime. You can insert, remove, or reorder handlers dynamically using setters for reference fields inside handler classes. This is ideal in iOS for form validation chains, authentication/authorization pipelines, and event handling hierarchies.

In Swift, this pattern is especially clean when implemented with protocols and default implementations via protocol extensions. The base handler behavior (forwarding to the next handler) lives in the extension, while concrete handlers only override the parts they care about. This is also a natural fit for middleware patterns in networking layers where each handler can transform, validate, or reject a request before passing it along.

## Structure

| Participant | Role |
|-------------|------|
| Handler (Protocol) | Declares the interface common to all concrete handlers. Usually contains a single method for handling requests, and optionally a method for setting the next handler in the chain. |
| Base Handler | Optional class that contains boilerplate code common to all handlers. Stores a reference to the next handler and implements default forwarding behavior. |
| Concrete Handlers | Contain the actual code for processing requests. Each handler decides whether to process a request and whether to pass it along the chain. |
| Client | Composes chains and initiates requests to any handler in the chain -- not necessarily the first one. |

## Conceptual Example

```swift
import XCTest

/// The Handler interface declares a method for building the chain of handlers.
/// It also declares a method for executing a request.
protocol Handler: AnyObject {

    @discardableResult
    func setNext(handler: Handler) -> Handler

    func handle(request: String) -> String?

    var nextHandler: Handler? { get set }
}

extension Handler {

    func setNext(handler: Handler) -> Handler {
        self.nextHandler = handler

        /// Returning a handler from here will let us link handlers in a
        /// convenient way like this:
        /// monkey.setNext(handler: squirrel).setNext(handler: dog)
        return handler
    }

    func handle(request: String) -> String? {
        return nextHandler?.handle(request: request)
    }
}

/// All Concrete Handlers either handle a request or pass it to the next handler
/// in the chain.
class MonkeyHandler: Handler {

    var nextHandler: Handler?

    func handle(request: String) -> String? {
        if (request == "Banana") {
            return "Monkey: I'll eat the " + request + ".\n"
        } else {
            return nextHandler?.handle(request: request)
        }
    }
}

class SquirrelHandler: Handler {

    var nextHandler: Handler?

    func handle(request: String) -> String? {

        if (request == "Nut") {
            return "Squirrel: I'll eat the " + request + ".\n"
        } else {
            return nextHandler?.handle(request: request)
        }
    }
}

class DogHandler: Handler {

    var nextHandler: Handler?

    func handle(request: String) -> String? {
        if (request == "MeatBall") {
            return "Dog: I'll eat the " + request + ".\n"
        } else {
            return nextHandler?.handle(request: request)
        }
    }
}

/// The client code is usually suited to work with a single handler. In most
/// cases, it is not even aware that the handler is part of a chain.
class Client {

    static func someClientCode(handler: Handler) {

        let food = ["Nut", "Banana", "Cup of coffee"]

        for item in food {

            print("Client: Who wants a " + item + "?\n")

            guard let result = handler.handle(request: item) else {
                print("  " + item + " was left untouched.\n")
                return
            }

            print("  " + result)
        }
    }
}

/// Let's see how it all works together.
class ChainOfResponsibilityConceptual: XCTestCase {

    func test() {

        let monkey = MonkeyHandler()
        let squirrel = SquirrelHandler()
        let dog = DogHandler()
        monkey.setNext(handler: squirrel).setNext(handler: dog)

        print("Chain: Monkey > Squirrel > Dog\n\n")
        Client.someClientCode(handler: monkey)
        print()
        print("Subchain: Squirrel > Dog\n\n")
        Client.someClientCode(handler: squirrel)
    }
}
```

**Output:**
```
Chain: Monkey > Squirrel > Dog

Client: Who wants a Nut?
  Squirrel: I'll eat the Nut.

Client: Who wants a Banana?
  Monkey: I'll eat the Banana.

Client: Who wants a Cup of coffee?
  Cup of coffee was left untouched.

Subchain: Squirrel > Dog

Client: Who wants a Nut?
  Squirrel: I'll eat the Nut.

Client: Who wants a Banana?
  Banana was left untouched.
```

## Real-World Example

```swift
import Foundation
import UIKit
import XCTest

protocol Handler {

    var next: Handler? { get }

    func handle(_ request: Request) -> LocalizedError?
}

class BaseHandler: Handler {

    var next: Handler?

    init(with handler: Handler? = nil) {
        self.next = handler
    }

    func handle(_ request: Request) -> LocalizedError? {
        return next?.handle(request)
    }
}

class LoginHandler: BaseHandler {

    override func handle(_ request: Request) -> LocalizedError? {

        guard request.email?.isEmpty == false else {
            return AuthError.emptyEmail
        }

        guard request.password?.isEmpty == false else {
            return AuthError.emptyPassword
        }

        return next?.handle(request)
    }
}

class SignUpHandler: BaseHandler {

    private struct Limit {
        static let passwordLength = 8
    }

    override func handle(_ request: Request) -> LocalizedError? {

        guard request.email?.contains("@") == true else {
            return AuthError.invalidEmail
        }

        guard (request.password?.count ?? 0) >= Limit.passwordLength else {
            return AuthError.invalidPassword
        }

        guard request.password == request.repeatedPassword else {
            return AuthError.differentPasswords
        }

        return next?.handle(request)
    }
}

class LocationHandler: BaseHandler {

    override func handle(_ request: Request) -> LocalizedError? {
        guard isLocationEnabled() else {
            return AuthError.locationDisabled
        }
        return next?.handle(request)
    }

    func isLocationEnabled() -> Bool {
        return true
    }
}

class NotificationHandler: BaseHandler {

    override func handle(_ request: Request) -> LocalizedError? {
        guard isNotificationsEnabled() else {
            return AuthError.notificationsDisabled
        }
        return next?.handle(request)
    }

    func isNotificationsEnabled() -> Bool {
        return false
    }
}

enum AuthError: LocalizedError {

    case emptyFirstName
    case emptyLastName

    case emptyEmail
    case emptyPassword

    case invalidEmail
    case invalidPassword
    case differentPasswords

    case locationDisabled
    case notificationsDisabled

    var errorDescription: String? {
        switch self {
        case .emptyFirstName:
            return "First name is empty"
        case .emptyLastName:
            return "Last name is empty"
        case .emptyEmail:
            return "Email is empty"
        case .emptyPassword:
            return "Password is empty"
        case .invalidEmail:
            return "Email is invalid"
        case .invalidPassword:
            return "Password is invalid"
        case .differentPasswords:
            return "Password and repeated password should be equal"
        case .locationDisabled:
            return "Please turn location services on"
        case .notificationsDisabled:
            return "Please turn notifications on"
        }
    }
}

protocol Request {

    var firstName: String? { get }
    var lastName: String? { get }

    var email: String? { get }
    var password: String? { get }
    var repeatedPassword: String? { get }
}

extension Request {

    var firstName: String? { return nil }
    var lastName: String? { return nil }

    var email: String? { return nil }
    var password: String? { return nil }
    var repeatedPassword: String? { return nil }
}

struct SignUpRequest: Request {

    var firstName: String?
    var lastName: String?

    var email: String?
    var password: String?
    var repeatedPassword: String?
}

struct LoginRequest: Request {

    var email: String?
    var password: String?
}

protocol AuthHandlerSupportable: AnyObject {

    var handler: Handler? { get set }
}

class BaseAuthViewController: UIViewController, AuthHandlerSupportable {

    var handler: Handler?

    init(handler: Handler) {
        self.handler = handler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class LoginViewController: BaseAuthViewController {

    func loginButtonSelected() {
        print("Login View Controller: User selected Login button")

        let request = LoginRequest(email: "smth@gmail.com", password: "123HardPass")

        if let error = handler?.handle(request) {
            print("Login View Controller: something went wrong")
            print("Login View Controller: Error -> " + (error.errorDescription ?? ""))
        } else {
            print("Login View Controller: Preconditions are successfully validated")
        }
    }
}

class SignUpViewController: BaseAuthViewController {

    func signUpButtonSelected() {
        print("SignUp View Controller: User selected SignUp button")

        let request = SignUpRequest(firstName: "Vasya",
                                    lastName: "Pupkin",
                                    email: "vasya.pupkin@gmail.com",
                                    password: "123HardPass",
                                    repeatedPassword: "123HardPass")

        if let error = handler?.handle(request) {
            print("SignUp View Controller: something went wrong")
            print("SignUp View Controller: Error -> " + (error.errorDescription ?? ""))
        } else {
            print("SignUp View Controller: Preconditions are successfully validated")
        }
    }
}

class ChainOfResponsibilityRealWorld: XCTestCase {

    func testChainOfResponsibilityRealWorld() {

        print("Client: Let's test Login flow!")

        let loginHandler = LoginHandler(with: LocationHandler())
        let loginController = LoginViewController(handler: loginHandler)

        loginController.loginButtonSelected()

        print("\nClient: Let's test SignUp flow!")

        let signUpHandler = SignUpHandler(with: LocationHandler(with: NotificationHandler()))
        let signUpController = SignUpViewController(handler: signUpHandler)

        signUpController.signUpButtonSelected()
    }
}
```

**Output:**
```
Client: Let's test Login flow!
Login View Controller: User selected Login button
Login View Controller: Preconditions are successfully validated

Client: Let's test SignUp flow!
SignUp View Controller: User selected SignUp button
SignUp View Controller: something went wrong
SignUp View Controller: Error -> Please turn notifications on
```

## iOS Framework Usage

- **UIKit**: The responder chain (`UIResponder.next`) is the canonical Chain of Responsibility in iOS. Touch events, motion events, and actions travel up from the first responder through views, view controllers, the window, and finally the application delegate.
- **SwiftUI**: View modifiers chain responsibility -- `.onTapGesture`, `.gesture()`, and `.allowsHitTesting()` form an implicit chain where gesture recognizers compete and propagate through the view hierarchy. `PreferenceKey` propagation also follows chain-of-responsibility semantics.
- **Foundation/Combine**: `URLProtocol` subclasses form a chain where each registered protocol class gets a chance to handle a URL request. Combine's `catch`, `retry`, and `tryCatch` operators create error-handling chains where each operator decides whether to handle the error or propagate it downstream.

## Swift-Specific Notes

- Use protocol extensions for default forwarding behavior (as shown in the conceptual example), which eliminates the need for a base class and allows handlers to be structs or classes freely.
- Swift's `@discardableResult` attribute on `setNext(handler:)` enables fluent chaining syntax (`a.setNext(handler: b).setNext(handler: c)`) while still allowing silent ignoring of the return value.
- Leverage `Result<Success, Failure>` or `throws` instead of returning optional errors for a more idiomatic Swift error-handling chain. Each handler can `throw` or return `.failure` to short-circuit the chain.
- Consider using Swift closures as lightweight handlers when the chain logic is simple: `[(Request) -> Error?]` array iterated with `first(where:)` provides a functional Chain of Responsibility.
- Combine Chain of Responsibility with Swift's `async/await` for asynchronous validation pipelines where each handler may need to perform network calls or database lookups before deciding.

## Related Patterns

- **Composite**: The chain can be built along branches of a Composite tree, where parent components serve as handlers when children cannot process a request.
- **Command**: Chain of Responsibility handlers can be implemented as Commands. Each handler wraps a specific operation and passes unhandled requests to the next handler.
- **Decorator**: Both have recursive composition, but CoR handlers can independently decide to stop processing, while decorators always extend behavior and cannot break the flow.
