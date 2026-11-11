# design-system.md — Design Tokens and UI Rules

The tokens the generator emits (`AppColors`, `AppTypography`, `Spacing`), where shared components live, and the rules Views follow when they use them.

## Tokens

All tokens live in `Core/DesignSystem/Tokens/`. Views use tokens, never literals. A missing value is added to the token file, so there is one place to change it and one place to audit.

### AppColors

```swift
// Core/DesignSystem/Tokens/AppColors.swift
enum AppColors {
    static let secondary = Color.adaptive(light: "5856D6", dark: "5E5CE6")
    static let accent = Color.adaptive(light: "FF9500", dark: "FF9F0A")
    static let primary = Color(.systemBlue)

    static let success = Color.adaptive(light: "34C759", dark: "30D158")
    static let warning = Color.adaptive(light: "FFCC00", dark: "FFD60A")
    static let error = Color(.systemRed)

    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let cardBackground = Color(.secondarySystemBackground)

    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    static let cardBorder = Color(.separator)
    static let divider = Color(.separator)
    static let shadowColor = Color(.label)
}
```

- Surfaces, text and borders use semantic system colors, and `primary` and `error` use system colors. They adapt to Light, Dark, elevated and Increase Contrast with no extra work, so reach for them first.
- Brand and status colors with no system equivalent are defined in code with `Color.adaptive(light:dark:)` (`Core/Common/Extensions/ColorHex.swift`), which resolves one hex value for Light and one for Dark. This is what the generator emits.
- **Code or asset catalog**: `Color.adaptive` only knows Light and Dark. When a custom color needs high-contrast variants, create a Color Set in `Resources/Assets.xcassets` (Any, Dark and their High Contrast appearances; the project already ships one, `AccentColor`) and point the same `AppColors` member at it: `static let accent = Color("BrandAccent")`. Views do not change, because they only see the token.
- No `Color(hex:)`, `Color.black` or `Color.white` in a View: a literal has no Dark Mode variant and escapes the token audit.
- No in-app Dark Mode selector. The app follows the system appearance; a second setting makes users configure the same thing twice.

### AppTypography

An enum of semantic text styles (`AppTypography.swift`). Its `font` property maps each case to a Dynamic Type style, never to a fixed size: `largeTitle`, `title1` (`.title`), `title2`, `title3`, `headline`, `body`, `callout`, `subheadline`, `footnote`, `caption1` (`.caption`), `caption2`.

```swift
Text(error.title)
    .font(AppTypography.title2.font)
```

No `.font(.system(size: 16))`: a fixed size ignores the user's text size. When a number is unavoidable (an icon), scale it with `@ScaledMetric`, as `IconType.image(size:color:)` does in `AppIcons.swift`.

### Spacing

```swift
// Core/DesignSystem/Tokens/Spacing.swift
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

`Spacing.md` is the default padding of generated screens. Use the scale for `padding` and stack `spacing`; no numeric literals in Views. The same folder holds `IconSize` (`sm` 16, `md` 24, `lg` 32, `xl` 48) and `AppIcons` (typed SF Symbols and `IconType`).

## Shared Components

| Path | Contents |
|---|---|
| `Core/Common/SwiftUI/Components/` | `ErrorView` (takes an `ErrorDecorator`), `LoadingStateView` |
| `Core/Common/SwiftUI/Modifiers/` | `.primaryButtonStyle(isEnabled:)`, `.customListRow(top:leading:bottom:trailing:)` |
| `Core/Common/SwiftUI/Builders/` | `.if(_:transform:)` |

A view or modifier used by two or more features goes here and reads only tokens. A subview used by one screen stays in `Features/<Feature>/UI/Components/`. Prefer system button styles (`.borderedProminent`, `.bordered`, `role: .destructive`) and `.primaryButtonStyle()` over one-off styling.

## Rules for Views

- Interactive elements have a hit area of at least 44x44 pt (`.frame(minWidth: 44, minHeight: 44)`, or `.contentShape` on a larger frame). Smaller targets get missed.
- Text contrast is at least 4.5:1, or 3:1 for large text. Semantic colors already meet it; check every custom pair in Light and Dark.
- Layouts hold up to the accessibility Dynamic Type sizes without truncation: let text wrap and change the layout instead of shrinking fonts.
- Icon-only buttons carry an `.accessibilityLabel`, decorative images are `.accessibilityHidden(true)`, and meaning is never conveyed by color alone.
- Accessibility identifiers for UI tests are covered in `ui-testing.md`.

## Adaptive Layout

Do not branch with `if sizeClass == .compact { VStack } else { HStack }`. The `if` destroys and recreates the children, so scroll position, focus and text being typed are lost, and the size class alone does not describe a narrow window on iPad. Let the layout adapt:

```swift
ViewThatFits {
    HStack { title; actions }
    VStack(alignment: .leading) { title; actions }
}
```

`ViewThatFits` shows the first variant that fits. When the switch must animate or follows a condition (size class, `dynamicTypeSize.isAccessibilitySize`), choose between `AnyLayout(HStackLayout())` and `AnyLayout(VStackLayout())` and keep a single content closure.

## Liquid Glass (iOS 26+)

- Standard bars and controls adopt Liquid Glass on iOS 26 and later as soon as the app is built with the iOS 26 SDK or a newer one; they need no code. Do not plan around the `UIDesignRequiresCompatibility` opt-out: an app built with the iOS 27 SDK ignores it on iOS 27.
- Glass belongs to controls and the navigation layer: toolbars, floating buttons, custom bars over content. Never put it on content; list rows, cards and section backgrounds keep their color or material.
- API: `.glassEffect()` (or `.glassEffect(.regular, in: shape)`), `GlassEffectContainer { }` around glass elements that sit close together, and `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` for buttons.
- An existing material is not converted for you: `.background(.regularMaterial)` stays a material until you replace it.
- With a deployment target below iOS 26 (the generator defaults to iOS 18), gate every glass call and keep a designed fallback:

```swift
if #available(iOS 26, *) {
    content.glassEffect(.regular, in: .rect(cornerRadius: 16))
} else {
    content.background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
}
```

## Before Release

- [ ] Light and Dark Mode, plus Increase Contrast.
- [ ] Smallest and largest Dynamic Type sizes: nothing truncated, nothing overlapping.
- [ ] Every interactive element is reachable and labelled with VoiceOver.
- [ ] No hex colors, fixed font sizes or numeric paddings outside `Core/DesignSystem/Tokens/`.
- [ ] iOS 26 and the oldest supported iOS: glass and its fallback both look intended.

Deeper reference (Axiom plugin, if installed): `axiom-design` (HIG, Liquid Glass, typography, SF Symbols), `axiom-accessibility` (VoiceOver, Dynamic Type, contrast), `axiom-swiftui` (adaptive layout).
