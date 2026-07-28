---
name: swift-decorator
description: >
  Swift Decorator design pattern — Structural. Use when adding behavior to objects dynamically
  without modifying them, building flexible wrapper chains, implementing middleware, or creating
  composable image/data filters. Includes conceptual example, real-world example, and iOS framework usage guide.
license: MIT
metadata:
  category: Structural
  source: refactoring.guru
---

# Decorator — Swift

> **Category**: Structural
> **Intent**: Decorator is a structural design pattern that lets you attach new behaviors to objects by placing these objects inside special wrapper objects that contain the behaviors.

## When to Use

Use the Decorator pattern when you need to add extra behaviors to objects at runtime without breaking the code that uses these objects. The pattern lets you stack behaviors by wrapping objects with multiple decorators. The result is the same as inheritance but without creating new subclasses for each combination of behaviors.

This pattern is ideal when extending a class's behavior using inheritance is impractical — for example, when there are many independent extensions that would produce an explosion of subclasses for every combination. Decorator offers a flexible alternative to subclassing for extending functionality.

In iOS, Decorator is common in image processing pipelines (stacking filters), networking middleware (adding authentication, logging, caching layers), and stream processing (`InputStream` decorating).

## Structure

| Participant | Role |
|-------------|------|
| Component (Protocol) | Declares the common interface for both wrappers and wrapped objects. |
| Concrete Component | The object being wrapped. Defines basic behavior. |
| Base Decorator | Has a reference to a wrapped component. Delegates all work to the wrapped object. |
| Concrete Decorators | Add extra behavior before or after delegating to the wrapped object. |

## Conceptual Example

```swift
import XCTest

protocol Component {
    func operation() -> String
}

class ConcreteComponent: Component {
    func operation() -> String {
        return "ConcreteComponent"
    }
}

class Decorator: Component {
    private var component: Component

    init(_ component: Component) {
        self.component = component
    }

    func operation() -> String {
        return component.operation()
    }
}

class ConcreteDecoratorA: Decorator {
    override func operation() -> String {
        return "ConcreteDecoratorA(" + super.operation() + ")"
    }
}

class ConcreteDecoratorB: Decorator {
    override func operation() -> String {
        return "ConcreteDecoratorB(" + super.operation() + ")"
    }
}

class Client {
    static func someClientCode(component: Component) {
        print("Result: " + component.operation())
    }
}

class DecoratorConceptual: XCTestCase {
    func testDecoratorConceptual() {
        print("Client: I've got a simple component")
        let simple = ConcreteComponent()
        Client.someClientCode(component: simple)

        let decorator1 = ConcreteDecoratorA(simple)
        let decorator2 = ConcreteDecoratorB(decorator1)
        print("\nClient: Now I've got a decorated component")
        Client.someClientCode(component: decorator2)
    }
}
```

**Output:**
```
Client: I've got a simple component
Result: ConcreteComponent

Client: Now I've got a decorated component
Result: ConcreteDecoratorB(ConcreteDecoratorA(ConcreteComponent))
```

## Real-World Example

