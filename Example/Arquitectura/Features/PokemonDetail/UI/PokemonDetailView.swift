import SwiftUI
import UIKit

// MARK: - PokemonDetailView

struct PokemonDetailView: View {
    // MARK: - Properties

    @State
    private var viewModel: PokemonDetailViewModel

    @State
    private var retryTrigger = false

    @State
    private var selectedTab: DetailTab = .about

    // MARK: - Init

    init(viewModel: PokemonDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear

            case .loading:
                loadingView

            case let .loaded(decorator):
                loadedView(decorator: decorator)

            case let .error(error):
                errorView(error: error)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
        .task(id: retryTrigger) {
            await viewModel.loadDetail()
        }
    }
}

// MARK: - Private Views

private extension PokemonDetailView {
    var loadingView: some View {
        LoadingStateView()
    }

    func loadedView(decorator: PokemonDetailPageDecorator) -> some View {
        let typeColor = decorator.primaryTypeColor?.uiColor ?? AppColors.primary

        return ScrollView {
            LazyVStack(spacing: Spacing.zero) {
                PokemonDetailHeaderView(decorator: decorator)
                    .staggeredAppear(delay: 0.0, offset: 10)

                tabSelector(decorator: decorator)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .staggeredAppear(delay: 0.15)

                tabContent(decorator: decorator)
                    .staggeredAppear(delay: 0.25)
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(
            ZStack(alignment: .top) {
                AppColors.background
                    .ignoresSafeArea()
                LinearGradient(
                    colors: [typeColor.opacity(0.55), typeColor.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
                .ignoresSafeArea(edges: .top)
            }
        )
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func tabSelector(decorator: PokemonDetailPageDecorator) -> some View {
        let typeColor = decorator.primaryTypeColor?.uiColor ?? AppColors.primary

        return HStack(spacing: Spacing.zero) {
            ForEach(DetailTab.allCases) { tab in
                tabButton(tab: tab, typeColor: typeColor)
            }
        }
        .padding(Spacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func tabButton(tab: DetailTab, typeColor: Color) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tab
            }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.caption.weight(.semibold))
                Text(tab.title)
                    .font(AppTypography.subheadline.font.weight(.semibold))
            }
            .foregroundStyle(isSelected ? tab.foregroundColor(typeColor: typeColor) : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(typeColor)
                        .shadow(color: typeColor.opacity(0.4), radius: 6, x: 0, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3, bounce: 0.2), value: selectedTab)
    }

    @ViewBuilder
    func tabContent(decorator: PokemonDetailPageDecorator) -> some View {
        switch selectedTab {
        case .about:
            PokemonDetailAboutView(decorator: decorator)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(DetailTab.about)

        case .stats:
            PokemonDetailStatsView(decorator: decorator)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .id(DetailTab.stats)
        }
    }

    func errorView(error: ErrorDecorator) -> some View {
        ErrorView(error: error) {
            retryTrigger.toggle()
        }
    }
}

// MARK: - DetailTab

private enum DetailTab: String, CaseIterable, Identifiable {
    case about
    case stats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .about: String(localized: "pokemonDetail.about.title")
        case .stats: String(localized: "pokemonDetail.stats.title")
        }
    }

    var icon: String {
        switch self {
        case .about: "info.circle"
        case .stats: "chart.bar.fill"
        }
    }

    func foregroundColor(typeColor: Color) -> Color {
        .white
    }
}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        PokemonDetailView(viewModel: PokemonDetailViewModel(pokemonId: 25,
                                                            useCase: PreviewPokemonDetailUseCase(),
                                                            decoratorMapper: PokemonDetailDecoratorMapperImpl(),
                                                            router: PreviewPokemonDetailRouter()))
    }
}

#Preview("Loading") {
    NavigationStack {
        PokemonDetailView(viewModel: PokemonDetailViewModel(pokemonId: 25,
                                                            useCase: PreviewPokemonDetailLoadingUseCase(),
                                                            decoratorMapper: PokemonDetailDecoratorMapperImpl(),
                                                            router: PreviewPokemonDetailRouter()))
    }
}

#Preview("Error") {
    NavigationStack {
        PokemonDetailView(viewModel: PokemonDetailViewModel(pokemonId: 25,
                                                            useCase: PreviewPokemonDetailErrorUseCase(),
                                                            decoratorMapper: PokemonDetailDecoratorMapperImpl(),
                                                            router: PreviewPokemonDetailRouter()))
    }
}

// MARK: - Preview Helpers

private struct PreviewPokemonDetailUseCase: PokemonDetailUseCase {
    func execute(pokemonId: Int) async throws -> PokemonDetailModel {
        PokemonDetailModel(id: 25,
                           name: "Pikachu",
                           imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"),
                           types: [.electric],
                           height: 4,
                           weight: 60,
                           stats: [PokemonStatModel(name: "hp", baseStat: 35),
                                   PokemonStatModel(name: "attack", baseStat: 55),
                                   PokemonStatModel(name: "defense", baseStat: 40),
                                   PokemonStatModel(name: "special-attack", baseStat: 50),
                                   PokemonStatModel(name: "special-defense", baseStat: 50),
                                   PokemonStatModel(name: "speed", baseStat: 90)],
                           abilities: [PokemonAbilityModel(name: "static", isHidden: false),
                                       PokemonAbilityModel(name: "lightning-rod", isHidden: true)],
                           description: "When several of these POKéMON gather, their electricity could build and cause lightning storms.",
                           genus: "Mouse Pokémon")
    }
}

private struct PreviewPokemonDetailLoadingUseCase: PokemonDetailUseCase {
    func execute(pokemonId: Int) async throws -> PokemonDetailModel {
        try await Task.sleep(for: .seconds(60))
        throw CancellationError()
    }
}

private struct PreviewPokemonDetailErrorUseCase: PokemonDetailUseCase {
    func execute(pokemonId: Int) async throws -> PokemonDetailModel {
        throw DomainError.network
    }
}

@MainActor
private struct PreviewPokemonDetailRouter: PokemonDetailRouter {
    func goBack() {}
}
