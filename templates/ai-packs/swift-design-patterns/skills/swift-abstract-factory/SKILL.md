---
name: swift-abstract-factory
description: >
  Swift Abstract Factory design pattern — Creational. Use when you need to create families of
  related objects without specifying concrete classes, ensure product compatibility within a family,
  or decouple client code from multiple product variants. Includes conceptual example, real-world
  example, and iOS framework usage guide.
license: MIT
metadata:
  category: Creational
  source: refactoring.guru
---

# Abstract Factory — Swift

> **Category**: Creational
> **Intent**: Produce families of related objects without specifying their concrete classes.

## When to Use

Use the Abstract Factory pattern when your code needs to work with various families of related products, but you do not want it to depend on the concrete classes of those products. The concrete classes may be unknown beforehand or you may want to allow for future extensibility. Abstract Factory provides you with an interface for creating objects from each class of the product family. As long as your code creates objects via this interface, you do not need to worry about creating the wrong variant of a product that does not match the products already created by your app.

The pattern is particularly valuable when you have a class with a set of Factory Methods that blur its primary responsibility. In a well-designed program, each class is responsible for only one thing. When a class deals with multiple product types, it may be worth extracting its factory methods into a standalone Abstract Factory class (or set of classes). This centralizes creation logic and makes it easier to manage, test, and extend.

Consider Abstract Factory whenever product compatibility matters. For example, in a UI toolkit that must render consistently across platforms (iOS, macOS, watchOS), each platform needs its own family of buttons, text fields, and toggles. An Abstract Factory for each platform ensures that all UI elements in a given context come from the same family, preventing visual or behavioral inconsistencies. The client code works with factories and products only through their abstract interfaces, making it completely independent of the actual product variants.

## Structure

| Participant | Role |
|-------------|------|
| Abstract Product (protocol) | Declares an interface for a type of product object. Each distinct product in a family has its own abstract product protocol. |
| Concrete Product | A specific implementation of an abstract product, grouped by variant. Each abstract product must be implemented across all variants. |
| Abstract Factory (protocol) | Declares a set of creation methods, one for each abstract product in the family. |
| Concrete Factory | Implements the creation methods of the abstract factory. Each concrete factory corresponds to a specific product variant and creates only products of that variant. |
| Client | Works with factories and products exclusively through their abstract interfaces, remaining decoupled from any specific variant. |

## Conceptual Example

```swift
import XCTest

protocol AbstractFactory {
    func createProductA() -> AbstractProductA
    func createProductB() -> AbstractProductB
}

class ConcreteFactory1: AbstractFactory {
    func createProductA() -> AbstractProductA {
        return ConcreteProductA1()
    }

    func createProductB() -> AbstractProductB {
        return ConcreteProductB1()
    }
}

class ConcreteFactory2: AbstractFactory {
    func createProductA() -> AbstractProductA {
        return ConcreteProductA2()
    }

    func createProductB() -> AbstractProductB {
        return ConcreteProductB2()
    }
}

protocol AbstractProductA {
    func usefulFunctionA() -> String
}

class ConcreteProductA1: AbstractProductA {
    func usefulFunctionA() -> String {
        return "The result of the product A1."
    }
}

class ConcreteProductA2: AbstractProductA {
    func usefulFunctionA() -> String {
        return "The result of the product A2."
    }
}

protocol AbstractProductB {
    func usefulFunctionB() -> String
    func anotherUsefulFunctionB(collaborator: AbstractProductA) -> String
}

class ConcreteProductB1: AbstractProductB {
    func usefulFunctionB() -> String {
        return "The result of the product B1."
    }

    func anotherUsefulFunctionB(collaborator: AbstractProductA) -> String {
        let result = collaborator.usefulFunctionA()
        return "The result of the B1 collaborating with the (\(result))"
    }
}

class ConcreteProductB2: AbstractProductB {
    func usefulFunctionB() -> String {
        return "The result of the product B2."
    }

    func anotherUsefulFunctionB(collaborator: AbstractProductA) -> String {
        let result = collaborator.usefulFunctionA()
        return "The result of the B2 collaborating with the (\(result))"
    }
}

class Client {
    static func someClientCode(factory: AbstractFactory) {
        let productA = factory.createProductA()
        let productB = factory.createProductB()

        print(productB.usefulFunctionB())
        print(productB.anotherUsefulFunctionB(collaborator: productA))
    }
}

class AbstractFactoryConceptual: XCTestCase {
    func testAbstractFactoryConceptual() {
        print("Client: Testing client code with the first factory type:")
        Client.someClientCode(factory: ConcreteFactory1())

        print("Client: Testing the same client code with the second factory type:")
        Client.someClientCode(factory: ConcreteFactory2())
    }
}
```

**Output:**

```
Client: Testing client code with the first factory type:
The result of the product B1.
The result of the B1 collaborating with the (The result of the product A1.)
Client: Testing the same client code with the second factory type:
The result of the product B2.
The result of the B2 collaborating with the (The result of the product A2.)
```

## Real-World Example

