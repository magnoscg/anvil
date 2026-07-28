import SwiftUI

// MARK: - PokemonDetailHeaderView

/// Hero header with Pokemon artwork, animated entrance, name, ID, genus, and type badges
struct PokemonDetailHeaderView: View {
    // MARK: - Properties

    let decorator: PokemonDetailPageDecorator

    @ScaledMetric(relativeTo: .body)
    private var imageSize: CGFloat = 280

    @State
    private var imageLoaded = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.zero) {
            pokemonImage
                .padding(.top, Spacing.xl)
            nameBlock
                .padding(.top, Spacing.sm)
            typeBadges
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.lg)
        }
    }
}

// MARK: - Private Views

private extension PokemonDetailHeaderView {
    var primaryColor: Color {
        decorator.primaryTypeColor?.uiColor ?? AppColors.primary
    }

    var pokemonImage: some View {
        AsyncImage(url: decorator.imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: imageSize, height: imageSize)
                    .accessibilityLabel(String(localized: "pokemonDetail.image.loading"))

            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize, height: imageSize)
                    .shadow(color: primaryColor.opacity(0.6), radius: 32, x: 0, y: 16)
                    .scaleEffect(imageLoaded ? 1.0 : 0.7)
                    .opacity(imageLoaded ? 1.0 : 0)
                    .onAppear {
                        if reduceMotion {
                            imageLoaded = true
                        } else {
                            withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
                                imageLoaded = true
                            }
                        }
                    }
                    .accessibilityLabel(String(localized: "pokemonDetail.header.artworkLabel \(decorator.name)"))

            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: imageSize, height: imageSize)
                    .accessibilityLabel(String(localized: "pokemonDetail.image.unavailable"))

            @unknown default:
                EmptyView()
                    .frame(width: imageSize, height: imageSize)
            }
        }
    }

    var nameBlock: some View {
        VStack(spacing: Spacing.xs) {
            Text(decorator.name)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.text)

            HStack(spacing: Spacing.sm) {
                Text(decorator.formattedId)
                    .font(AppTypography.subheadline.font)
                    .foregroundStyle(AppColors.textSecondary)

                if let genus = decorator.genus {
                    Text("·")
                        .foregroundStyle(AppColors.textTertiary)
                    Text(genus)
                        .font(AppTypography.subheadline.font)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    var typeBadges: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(decorator.types) { type in
                HStack(spacing: Spacing.xs) {
                    Image(systemName: type.typeColor.sfSymbolName)
                        .font(.caption2.weight(.semibold))

                    Text(type.name)
                        .font(AppTypography.caption1.font.weight(.semibold))
                }
                .foregroundStyle(type.typeColor.foregroundColor)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(type.typeColor.uiColor)
                .clipShape(Capsule())
                .shadow(color: type.typeColor.uiColor.opacity(0.5), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PokemonDetailHeaderView(decorator: PokemonDetailPageDecorator(id: "25",
                                                                  name: "Pikachu",
                                                                  formattedId: "#025",
                                                                  imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"),
                                                                  types: [PokemonTypeDecorator(id: "electric",
                                                                                               name: "Electric",
                                                                                               typeColor: .electric)],
                                                                  genus: "Mouse Pokémon",
                                                                  description: "A Pokemon description.",
                                                                  height: "0.4 m",
                                                                  weight: "6.0 kg",
                                                                  abilities: [],
                                                                  stats: []))
}
