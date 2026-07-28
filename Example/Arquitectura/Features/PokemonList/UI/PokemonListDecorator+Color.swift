import SwiftUI

// MARK: - PokemonTypeColor + UI Color

extension PokemonTypeColor {
    // MARK: - Properties

    /// Canonical Pokemon type color for UI display.
    var uiColor: Color {
        switch self {
        case .normal:
            Color(hex: "A8A77A")
        case .fire:
            Color(hex: "EE8130")
        case .water:
            Color(hex: "6390F0")
        case .grass:
            Color(hex: "7AC74C")
        case .electric:
            Color(hex: "F7D02C")
        case .ice:
            Color(hex: "96D9D6")
        case .fighting:
            Color(hex: "C22E28")
        case .poison:
            Color(hex: "A33EA1")
        case .ground:
            Color(hex: "E2BF65")
        case .flying:
            Color(hex: "A98FF3")
        case .psychic:
            Color(hex: "F95587")
        case .bug:
            Color(hex: "A6B91A")
        case .rock:
            Color(hex: "B6A136")
        case .ghost:
            Color(hex: "735797")
        case .dragon:
            Color(hex: "6F35FC")
        case .dark:
            Color(hex: "705746")
        case .steel:
            Color(hex: "B7B7CE")
        case .fairy:
            Color(hex: "D685AD")
        case .unknown:
            Color(hex: "68A090")
        }
    }

    // MARK: - SF Symbol

    /// SF Symbol name representing the Pokemon type
    var sfSymbolName: String {
        switch self {
        case .fire:
            "flame.fill"
        case .water:
            "drop.fill"
        case .grass:
            "leaf.fill"
        case .electric:
            "bolt.fill"
        case .ice:
            "snowflake"
        case .fighting:
            "figure.martial.arts"
        case .poison:
            "flask.fill"
        case .ground:
            "mountain.2.fill"
        case .flying:
            "wind"
        case .psychic:
            "brain.head.profile"
        case .bug:
            "ladybug.fill"
        case .rock:
            "mountain.fill"
        case .ghost:
            "moon.stars.fill"
        case .dragon:
            "sparkles"
        case .dark:
            "moon.fill"
        case .steel:
            "shield.fill"
        case .fairy:
            "sparkle"
        case .normal:
            "circle.fill"
        case .unknown:
            "questionmark.circle.fill"
        }
    }

    /// Accessible foreground color for text rendered on top of the badge color.
    var foregroundColor: Color {
        switch self {
        case .fire, .water, .dark, .dragon, .fighting, .ghost, .poison, .psychic:
            .white
        case .electric, .normal, .flying, .rock, .steel, .bug, .ground, .ice, .grass, .fairy, .unknown:
            .black
        }
    }
}
