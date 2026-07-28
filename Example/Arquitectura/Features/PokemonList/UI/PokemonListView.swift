import SwiftUI

// MARK: - PokemonListView

struct PokemonListView: View {
    // MARK: - Properties

    @State
    private var viewModel: PokemonListViewModel

    @State
    private var retryTrigger = false

    @State
    private var paginationRetryTrigger = 0

    // MARK: - Init

    init(viewModel: PokemonListViewModel) {
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

            case let .loaded(items):
                loadedView(items: items)

            case let .error(error):
                errorView(error: error)
            }
        }
        .navigationTitle(String(localized: "pokemonList.title"))
        .navigationBarTitleDisplayMode(.large)
        .background(AppColors.background)
        .task(id: retryTrigger) {
            await viewModel.loadPokemon()
        }
    }
}

// MARK: - Private Views

private extension PokemonListView {
    var loadingView: some View {
        LoadingStateView()
    }

    func loadedView(items: [PokemonListItemDecorator]) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(items) { pokemon in
                    Button {
                        viewModel.navigateToDetail(pokemonId: pokemon.numericId)
                    } label: {
                        PokemonListCardView(pokemon: pokemon)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(String(localized: "pokemonList.card.accessibilityHint"))
                    .padding(.horizontal, Spacing.md)
                    .task(id: pokemon.numericId) {
                        await viewModel.onItemAppeared(pokemonId: pokemon.numericId)
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(Spacing.md)
                        .accessibilityLabel(String(localized: "pokemonList.loadingMore"))
                }

                if let paginationError = viewModel.paginationError {
                    paginationErrorBanner(error: paginationError)
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .background(AppColors.background)
    }

    func paginationErrorBanner(error: ErrorDecorator) -> some View {
        VStack(spacing: Spacing.sm) {
            Text(error.message)
                .font(AppTypography.footnote.font)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(String(localized: "error.button.retry")) {
                paginationRetryTrigger += 1
            }
            .font(AppTypography.footnote.font)
        }
        .padding(Spacing.md)
        .task(id: paginationRetryTrigger) {
            guard paginationRetryTrigger > 0 else { return }
            await viewModel.loadMore()
        }
    }

    func errorView(error: ErrorDecorator) -> some View {
        ErrorView(error: error) {
            retryTrigger.toggle()
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        PokemonListView(viewModel: PokemonListViewModel(useCase: PreviewPokemonListUseCase(),
                                                        decoratorMapper: PokemonListDecoratorMapperImpl(),
                                                        router: PreviewPokemonListRouter()))
    }
}

#Preview("Loading") {
    NavigationStack {
        PokemonListView(viewModel: PokemonListViewModel(useCase: PreviewPokemonListLoadingUseCase(),
                                                        decoratorMapper: PokemonListDecoratorMapperImpl(),
                                                        router: PreviewPokemonListRouter()))
    }
}

#Preview("Error") {
    NavigationStack {
        PokemonListView(viewModel: PokemonListViewModel(useCase: PreviewPokemonListErrorUseCase(),
                                                        decoratorMapper: PokemonListDecoratorMapperImpl(),
                                                        router: PreviewPokemonListRouter()))
    }
}

// MARK: - Preview Helpers

private struct PreviewPokemonListUseCase: PokemonListUseCase {
    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult {
        PokemonListResult(pokemon: [PokemonListModel(id: 1,
                                                     name: "bulbasaur",
                                                     imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png"),
                                                     types: [.grass, .poison]),
                                    PokemonListModel(id: 4,
                                                     name: "charmander",
                                                     imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png"),
                                                     types: [.fire]),
                                    PokemonListModel(id: 7,
                                                     name: "squirtle",
                                                     imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png"),
                                                     types: [.water]),
                                    PokemonListModel(id: 25,
                                                     name: "pikachu",
                                                     imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"),
                                                     types: [.electric])],
                          hasMore: true,
                          totalCount: 1302)
    }
}

private struct PreviewPokemonListLoadingUseCase: PokemonListUseCase {
    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult {
        try await Task.sleep(for: .seconds(60))
        return PokemonListResult(pokemon: [], hasMore: false, totalCount: 0)
    }
}

private struct PreviewPokemonListErrorUseCase: PokemonListUseCase {
    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult {
        throw DomainError.network
    }
}

@MainActor
private struct PreviewPokemonListRouter: PokemonListRouter {
    func navigateToDetail(pokemonId: Int) {}
    func goBack() {}
}