```swift
import UIKit
import XCTest

protocol ImageEditor: CustomStringConvertible {
    func apply() -> UIImage
}

class ImageDecorator: ImageEditor {
    private var editor: ImageEditor

    required init(_ editor: ImageEditor) {
        self.editor = editor
    }

    func apply() -> UIImage {
        print(editor.description + " applies changes")
        return editor.apply()
    }

    var description: String { return "ImageDecorator" }
}

extension UIImage: ImageEditor {
    func apply() -> UIImage { return self }
    open override var description: String { return "Image" }
}

class BaseFilter: ImageDecorator {
    fileprivate var filter: CIFilter?

    init(editor: ImageEditor, filterName: String) {
        self.filter = CIFilter(name: filterName)
        super.init(editor)
    }

    required init(_ editor: ImageEditor) {
        super.init(editor)
    }

    override func apply() -> UIImage {
        let image = super.apply()
        let context = CIContext(options: nil)
        filter?.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        guard let output = filter?.outputImage else { return image }
        guard let coreImage = context.createCGImage(output, from: output.extent) else { return image }
        return UIImage(cgImage: coreImage)
    }

    override var description: String { return "BaseFilter" }
}

class BlurFilter: BaseFilter {
    required init(_ editor: ImageEditor) {
        super.init(editor: editor, filterName: "CIGaussianBlur")
    }

    func update(radius: Double) {
        filter?.setValue(radius, forKey: "inputRadius")
    }

    override var description: String { return "BlurFilter" }
}

class ColorFilter: BaseFilter {
    required init(_ editor: ImageEditor) {
        super.init(editor: editor, filterName: "CIColorControls")
    }

    func update(saturation: Double) { filter?.setValue(saturation, forKey: "inputSaturation") }
    func update(brightness: Double) { filter?.setValue(brightness, forKey: "inputBrightness") }
    func update(contrast: Double) { filter?.setValue(contrast, forKey: "inputContrast") }

    override var description: String { return "ColorFilter" }
}

class Resizer: ImageDecorator {
    private var xScale: CGFloat = 0
    private var yScale: CGFloat = 0
    private var hasAlpha = false

    convenience init(_ editor: ImageEditor, xScale: CGFloat, yScale: CGFloat, hasAlpha: Bool = false) {
        self.init(editor)
        self.xScale = xScale
        self.yScale = yScale
        self.hasAlpha = hasAlpha
    }

    required init(_ editor: ImageEditor) {
        super.init(editor)
    }

    override func apply() -> UIImage {
        let image = super.apply()
        let size = image.size.applying(CGAffineTransform(scaleX: xScale, y: yScale))
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, UIScreen.main.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage ?? image
    }

    override var description: String { return "Resizer" }
}

class DecoratorRealWorld: XCTestCase {
    func testDecoratorRealWorld() {
        let image = UIImage()

        print("Client: set up an editors stack")
        let resizer = Resizer(image, xScale: 0.2, yScale: 0.2)

        let blurFilter = BlurFilter(resizer)
        blurFilter.update(radius: 2)

        let colorFilter = ColorFilter(blurFilter)
        colorFilter.update(contrast: 0.53)
        colorFilter.update(brightness: 0.12)
        colorFilter.update(saturation: 4)

        clientCode(editor: colorFilter)
    }

    func clientCode(editor: ImageEditor) {
        let image = editor.apply()
        print("Client: all changes have been applied for \(image)")
    }
}
```

**Output:**
```
Client: set up an editors stack
BlurFilter applies changes
Resizer applies changes
Image applies changes
Client: all changes have been applied for Image
```

## iOS Framework Usage

- **UIKit**: `NSAttributedString` decorates strings with visual attributes. `UIScrollView` decorates content views with scrolling behavior.
- **SwiftUI**: View modifiers (`.font()`, `.padding()`, `.background()`) are decorators — each wraps the view and adds behavior. They chain: `Text("Hi").bold().italic()`.
- **Foundation**: `InputStream` / `OutputStream` decorators add buffering, compression, or encryption. `JSONEncoder` / `JSONDecoder` strategies decorate encoding behavior.

## Swift-Specific Notes

- **Protocol extensions**: Can act as lightweight decorators, adding behavior to all conforming types without wrapping.
- **Property wrappers**: `@propertyWrapper` is a built-in decorator mechanism — `@Published`, `@AppStorage`, `@State` all decorate stored properties with additional behavior.
- **Functional chaining**: Closures and higher-order functions provide a functional alternative: `image.applying(blur).applying(resize)`.
- **Struct decorators**: Use structs for stateless decorators to get value semantics and avoid reference counting overhead.
- **Method chaining**: Decorators that return `Self` enable fluent APIs: `builder.add(blur: 2).add(color: .red).build()`.

## Related Patterns

- **Adapter**: Changes an object's interface. Decorator enhances an object without changing its interface.
- **Composite**: Both have similar recursive structure, but Composite sums up children's results while Decorator adds behavior to the wrapped component.
- **Proxy**: Both wrap objects, but Proxy manages the lifecycle or access to the object, while Decorator adds behavior.
