# Design System & HIG Guidelines

> Apple Human Interface Guidelines compliance for iOS apps.

## Color Guidelines

### Use Semantic Colors

Always prefer system semantic colors over custom colors:

```swift
// Correct: Semantic colors adapt to Dark Mode automatically
Color(.systemBackground)
Color(.secondarySystemBackground)
Color(.tertiarySystemBackground)
Color(.systemGroupedBackground)
Color(.secondarySystemGroupedBackground)

Color(.label)
Color(.secondaryLabel)
Color(.tertiaryLabel)
Color(.quaternaryLabel)

Color(.systemFill)
Color(.secondarySystemFill)
Color(.tertiarySystemFill)
Color(.quaternarySystemFill)

Color(.separator)
Color(.opaqueSeparator)

// Wrong: Hardcoded colors break in Dark Mode
Color.black
Color.white
Color(hex: "#FFFFFF")
```

### System Colors for Accents

```swift
// System colors (adapt to accessibility settings)
Color(.systemBlue)
Color(.systemGreen)
Color(.systemRed)
Color(.systemOrange)
Color(.systemYellow)
Color(.systemPink)
Color(.systemPurple)
Color(.systemTeal)
Color(.systemIndigo)

// For tint color
Color.accentColor  // Uses app's accent color from asset catalog
```

### Custom Colors (When Necessary)

```swift
// Core/DesignSystem/Tokens/AppColors.swift
import SwiftUI

enum AppColors {
    static let brand = Color("BrandColor")

    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)

    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)

    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)
    static let info = Color(.systemBlue)
}
```

### Dark Mode Rules

| Rule | Description |
|------|-------------|
| **Never create a Dark Mode toggle** | Respect system preference via `@Environment(\.colorScheme)` |
| **Use semantic colors** | They adapt automatically |
| **Test in both modes** | Always verify appearance in Light and Dark |
| **Asset catalog variants** | Define Light/Dark variants for custom colors |

---

## Typography

### Use System Fonts

```swift
// Correct: Dynamic Type compatible
.font(.largeTitle)
.font(.title)
.font(.title2)
.font(.title3)
.font(.headline)
.font(.subheadline)
.font(.body)
.font(.callout)
.font(.footnote)
.font(.caption)
.font(.caption2)

// With weight
.font(.body.weight(.semibold))
.font(.headline.bold())
```

### Typography Tokens

```swift
// Core/DesignSystem/Tokens/AppTypography.swift
import SwiftUI

enum AppTypography {
    static let screenTitle = Font.largeTitle.weight(.bold)
    static let sectionTitle = Font.title2.weight(.semibold)
    static let cardTitle = Font.headline

    static let bodyRegular = Font.body
    static let bodyEmphasized = Font.body.weight(.medium)

    static let caption = Font.caption
    static let footnote = Font.footnote
}
```

### Dynamic Type Support

```swift
// Always support Dynamic Type
Text("Hello")
    .font(.body)  // Scales with user's text size preference

// Use scaledMetric for custom sizes
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24

// Never use fixed font sizes for body text
Text("Hello")
    .font(.system(size: 16))  // WRONG: Won't scale
```

---

## Accessibility Requirements

### Minimum Standards

| Requirement | Value | Notes |
|-------------|-------|-------|
| **Contrast Ratio** | >= 4.5:1 | Text on background (WCAG AA) |
| **Large Text Contrast** | >= 3:1 | For 18pt+ or 14pt+ bold |
| **Touch Targets** | >= 44x44 pt | All interactive elements |
| **Dynamic Type** | Up to 200% | Text must not truncate |

### Touch Target Sizes

```swift
// Ensure minimum 44x44 touch target
Button(action: {}) {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)

// Use .contentShape for expanded hit area
HStack {
    Image(systemName: "star")
    Text("Favorite")
}
.contentShape(Rectangle())
.frame(minHeight: 44)
.onTapGesture { }
```

### Accessibility Labels

```swift
// Icons without text need labels
Button(action: delete) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")

// Decorative images should be hidden
Image("decorative-pattern")
    .accessibilityHidden(true)

// Meaningful images need descriptions
Image("product-photo")
    .accessibilityLabel("Blue sneakers, side view")
```

### VoiceOver Best Practices

```swift
// Group related elements
HStack {
    Image(systemName: "star.fill")
    Text("4.5")
    Text("(120 reviews)")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Rating: 4.5 stars, 120 reviews")

// Custom actions
.accessibilityAction(named: "Mark as favorite") {
    toggleFavorite()
}

// Hints for complex interactions
.accessibilityHint("Double tap to open details, swipe up for more options")
```

---

## Spacing

