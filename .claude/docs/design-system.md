# Design System & HIG Guidelines

> Apple Human Interface Guidelines compliance for iOS apps.
> Related skill: `/axiom:audit accessibility`
> Axiom complementa: Liquid Glass, SF Symbols advanced

## Color Guidelines

### Use Semantic Colors

Always prefer system semantic colors over custom colors:

```swift
// ✅ Correct: Semantic colors adapt to Dark Mode automatically
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

// ❌ Wrong: Hardcoded colors break in Dark Mode
Color.black
Color.white
Color(hex: "#FFFFFF")
```

### System Colors for Accents

```swift
// ✅ System colors (adapt to accessibility settings)
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

`Example/` defines its colors in code with light/dark hex pairs via `Color.adaptive(light:dark:)` (`Core/Common/Extensions/Color+Hex.swift`), resolved at render time from the trait collection. Use these tokens instead of raw colors:

```swift
// Core/DesignSystem/Tokens/AppColors.swift (excerpt)
import SwiftUI

// MARK: - AppColors

enum AppColors {
    // MARK: - Brand / Accent

    static let primary = Color.adaptive(light: "007AFF", dark: "0A84FF")
    static let secondary = Color.adaptive(light: "5856D6", dark: "5E5CE6")
    static let accent = Color.adaptive(light: "FF9500", dark: "FF9F0A")

    // MARK: - Status

    static let success = Color.adaptive(light: "34C759", dark: "30D158")
    static let warning = Color.adaptive(light: "FFCC00", dark: "FFD60A")
    static let error = Color.adaptive(light: "FF3B30", dark: "FF453A")

    // MARK: - Surfaces

    static let background = Color.adaptive(light: "F2F2F7", dark: "000000")
    static let surface = Color.adaptive(light: "FFFFFF", dark: "1C1C1E")
    static let cardBackground = Color.adaptive(light: "FFFFFF", dark: "1C1C1E")

    // MARK: - Text

    static let text = Color.adaptive(light: "000000", dark: "FFFFFF")
    static let textSecondary = Color.adaptive(light: "8E8E93", dark: "98989D")
    static let textTertiary = Color.adaptive(light: "C7C7CC", dark: "48484A")
}
```

The file also defines `cardBorder`, `divider`, `codeBackground`, gradient, `onGradient`/`onAccent`, `shadowColor` and splash-screen colors. Add a new token there (with both light and dark values) instead of using a hex color in a View.

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
// ✅ Correct: Dynamic Type compatible
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

`AppTypography` is an enum of text styles with a `font` property that maps each case to a Dynamic Type system font. Use it as `.font(AppTypography.footnote.font)`:

```swift
// Core/DesignSystem/Tokens/AppTypography.swift
import SwiftUI

// MARK: - AppTypography

enum AppTypography {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2

    var font: Font {
        switch self {
        case .largeTitle:
            .largeTitle
        case .title1:
            .title
        case .title2:
            .title2
        case .title3:
            .title3
        case .headline:
            .headline
        case .body:
            .body
        case .callout:
            .callout
        case .subheadline:
            .subheadline
        case .footnote:
            .footnote
        case .caption1:
            .caption
        case .caption2:
            .caption2
        }
    }
}
```

### Dynamic Type Support

```swift
// ✅ Always support Dynamic Type
Text("Hello")
    .font(.body)  // Scales with user's text size preference

// ✅ Use scaledMetric for custom sizes
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24

// ❌ Never use fixed font sizes for body text
Text("Hello")
    .font(.system(size: 16))  // WRONG: Won't scale
```

---

## Accessibility Requirements

### Minimum Standards

| Requirement | Value | Notes |
|-------------|-------|-------|
| **Contrast Ratio** | ≥ 4.5:1 | Text on background (WCAG AA) |
| **Large Text Contrast** | ≥ 3:1 | For 18pt+ or 14pt+ bold |
| **Touch Targets** | ≥ 44×44 pt | All interactive elements |
| **Dynamic Type** | Up to 200% | Text must not truncate |

### Touch Target Sizes

```swift
// ✅ Ensure minimum 44×44 touch target
Button(action: {}) {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)

// ✅ Use .contentShape for expanded hit area
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
// ✅ Icons without text need labels
Button(action: delete) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")

// ✅ Decorative images should be hidden
Image("decorative-pattern")
    .accessibilityHidden(true)

// ✅ Meaningful images need descriptions
Image("product-photo")
    .accessibilityLabel("Blue sneakers, side view")
