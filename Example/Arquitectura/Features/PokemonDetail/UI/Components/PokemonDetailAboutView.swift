import SwiftUI

// MARK: - PokemonDetailAboutView

/// About section displaying description, physical data, and abilities
struct PokemonDetailAboutView: View {
    // MARK: - Properties

    let decorator: PokemonDetailPageDecorator

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if let description = decorator.description {
                descriptionText(description)
            }

            physicalDataGrid
            abilitiesSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
    }
}

// MARK: - Private Views

private extension PokemonDetailAboutView {
    var typeColor: Color {
        decorator.primaryTypeColor?.uiColor ?? AppColors.textSecondary
    }

    func descriptionText(_ description: String) -> some View {
        Text(description)
            .font(AppTypography.body.font)
            .foregroundStyle(AppColors.text)
            .lineSpacing(4)
    }

    var physicalDataGrid: some View {
        HStack(spacing: Spacing.sm) {
            physicalDataCell(icon: "ruler",
                             label: String(localized: "pokemonDetail.about.height"),
                             value: decorator.height)

            Divider()
                .frame(height: 50)

            physicalDataCell(icon: "scalemass",
                             label: String(localized: "pokemonDetail.about.weight"),
                             value: decorator.weight)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func physicalDataCell(icon: String, label: String, value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(typeColor)

            Text(value)
                .font(AppTypography.headline.font)
                .foregroundStyle(AppColors.text)

            Text(label)
                .font(AppTypography.caption1.font)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    var abilitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "pokemonDetail.about.abilities"))
                .font(AppTypography.subheadline.font.weight(.semibold))
                .foregroundStyle(AppColors.text)

            VStack(spacing: Spacing.xs) {
                ForEach(decorator.abilities) { ability in
                    abilityRow(ability)
                }
            }
        }
    }

    func abilityRow(_ ability: PokemonAbilityDecorator) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: ability.isHidden ? "eye.slash" : "sparkle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ability.isHidden ? AppColors.textSecondary : typeColor)
                .frame(width: 20)

            Text(ability.name)
                .font(AppTypography.body.font)
                .foregroundStyle(AppColors.text)

            Spacer()

            if ability.isHidden {
                Text(String(localized: "pokemonDetail.about.hidden"))
                    .font(AppTypography.caption2.font)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.cardBorder.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(AppColors.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    PokemonDetailAboutView(decorator: PokemonDetailPageDecorator(id: "25",
                                                                 name: "Pikachu",
                                                                 formattedId: "#025",
                                                                 imageURL: nil,
                                                                 types: [PokemonTypeDecorator(id: "electric",
                                                                                              name: "Electric",
                                                                                              typeColor: .electric)],
                                                                 genus: "Mouse Pokémon",
                                                                 description: "When several of these POKéMON gather, their electricity could build and cause lightning storms.",
                                                                 height: "0.4 m",
                                                                 weight: "6.0 kg",
                                                                 abilities: [PokemonAbilityDecorator(id: "static",
                                                                                                     name: "Static",
                                                                                                     isHidden: false),
                                                                             PokemonAbilityDecorator(id: "lightning-rod",
                                                                                                     name: "Lightning Rod",
                                                                                                     isHidden: true)],
                                                                 stats: []))
        .padding()
}
