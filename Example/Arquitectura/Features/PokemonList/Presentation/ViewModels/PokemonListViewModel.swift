import Foundation
import os

// MARK: - PokemonListViewModel

/// ViewModel for the PokemonList screen with infinite scroll pagination
@MainActor
@Observable
final class PokemonListViewModel {
    // MARK: - Static

    private nonisolated static let logger = Logger(subsystem: "com.magnos.Arquitectura",
                                                   category: "PokemonListViewModel")

    // MARK: - Properties

    private(set) var state: PokemonListState = .idle
    private(set) var isLoadingMore = false
    private(set) var paginationError: ErrorDecorator?

    private let useCase: PokemonListUseCase
    private let decoratorMapper: PokemonListDecoratorMapper
    private let router: PokemonListRouter
    private let pageSize = 20

    private var currentPage = 0
    private var hasMore = true
    private var allItems: [PokemonListItemDecorator] = []

    // MARK: - Init

    init(useCase: PokemonListUseCase,
         decoratorMapper: PokemonListDecoratorMapper,
         router: PokemonListRouter) {
        self.useCase = useCase
        self.decoratorMapper = decoratorMapper
        self.router = router
    }

    // MARK: - Public Methods

    /// Loads the initial page of Pokemon
    func loadPokemon() async {
        switch state {
        case .loading, .loaded: return
        case .idle, .error: break
        }

        let previousState = state
        state = .loading
        currentPage = 0
        hasMore = true
        allItems = []

        do {
            let result = try await useCase.execute(page: 0, pageSize: pageSize)
            let items = decoratorMapper.mapToItems(result.pokemon)
            allItems = items
            hasMore = result.hasMore
            currentPage = 1
            state = .loaded(items)
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }

    /// Loads the next page of Pokemon for infinite scroll
    func loadMore() async {
        guard !isLoadingMore, hasMore, case .loaded = state else { return }

        isLoadingMore = true
        paginationError = nil

        do {
            let result = try await useCase.execute(page: currentPage, pageSize: pageSize)
            let newItems = decoratorMapper.mapToItems(result.pokemon)
            allItems.append(contentsOf: newItems)
            hasMore = result.hasMore
            currentPage += 1
            state = .loaded(allItems)
        } catch is CancellationError {
        } catch let error as DomainError {
            Self.logger.error("Pagination failed at page \(self.currentPage): \(error)")
            paginationError = ErrorDecorator.from(error)
        } catch {
            Self.logger.error("Pagination failed at page \(self.currentPage): \(error.localizedDescription)")
            paginationError = .generic
        }

        isLoadingMore = false
    }

    /// Dismisses the pagination error banner
    func dismissPaginationError() {
        paginationError = nil
    }

    /// Notifies the ViewModel that an item has appeared in the list.
    /// Triggers pagination when the last loaded item becomes visible.
    /// - Parameter pokemonId: The numeric ID of the appeared Pokemon
    func onItemAppeared(pokemonId: Int) async {
        guard pokemonId == allItems.last?.numericId, hasMore, !isLoadingMore else { return }
        await loadMore()
    }

    /// Navigates to the detail view for a specific Pokemon
    /// - Parameter pokemonId: The unique identifier of the Pokemon
    func navigateToDetail(pokemonId: Int) {
        router.navigateToDetail(pokemonId: pokemonId)
    }
}
