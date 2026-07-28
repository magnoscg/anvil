import SwiftUI

// MARK: - PokemonDetailStatsView

/// Base stats section displaying animated stat bars with sequential entrance and type-colored gradients
struct PokemonDetailStatsView: View {
    // MARK: - Properties

    let decorator: PokemonDetailPageDecorator

    @State
    private var animatedStats: Set<String> = []

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(decorator.stats.enumerated()), id: \.element.id) { index, stat in
                statRow(stat, index: index)
            }

            Divider()
                .padding(.vertical, Spacing.xs)

            bstRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .task {
            await animateSequentially()
        }
    }
}

// MARK: - Private Views

private extension PokemonDetailStatsView {
    var typeColor: Color {
        decorator.primaryTypeColor?.uiColor ?? AppColors.primary
    }

    func statRow(_ stat: PokemonStatDecorator, index: Int) -> some View {
        let isAnimated = animatedStats.contains(stat.id)

        return HStack(spacing: Spacing.md) {
            Text(stat.name)
                .font(AppTypography.caption1.font)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 40, alignment: .trailing)

            Text("\(stat.value)")
                .font(AppTypography.body.font.monospacedDigit())
                .foregroundStyle(AppColors.text)
                .frame(width: 36, alignment: .trailing)

            animatedStatBar(progress: stat.progress, isAnimated: isAnimated)
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stat.name)
        .accessibilityValue(String(localized: "pokemonDetail.stats.accessibility.value \(stat.value)"))
    }

    var bstRow: some View {
        let bstProgress = Double(decorator.baseStatTotal) / 720.0
        let isAnimated = animatedStats.contains("bst")

        return HStack(spacing: Spacing.md) {
            Text(String(localized: "pokemonDetail.stats.bst"))
                .font(AppTypography.caption1.font.weight(.bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 40, alignment: .trailing)

            Text("\(decorator.baseStatTotal)")
                .font(AppTypography.body.font.weight(.bold).monospacedDigit())
                .foregroundStyle(AppColors.text)
                .frame(width: 36, alignment: .trailing)

            animatedStatBar(progress: bstProgress, isAnimated: isAnimated, isBst: true)
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "pokemonDetail.stats.bst.accessibility"))
        .accessibilityValue("\(decorator.baseStatTotal)")
    }

    func animatedStatBar(progress: Double, isAnimated: Bool, isBst: Bool = false) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.cardBorder.opacity(0.3))

                Capsule()
                    .fill(
                        isBst
                        ? LinearGradient(
                            colors: [typeColor.opacity(0.5), typeColor, typeColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                        : LinearGradient(
                            colors: [typeColor.opacity(0.6), typeColor],
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .frame(width: max(0, geometry.size.width * (isAnimated ? progress : 0)))
            }
        }
        .frame(height: isBst ? 10 : 8)
        .accessibilityHidden(true)
    }

    func animateSequentially() async {
        let allIds = decorator.stats.map(\.id) + ["bst"]

        if reduceMotion {
            animatedStats = Set(allIds)
            return
        }

        for (index, id) in allIds.enumerated() {
            let delay = Double(index) * 0.07
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                _ = animatedStats.insert(id)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PokemonDetailStatsView(decorator: PokemonDetailPageDecorator(id: "25",
                                                                 name: "Pikachu",
                                                                 formattedId: "#025",
                                                                 imageURL: nil,
                                                                 types: [PokemonTypeDecorator(id: "electric",
                                                                                              name: "Electric",
                                                                                              typeColor: .electric)],
                                                                 genus: "Mouse Pokémon",
                                                                 description: "A Pokemon description.",
                                                                 height: "0.4 m",
                                                                 weight: "6.0 kg",
                                                                 abilities: [],
                                                                 stats: [PokemonStatDecorator(id: "hp", name: "HP",
                                                                                              value: 35,
                                                                                              progress: 35.0 / 255.0),
                                                                         PokemonStatDecorator(id: "attack", name: "ATK",
                                                                                              value: 55,
                                                                                              progress: 55.0 / 255.0),
                                                                         PokemonStatDecorator(id: "defense",
                                                                                              name: "DEF", value: 40,
                                                                                              progress: 40.0 / 255.0),
                                                                         PokemonStatDecorator(id: "special-attack",
                                                                                              name: "SpA", value: 50,
                                                                                              progress: 50.0 / 255.0),
                                                                         PokemonStatDecorator(id: "special-defense",
                                                                                              name: "SpD", value: 50,
                                                                                              progress: 50.0 / 255.0),
                                                                         PokemonStatDecorator(id: "speed", name: "SPD",
                                                                                              value: 90,
                                                                                              progress: 90.0 / 255.0)]))
        .padding()
}