```swift
import Foundation
import UIKit
import XCTest

enum AuthType {
    case login
    case signUp
}

protocol AuthViewFactory {
    static func authView(for type: AuthType) -> AuthView
    static func authController(for type: AuthType) -> AuthViewController
}

class StudentAuthViewFactory: AuthViewFactory {
    static func authView(for type: AuthType) -> AuthView {
        print("Student View has been created")
        switch type {
            case .login: return StudentLoginView()
            case .signUp: return StudentSignUpView()
        }
    }

    static func authController(for type: AuthType) -> AuthViewController {
        let controller = StudentAuthViewController(contentView: authView(for: type))
        print("Student View Controller has been created")
        return controller
    }
}

class TeacherAuthViewFactory: AuthViewFactory {
    static func authView(for type: AuthType) -> AuthView {
        print("Teacher View has been created")
        switch type {
            case .login: return TeacherLoginView()
            case .signUp: return TeacherSignUpView()
        }
    }

    static func authController(for type: AuthType) -> AuthViewController {
        let controller = TeacherAuthViewController(contentView: authView(for: type))
        print("Teacher View Controller has been created")
        return controller
    }
}

protocol AuthView {
    typealias AuthAction = (AuthType) -> ()
    var contentView: UIView { get }
    var authHandler: AuthAction? { get set }
    var description: String { get }
}

class StudentSignUpView: UIView, AuthView {
    private class StudentSignUpContentView: UIView {}

    var contentView: UIView = StudentSignUpContentView()
    var authHandler: AuthView.AuthAction?

    override var description: String {
        return "Student-SignUp-View"
    }
}

class StudentLoginView: UIView, AuthView {
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let signUpButton = UIButton()

    var contentView: UIView {
        return self
    }

    var authHandler: AuthView.AuthAction?

    override var description: String {
        return "Student-Login-View"
    }
}

class TeacherSignUpView: UIView, AuthView {
    class TeacherSignUpContentView: UIView {}

    var contentView: UIView = TeacherSignUpContentView()
    var authHandler: AuthView.AuthAction?

    override var description: String {
        return "Teacher-SignUp-View"
    }
}

class TeacherLoginView: UIView, AuthView {
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton()
    private let forgotPasswordButton = UIButton()

    var contentView: UIView {
        return self
    }

    var authHandler: AuthView.AuthAction?

    override var description: String {
        return "Teacher-Login-View"
    }
}

class AuthViewController: UIViewController {
    fileprivate var contentView: AuthView

    init(contentView: AuthView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        return nil
    }
}

class StudentAuthViewController: AuthViewController {}

class TeacherAuthViewController: AuthViewController {}

private class ClientCode {
    private var currentController: AuthViewController?

    private lazy var navigationController: UINavigationController = {
        guard let vc = currentController else { return UINavigationController() }
        return UINavigationController(rootViewController: vc)
    }()

    private let factoryType: AuthViewFactory.Type

    init(factoryType: AuthViewFactory.Type) {
        self.factoryType = factoryType
    }

    func presentLogin() {
        let controller = factoryType.authController(for: .login)
        navigationController.pushViewController(controller, animated: true)
    }

    func presentSignUp() {
        let controller = factoryType.authController(for: .signUp)
        navigationController.pushViewController(controller, animated: true)
    }
}

class AbstractFactoryRealWorld: XCTestCase {
    func testFactoryMethodRealWorld() {
        #if teacherMode
            let clientCode = ClientCode(factoryType: TeacherAuthViewFactory.self)
        #else
            let clientCode = ClientCode(factoryType: StudentAuthViewFactory.self)
        #endif

        clientCode.presentLogin()
        print("Login screen has been presented")

        clientCode.presentSignUp()
        print("Sign up screen has been presented")
    }
}
```

**Output:**

```
Student View has been created
Student View Controller has been created
Login screen has been presented
Student View has been created
Student View Controller has been created
Sign up screen has been presented
```

## iOS Framework Usage

- **UIKit**: `UIAppearance` acts as an abstract factory for styling -- you configure appearance proxies that produce consistently styled UI elements. `UITraitCollection` effectively selects between "product families" (light/dark mode, compact/regular size classes), and the system creates matching UI variants. `NSCoder`/`NSKeyedArchiver` factories produce different serialized representations of the same object graph.
- **SwiftUI**: SwiftUI's environment system with `@Environment(\.colorScheme)` and custom `EnvironmentKey` types acts as an abstract factory mechanism. Different environment configurations produce different visual families. Modifier chains like `.buttonStyle()` and `.textFieldStyle()` let you swap entire families of component appearances without changing view code.
- **Foundation**: `URLProtocol` is an abstract factory for network request handling -- different registered protocol classes handle different URL schemes (HTTP, FTP, custom). `NSValueTransformer` acts as a factory for value transformations where subclasses provide different conversion strategies.

## Swift-Specific Notes

- In Swift, Abstract Factory is best expressed using **protocols with static methods** or **metatypes** (`AuthViewFactory.Type`), as shown in the real-world example. This leverages Swift's first-class type system.
- Use `associatedtype` in factory protocols when products need type relationships: `associatedtype ViewType: AuthView` ensures compile-time consistency within a family.
- Swift's conditional compilation (`#if`, `#else`) naturally complements Abstract Factory for compile-time variant selection, as demonstrated in the real-world example with `#if teacherMode`.
- Generics can reduce boilerplate: `func create<F: AbstractFactory>(using factory: F)` lets the compiler enforce product family consistency at compile time.
- Consider using Swift enums with associated values as a lightweight alternative when the number of product families is small and fixed.
- For dependency injection containers (e.g., Swinject, Factory), the Abstract Factory pattern underpins how different module registrations produce different dependency graphs for production vs. testing.

## Related Patterns

- **Factory Method**: Abstract Factory classes are often based on a set of Factory Methods. Abstract Factory is the more complex evolution when you need families of objects rather than single products.
- **Builder**: Builder focuses on constructing complex objects step by step, while Abstract Factory emphasizes creating families of related objects in one shot.
- **Prototype**: Can compose Abstract Factory methods as an alternative to subclassing for concrete factory creation.
- **Singleton**: Concrete factory implementations are often Singletons, since usually only one factory instance per variant is needed.