```

### Accessibility Identifiers (for UI Testing)

> `.accessibilityLabel` = for users (VoiceOver, localized).
> `.accessibilityIdentifier` = for tests (XCUITest, NOT localized).
> They serve different purposes — use both when appropriate.

```swift
// Interactive elements: ALWAYS add both
Button(action: delete) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")                    // For VoiceOver
.accessibilityIdentifier("article.deleteButton")      // For UI tests

// Key data displays: add identifier
Text(article.title)
    .accessibilityIdentifier("article.title")

// State containers: add identifier
ProgressView()
    .accessibilityIdentifier("article.loadingIndicator")

// Decorative elements: NO identifier needed
Image("decorative-pattern")
    .accessibilityHidden(true)
```

#### Naming Convention

| Segment | Rule | Example |
|---------|------|---------|
| Feature | camelCase feature name | `article` |
| Element | camelCase element type | `deleteButton`, `title`, `row` |
| Qualifier | Optional, for dynamic items | `article.row.123` |

Pattern: `[feature].[element].[qualifier?]`

> Full reference: `ui-testing.md` and `create-ui-tests.md`

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

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    static let zero: CGFloat = 0
}
```

`Spacing.md` (16pt) is the default padding used across `Example/` (e.g. list cards in `PokemonListView`).

### Usage

```swift
VStack(spacing: Spacing.sm) {
    Text("Title")
    Text("Subtitle")
}
.padding(Spacing.md)

HStack(spacing: Spacing.xs) {
    Image(systemName: "star")
    Text("Favorite")
}
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

### Cards

```swift
// Core/Common/SwiftUI/Components/CardView.swift (illustrative; shared components live here, next to ErrorView and LoadingStateView)
struct CardView<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## SF Symbols

### Symbol Selection

```swift
// Use filled variants for selected/active states
Image(systemName: isSelected ? "star.fill" : "star")

// Use semantic symbols when available
Image(systemName: "person.crop.circle")  // Profile
Image(systemName: "gear")                 // Settings
Image(systemName: "magnifyingglass")      // Search
Image(systemName: "plus")                 // Add
Image(systemName: "trash")                // Delete
```

### Symbol Configuration

