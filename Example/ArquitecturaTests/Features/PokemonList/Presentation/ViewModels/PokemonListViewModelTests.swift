import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListViewModelTests

@Suite
@MainActor
struct PokemonListViewModelTests {
    // MARK: - Helpers

    private func makeSUT(useCase: PokemonListUseCaseMock = PokemonListUseCaseMock(),
                         mapper: PokemonListDecoratorMapper = PokemonListDecoratorMapperImpl(),
                         router: PokemonListRouterMock? = nil)
        -> (PokemonListViewModel,
            PokemonListUseCaseMock,
            PokemonListRouterMock) {
        let resolvedRouter = router ?? PokemonListRouterMock()
        let viewModel = PokemonListViewModel(useCase: useCase,
                                             decoratorMapper: mapper,
                                             router: resolvedRouter)
        return (viewModel, useCase, resolvedRouter)
    }

    private func makePokemonResult(count: Int = 3,
                                   hasMore: Bool = true,
                                   totalCount: Int = 1302) -> PokemonListResult {
        let pokemon = (1 ... count).map { index in
            PokemonSummaryModel(id: index,
                                name: "pokemon-\(index)",
                                imageURL: URL(string: "https://example.com/\(index).png"),
                                types: [.fire])
        }
        return PokemonListResult(pokemon: pokemon, hasMore: hasMore, totalCount: totalCount)
    }

    // MARK: - Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let (viewModel, _, _) = makeSUT()

        #expect(viewModel.state == .idle)
        #expect(viewModel.isLoadingMore == false)
    }

    @Test("loadPokemon transitions to loaded state with items")
    func loadPokemonTransitionsToLoaded() async throws {
        let mockUseCase = PokemonListUseCaseMock()
        let result = makePokemonResult(count: 3)
        mockUseCase.executeResult = .success(result)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        let items = try #require(viewModel.state.loadedItems)
        #expect(items.count == 3)
        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("loadPokemon transitions to error state on failure")
    func loadPokemonTransitionsToError() async {
        let mockUseCase = PokemonListUseCaseMock()
        mockUseCase.executeResult = .failure(DomainError.network)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        #expect(viewModel.state == .error(.network))
    }

    @Test("loadPokemon restores previous state on CancellationError")
    func loadPokemonRestoresPreviousStateOnCancellation() async {
        let mockUseCase = PokemonListUseCaseMock()
        mockUseCase.executeResult = .failure(CancellationError())
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        #expect(viewModel.state == .idle)
    }

    @Test("loadPokemon skips reload when state is already loaded")
    func loadPokemonSkipsReloadWhenAlreadyLoaded() async throws {
        let mockUseCase = PokemonListUseCaseMock()
        let result = makePokemonResult(count: 3)
        mockUseCase.executeResult = .success(result)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        await viewModel.loadPokemon()
        let items = try #require(viewModel.state.loadedItems)
        #expect(items.count == 3)
        #expect(mockUseCase.executeCallCount == 1)

        await viewModel.loadPokemon()

        #expect(mockUseCase.executeCallCount == 1)
        let itemsAfter = try #require(viewModel.state.loadedItems)
        #expect(itemsAfter.count == 3)
    }

    @Test("Double loadPokemon does not trigger duplicate fetch")
    func doubleLoadPokemonDoesNotDuplicateFetch() async {
        let mockUseCase = PokemonListUseCaseMock()
        mockUseCase.executeResult = .success(makePokemonResult())
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        mockUseCase.onExecute = { await viewModel.loadPokemon() }

        await viewModel.loadPokemon()

        #expect(mockUseCase.executeCallCount == 1)
    }

    @Test("loadMore appends items and increments page")
    func loadMoreAppendsItems() async throws {
        let mockUseCase = PokemonListUseCaseMock()
        let initialResult = makePokemonResult(count: 2, hasMore: true)
        mockUseCase.executeResult = .success(initialResult)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        await viewModel.loadPokemon()
        let nextPageResult = PokemonListResult(pokemon: [PokemonSummaryModel(id: 10,
                                                                             name: "caterpie",
                                                                             imageURL: URL(string: "https://example.com/10.png"),
                                                                             types: [.bug])],
                                               hasMore: false,
                                               totalCount: 1302)
        mockUseCase.executeResult = .success(nextPageResult)

        await viewModel.loadMore()

        let items = try #require(viewModel.state.loadedItems)
        #expect(items.count == 3)
        #expect(mockUseCase.lastPage == 1)
    }

    @Test("loadMore does nothing when hasMore is false")
    func loadMoreDoesNothingWhenNoMore() async {
        let mockUseCase = PokemonListUseCaseMock()
        let result = makePokemonResult(count: 2, hasMore: false)
        mockUseCase.executeResult = .success(result)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        await viewModel.loadPokemon()
        let callCountAfterLoad = mockUseCase.executeCallCount

        await viewModel.loadMore()

        #expect(mockUseCase.executeCallCount == callCountAfterLoad)
    }

    // MARK: - onItemAppeared Tests

    @Test("onItemAppeared triggers loadMore when last item appears")
    func onItemAppearedTriggersLoadMore() async {
        let mockUseCase = PokemonListUseCaseMock()
        let result = makePokemonResult(count: 3, hasMore: true)
        mockUseCase.executeResult = .success(result)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        await viewModel.loadPokemon()
        let callCountAfterLoad = mockUseCase.executeCallCount
        let nextResult = PokemonListResult(pokemon: [PokemonSummaryModel(id: 10,
                                                                         name: "caterpie",
                                                                         imageURL: nil,
                                                                         types: [.bug])],
                                           hasMore: false,
                                           totalCount: 4)
        mockUseCase.executeResult = .success(nextResult)

        await viewModel.onItemAppeared(pokemonId: 3)

        #expect(mockUseCase.executeCallCount == callCountAfterLoad + 1)
    }

    @Test("onItemAppeared does not trigger loadMore for non-last item")
    func onItemAppearedIgnoresNonLastItem() async {
        let mockUseCase = PokemonListUseCaseMock()
        let result = makePokemonResult(count: 3, hasMore: true)
        mockUseCase.executeResult = .success(result)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        await viewModel.loadPokemon()
        let callCountAfterLoad = mockUseCase.executeCallCount

        await viewModel.onItemAppeared(pokemonId: 1)

        #expect(mockUseCase.executeCallCount == callCountAfterLoad)
    }

    @Test("onItemAppeared does not trigger loadMore when hasMore is false")
    func onItemAppearedIgnoresWhenNoMore() async {
        let mockUseCase = PokemonListUseCaseMock()
        let result = makePokemonResult(count: 3, hasMore: false)
        mockUseCase.executeResult = .success(result)
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)
        await viewModel.loadPokemon()
        let callCountAfterLoad = mockUseCase.executeCallCount

        await viewModel.onItemAppeared(pokemonId: 3)

        #expect(mockUseCase.executeCallCount == callCountAfterLoad)
    }

    @Test("navigateToDetail calls router with correct pokemonId")
    func navigateToDetailCallsRouter() {
        let mockRouter = PokemonListRouterMock()
        let (viewModel, _, _) = makeSUT(router: mockRouter)

        viewModel.navigateToDetail(pokemonId: 25)

        #expect(mockRouter.navigateToDetailCallCount == 1)
        #expect(mockRouter.lastNavigatedPokemonId == 25)
    }
}

// MARK: - PokemonListState + Loaded items

private extension PokemonListState {
    var loadedItems: [PokemonListItemDecorator]? {
        if case let .loaded(items) = self {
            items
        } else {
            nil
        }
    }
}
