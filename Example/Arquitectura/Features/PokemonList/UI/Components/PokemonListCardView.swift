import SwiftUI

// MARK: - PokemonListCardView

/// Card component for displaying a single Pokemon in the list
struct PokemonListCardView: View {
    // MARK: - Properties

    let pokemon: PokemonListItemDecorator

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            pokemonImage
            pokemonInfo
            Spacer()
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(AppColors.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pokemon.name), \(pokemon.types.map(\.name).joined(separator: ", "))")
    }
}

// MARK: - Private Views

private extension PokemonListCardView {
    var pokemonImage: some View {
        AsyncImage(url: pokemon.imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 80, height: 80)
                    .accessibilityLabel("Loading \(pokemon.name) image")

            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .accessibilityLabel("\(pokemon.name) artwork")

            case .failure:
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 80, height: 80)
                    .accessibilityLabel("Image failed to load for \(pokemon.name)")

            @unknown default:
                EmptyView()
                    .frame(width: 80, height: 80)
            }
        }
    }

    var pokemonInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(pokemon.name)
                .font(AppTypography.headline.font)
                .foregroundStyle(AppColors.text)

            typeBadges
        }
    }

    var typeBadges: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(pokemon.types) { type in
                Text(type.name)
                    .font(AppTypography.caption1.font)
                    .foregroundStyle(type.typeColor.foregroundColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(type.typeColor.uiColor)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PokemonListCardView(pokemon: PokemonListItemDecorator(id: "25",
                                                          numericId: 25,
                                                          name: "Pikachu",
                                                          imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"),
                                                          types: [PokemonTypeDecorator(id: "electric",
                                                                                       name: "Electric",
                                                                                       typeColor: .electric)]))
        .padding()
}
