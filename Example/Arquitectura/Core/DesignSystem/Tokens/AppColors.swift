import SwiftUI

// MARK: - AppColors

/// Design system color tokens with automatic light/dark mode adaptation.
/// Uses `Color.adaptive(light:dark:)` which resolves at render time via UIColor traits.
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

    // MARK: - Borders & Dividers

    static let cardBorder = Color.adaptive(light: "E5E5EA", dark: "38383A")
    static let divider = Color.adaptive(light: "C6C6C8", dark: "38383A")

    // MARK: - Code Display

    static let codeBackground = Color(hex: "1E1E2E")

    // MARK: - Gradients

    static let gradientStart = Color.adaptive(light: "007AFF", dark: "0A84FF")
    static let gradientEnd = Color.adaptive(light: "5856D6", dark: "5E5CE6")

    // MARK: - On-Surface (content on colored backgrounds)

    static let onGradient = Color(hex: "FFFFFF")
    static let onAccent = Color(hex: "FFFFFF")
    static let shadowColor = Color(hex: "000000")

    // MARK: - Splash Screen (intentionally fixed, always dark theme)

    static let swiftOrange = Color(hex: "F05138")
    static let swiftOrangeDark = Color(hex: "C73E2D")
    static let deepBlack = Color(hex: "0A0A0F")
    static let nightBlue = Color(hex: "0F1419")
    static let accentBlue = Color.adaptive(light: "1a237e", dark: "3949AB")
}
