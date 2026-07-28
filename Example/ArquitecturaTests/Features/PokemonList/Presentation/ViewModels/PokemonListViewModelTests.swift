import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListViewModelTests

@Suite
@MainActor
struct PokemonListViewModelTests {
    // MARK: - Helpers

    private func makeSUT(useCase: MockPokemonListUseCase = MockPokemonListUseCase(),
                         mapper: PokemonListDecoratorMapper = PokemonListDecoratorMapperImpl(),
                         router: MockPokemonListRouter? = nil)
        -> (PokemonListViewModel,
            MockPokemonListUseCase,
            MockPokemonListRouter) {
        let resolvedRouter = router ?? MockPokemonListRouter()
        let viewModel = PokemonListViewModel(useCase: useCase,
                                             decoratorMapper: mapper,
                                             router: resolvedRouter)
        return (viewModel, useCase, resolvedRouter)
    }

    private func makePokemonResult(count: Int = 3,
                                   hasMore: Bool = true,
                                   totalCount: Int = 1302) -> PokemonListResult {
        let pokemon = (1 ... count).map { index in
            PokemonListModel(id: index,
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
    func loadPokemonTransitionsToLoaded() async {
        let mockUseCase = MockPokemonListUseCase()
        let result = makePokemonResult(count: 3)
        await mockUseCase.setExecuteResult(.success(result))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        guard case let .loaded(items) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state, got \(viewModel.state)")
            return
        }
        #expect(items.count == 3)
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }

    @Test("loadPokemon transitions to error state on failure")
    func loadPokemonTransitionsToError() async {
        let mockUseCase = MockPokemonListUseCase()
        await mockUseCase.setExecuteResult(.failure(DomainError.network))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        guard case let .error(decorator) = viewModel.state else {
            #expect(Bool(false), "Expected error state, got \(viewModel.state)")
            return
        }
        #expect(decorator == ErrorDecorator.network)
    }

    @Test("loadPokemon restores previous state on CancellationError")
    func loadPokemonRestoresPreviousStateOnCancellation() async {
        let mockUseCase = MockPokemonListUseCase()
        await mockUseCase.setExecuteResult(.failure(CancellationError()))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        #expect(viewModel.state == .idle)
    }

    @Test("loadPokemon skips reload when state is already loaded")
    func loadPokemonSkipsReloadWhenAlreadyLoaded() async {
        let mockUseCase = MockPokemonListUseCase()
        let result = makePokemonResult(count: 3)
        await mockUseCase.setExecuteResult(.success(result))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        guard case let .loaded(items) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state")
            return
        }
        #expect(items.count == 3)
        let callCountAfterFirstLoad = await mockUseCase.executeCallCount
        #expect(callCountAfterFirstLoad == 1)

        // Second call should be a no-op (simulates .task re-firing on navigation back)
        await viewModel.loadPokemon()

        let callCountAfterSecondLoad = await mockUseCase.executeCallCount
        #expect(callCountAfterSecondLoad == 1)

        guard case let .loaded(itemsAfter) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state preserved")
            return
        }
        #expect(itemsAfter.count == 3)
    }

    @Test("Double loadPokemon does not trigger duplicate fetch")
    func doubleLoadPokemonDoesNotDuplicateFetch() async {
        let mockUseCase = MockPokemonListUseCase()
        await mockUseCase.setExecuteResult(.success(makePokemonResult()))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        async let first: () = viewModel.loadPokemon()
        async let second: () = viewModel.loadPokemon()
        _ = await (first, second)

        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 1)
    }

    @Test("loadMore appends items and increments page")
    func loadMoreAppendsItems() async {
        let mockUseCase = MockPokemonListUseCase()
        let initialResult = makePokemonResult(count: 2, hasMore: true)
        await mockUseCase.setExecuteResult(.success(initialResult))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()

        let nextPageResult = PokemonListResult(pokemon: [PokemonListModel(id: 10,
                                                                          name: "caterpie",
                                                                          imageURL: URL(string: "https://example.com/10.png"),
                                                                          types: [.bug])],
                                               hasMore: false,
                                               totalCount: 1302)
        await mockUseCase.setExecuteResult(.success(nextPageResult))

        await viewModel.loadMore()

        guard case let .loaded(items) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state")
            return
        }
        #expect(items.count == 3)
        let lastPage = await mockUseCase.lastPage
        #expect(lastPage == 1)
    }

    @Test("loadMore does nothing when hasMore is false")
    func loadMoreDoesNothingWhenNoMore() async {
        let mockUseCase = MockPokemonListUseCase()
        let result = makePokemonResult(count: 2, hasMore: false)
        await mockUseCase.setExecuteResult(.success(result))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()
        let callCountAfterLoad = await mockUseCase.executeCallCount

        await viewModel.loadMore()

        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == callCountAfterLoad)
    }

    // MARK: - onItemAppeared Tests

    @Test("onItemAppeared triggers loadMore when last item appears")
    func onItemAppearedTriggersLoadMore() async {
        let mockUseCase = MockPokemonListUseCase()
        let result = makePokemonResult(count: 3, hasMore: true)
        await mockUseCase.setExecuteResult(.success(result))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()
        let callCountAfterLoad = await mockUseCase.executeCallCount

        let nextResult = PokemonListResult(pokemon: [PokemonListModel(id: 10,
                                                                      name: "caterpie",
                                                                      imageURL: nil,
                                                                      types: [.bug])],
                                           hasMore: false,
                                           totalCount: 4)
        await mockUseCase.setExecuteResult(.success(nextResult))

        await viewModel.onItemAppeared(pokemonId: 3)

        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == callCountAfterLoad + 1)
    }

    @Test("onItemAppeared does not trigger loadMore for non-last item")
    func onItemAppearedIgnoresNonLastItem() async {
        let mockUseCase = MockPokemonListUseCase()
        let result = makePokemonResult(count: 3, hasMore: true)
        await mockUseCase.setExecuteResult(.success(result))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()
        let callCountAfterLoad = await mockUseCase.executeCallCount

        await viewModel.onItemAppeared(pokemonId: 1)

        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == callCountAfterLoad)
    }

    @Test("onItemAppeared does not trigger loadMore when hasMore is false")
    func onItemAppearedIgnoresWhenNoMore() async {
        let mockUseCase = MockPokemonListUseCase()
        let result = makePokemonResult(count: 3, hasMore: false)
        await mockUseCase.setExecuteResult(.success(result))
        let (viewModel, _, _) = makeSUT(useCase: mockUseCase)

        await viewModel.loadPokemon()
        let callCountAfterLoad = await mockUseCase.executeCallCount

        await viewModel.onItemAppeared(pokemonId: 3)

        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == callCountAfterLoad)
    }

    @Test("navigateToDetail calls router with correct pokemonId")
    func navigateToDetailCallsRouter() {
        let mockRouter = MockPokemonListRouter()
        let (viewModel, _, _) = makeSUT(router: mockRouter)

        viewModel.navigateToDetail(pokemonId: 25)

        #expect(mockRouter.navigateToDetailCallCount == 1)
        #expect(mockRouter.lastNavigatedPokemonId == 25)
    }
}