### Spacing Scale

```swift
// Core/DesignSystem/Tokens/Spacing.swift
import SwiftUI

enum Spacing {
    /// 4pt
    static let xxxs: CGFloat = 4

    /// 8pt
    static let xxs: CGFloat = 8

    /// 12pt
    static let xs: CGFloat = 12

    /// 16pt - Default spacing
    static let sm: CGFloat = 16

    /// 20pt
    static let md: CGFloat = 20

    /// 24pt
    static let lg: CGFloat = 24

    /// 32pt
    static let xl: CGFloat = 32

    /// 40pt
    static let xxl: CGFloat = 40

    /// 48pt
    static let xxxl: CGFloat = 48
}
```

### Usage

```swift
VStack(spacing: Spacing.sm) {
    Text("Title")
    Text("Subtitle")
}
.padding(Spacing.md)
```

---

## Component Patterns

### Buttons

```swift
// Primary action
Button("Save") { }
    .buttonStyle(.borderedProminent)

// Secondary action
Button("Cancel") { }
    .buttonStyle(.bordered)

// Tertiary/text action
Button("Learn more") { }
    .buttonStyle(.plain)
    .foregroundStyle(.tint)

// Destructive action
Button("Delete", role: .destructive) { }
```

### Lists

```swift
// Grouped list (settings-style)
List {
    Section("Account") {
        NavigationLink("Profile") { }
        NavigationLink("Security") { }
    }
}
.listStyle(.insetGrouped)

// Plain list (content-style)
List(items) { item in
    ItemRow(item: item)
}
.listStyle(.plain)
```

---

## SF Symbols

### Symbol Selection

```swift
// Use filled variants for selected/active states
Image(systemName: isSelected ? "star.fill" : "star")

// Use semantic symbols when available
Image(systemName: "person.crop.circle")  // Profile
Image(systemName: "gear")                // Settings
Image(systemName: "magnifyingglass")     // Search
Image(systemName: "plus")               // Add
Image(systemName: "trash")              // Delete
```

### Symbol Configuration

```swift
// Size with font
Image(systemName: "star.fill")
    .font(.title)

// With rendering mode
Image(systemName: "heart.fill")
    .symbolRenderingMode(.multicolor)

// With variable value (iOS 16+)
Image(systemName: "speaker.wave.3.fill", variableValue: 0.75)
```

---

## Safe Areas & Layout

### Respect Safe Areas

```swift
// Content respects safe areas by default
VStack {
    Text("Content")
}

// Backgrounds can extend into safe areas
VStack {
    Text("Content")
}
.background(Color.blue.ignoresSafeArea())

// Don't ignore safe areas for interactive content
```

### Adaptive Layouts

```swift
// Respond to size class
@Environment(\.horizontalSizeClass) var sizeClass

var body: some View {
    if sizeClass == .compact {
        VStack { content }
    } else {
        HStack { content }
    }
}

// Or use ViewThatFits
ViewThatFits {
    HStack { content }
    VStack { content }
}
```

---

## Checklist Before Release

### Visual Review

- [ ] Test in Light Mode
- [ ] Test in Dark Mode
- [ ] Test with Increased Contrast enabled
- [ ] Test at smallest Dynamic Type size
- [ ] Test at largest Dynamic Type size (Accessibility sizes)
- [ ] Verify contrast ratios meet 4.5:1 minimum

### Accessibility Review

- [ ] All interactive elements have 44x44pt minimum touch targets
- [ ] All icons have accessibility labels
- [ ] VoiceOver navigation makes sense
- [ ] Screen reader announces content in logical order
- [ ] No information conveyed by color alone

### Layout Review

- [ ] Content respects safe areas
- [ ] Works in portrait and landscape (if supported)
- [ ] Works on all supported device sizes
- [ ] Text doesn't truncate at large Dynamic Type sizes

---

## SwiftUI Accessibility Modifiers Reference

```swift
// Labels and Descriptions
.accessibilityLabel("Close button")
.accessibilityHint("Double tap to dismiss")
.accessibilityValue("50 percent")

// Traits
.accessibilityAddTraits(.isHeader)
.accessibilityAddTraits(.isButton)
.accessibilityAddTraits(.isSelected)
.accessibilityRemoveTraits(.isImage)

// Grouping
.accessibilityElement(children: .combine)
.accessibilityElement(children: .contain)
.accessibilityElement(children: .ignore)

// Actions
.accessibilityAction(named: "Delete") { delete() }
.accessibilityAdjustableAction { direction in
    // Handle increment/decrement
}

// Ordering
.accessibilitySortPriority(1)

// Hiding
.accessibilityHidden(true)
```