```swift
// Size with font
Image(systemName: "star.fill")
    .font(.title)

// Or explicit size
Image(systemName: "star.fill")
    .imageScale(.large)

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
// ✅ Content respects safe areas by default
VStack {
    Text("Content")
}

// ✅ Backgrounds can extend into safe areas
VStack {
    Text("Content")
}
.background(Color.blue.ignoresSafeArea())

// ❌ Don't ignore safe areas for interactive content
Button("Tap me") { }
    .ignoresSafeArea()  // WRONG: May be unreachable
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

- [ ] All interactive elements have 44×44pt minimum touch targets
- [ ] All icons have accessibility labels
- [ ] VoiceOver navigation makes sense
- [ ] Screen reader announces content in logical order
- [ ] No information conveyed by color alone
- [ ] All interactive elements have `.accessibilityIdentifier` (if UI test target exists)
- [ ] Identifiers follow `[feature].[element].[qualifier?]` naming convention
- [ ] Stub DataSources return consistent data for UI tests

### Layout Review

- [ ] Content respects safe areas
- [ ] Works in portrait and landscape (if supported)
- [ ] Works on all supported device sizes
- [ ] Text doesn't truncate at large Dynamic Type sizes

---

## Accessibility Testing Workflow

### Using Axiom Accessibility Auditor

```bash
# Run comprehensive accessibility audit
/axiom:audit accessibility
```

The audit checks for:
- Missing VoiceOver labels
- Touch target size violations (< 44×44pt)
- Dynamic Type truncation
- Color contrast failures
- Information conveyed by color alone

### Manual Testing Steps

#### 1. VoiceOver Testing

```
Settings → Accessibility → VoiceOver → ON
```

| Test | What to Check |
|------|---------------|
| **Navigation order** | Swipe through all elements - logical flow? |
| **Labels** | Every control announced meaningfully? |
| **Actions** | Double-tap works on all buttons? |
| **Hints** | Complex controls have usage hints? |
| **Announcements** | State changes announced (loading, error)? |

#### 2. Dynamic Type Testing

```
Settings → Accessibility → Display & Text Size → Larger Text
```

| Size | What to Check |
|------|---------------|
| **xSmall** | Text readable, not too sparse |
| **Default** | Baseline appearance |
| **xxxLarge** | No truncation, scrolls if needed |
| **AX5** (largest) | App remains usable |

#### 3. Color & Contrast Testing

```
Settings → Accessibility → Display & Text Size
```

| Setting | What to Check |
|---------|---------------|
| **Increase Contrast** | UI elements have stronger borders/fills |
| **Reduce Transparency** | Blurs replaced with solid backgrounds |
| **Differentiate Without Color** | Shapes/patterns distinguish states |

### Accessibility Inspector (Xcode)

```
Xcode → Open Developer Tool → Accessibility Inspector
```

| Feature | Use Case |
|---------|----------|
| **Inspection** | Point at elements to see accessibility properties |
| **Audit** | Auto-detect common issues |
| **Settings** | Simulate Dynamic Type, Invert Colors, etc. |

---

## WCAG 2.1 AA Checklist

> Web Content Accessibility Guidelines adapted for iOS. Level AA is the legal standard.

### Perceivable

| Criterion | iOS Implementation | Check |
|-----------|-------------------|-------|
| **1.1.1 Non-text Content** | All images have `.accessibilityLabel()` | ☐ |
| **1.3.1 Info and Relationships** | Headings use `.accessibilityAddTraits(.isHeader)` | ☐ |
| **1.3.4 Orientation** | App works in both portrait/landscape | ☐ |
| **1.4.1 Use of Color** | Don't use color alone (add icons/text) | ☐ |
| **1.4.3 Contrast (Minimum)** | Text ≥ 4.5:1, Large text ≥ 3:1 | ☐ |
| **1.4.4 Resize Text** | Text scales to 200% (Dynamic Type) | ☐ |
| **1.4.10 Reflow** | Content reflows, no horizontal scroll | ☐ |
| **1.4.11 Non-text Contrast** | UI elements ≥ 3:1 contrast | ☐ |

### Operable

| Criterion | iOS Implementation | Check |
|-----------|-------------------|-------|
| **2.1.1 Keyboard** | Full VoiceOver navigation | ☐ |
| **2.4.3 Focus Order** | Logical reading order | ☐ |
| **2.4.6 Headings and Labels** | Descriptive, unique labels | ☐ |
| **2.5.5 Target Size** | Touch targets ≥ 44×44pt | ☐ |

### Understandable

| Criterion | iOS Implementation | Check |
|-----------|-------------------|-------|
| **3.2.1 On Focus** | No unexpected changes on focus | ☐ |
| **3.2.2 On Input** | No unexpected changes on input | ☐ |
| **3.3.1 Error Identification** | Errors clearly described | ☐ |
| **3.3.2 Labels or Instructions** | Form fields have clear labels | ☐ |

### Robust

| Criterion | iOS Implementation | Check |
|-----------|-------------------|-------|
| **4.1.2 Name, Role, Value** | Custom controls have proper traits | ☐ |

### SwiftUI Accessibility Modifiers Reference

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
.accessibilitySortPriority(1)  // Higher = read first

// Hiding
.accessibilityHidden(true)  // Decorative elements
```

---

## Liquid Glass (iOS 26+)

> Prepare for Apple's new design language when targeting iOS 26+.

### Readiness Checklist

| Preparation | Description |
|-------------|-------------|
| **Use semantic colors** | Will automatically adapt to Liquid Glass materials |
| **Avoid hardcoded blur** | System will replace with Liquid Glass effects |
| **Test on iOS 26 simulator** | Verify visual hierarchy with new materials |
| **Check contrast** | Liquid Glass may affect text readability |

### Migration Notes

When iOS 26+ adoption is sufficient:

```swift
// Future: Check for Liquid Glass availability
if #available(iOS 26, *) {
    // Use Liquid Glass materials
    .background(.regularMaterial)  // Will use Liquid Glass
} else {
    // Fallback to current materials
    .background(.ultraThinMaterial)
}
```

### Audit for Liquid Glass

```bash
# When ready to adopt iOS 26+
/axiom:audit liquid-glass
```

The audit identifies:
- Views ready for Liquid Glass
- Blur effects to migrate
- Potential contrast issues
- Toolbar improvements

---

## Quick Reference

| Category | Tool/Command |
|----------|--------------|
| **Accessibility audit** | `/axiom:audit accessibility` |
| **Manual VoiceOver** | Settings → Accessibility → VoiceOver |
| **Xcode Inspector** | Xcode → Open Developer Tool → Accessibility Inspector |
| **Contrast checker** | Use online tools like WebAIM Contrast Checker |
| **Liquid Glass prep** | `/axiom:audit liquid-glass` (iOS 26+) |
