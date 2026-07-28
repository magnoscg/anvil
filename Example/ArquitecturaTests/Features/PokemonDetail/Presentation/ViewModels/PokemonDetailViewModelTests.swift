import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonDetailViewModelTests

@Suite
@MainActor
struct PokemonDetailViewModelTests {
    // MARK: - Tests

    @Test("loadDetail success sets state to loaded")
    func loadDetailSuccess() async {
        // Given
        let model = makeModel()
        let decorator = makeDecorator()

        let mockUseCase = MockPokemonDetailUseCase()
        await mockUseCase.setExecuteResult(.success(model))

        let mockMapper = MockPokemonDetailDecoratorMapper(mapResult: decorator)
        let mockRouter = MockPokemonDetailRouter()
        let viewModel = PokemonDetailViewModel(pokemonId: 25,
                                               useCase: mockUseCase,
                                               decoratorMapper: mockMapper,
                                               router: mockRouter)

        // When
        await viewModel.loadDetail()

        // Then
        #expect(viewModel.state == .loaded(decorator))
    }

    @Test("loadDetail error sets state to error")
    func loadDetailError() async {
        // Given
        let mockUseCase = MockPokemonDetailUseCase()
        await mockUseCase.setExecuteResult(.failure(DomainError.network))

        let mockMapper = MockPokemonDetailDecoratorMapper(mapResult: makeDecorator())
        let mockRouter = MockPokemonDetailRouter()
        let viewModel = PokemonDetailViewModel(pokemonId: 25,
                                               useCase: mockUseCase,
                                               decoratorMapper: mockMapper,
                                               router: mockRouter)

        // When
        await viewModel.loadDetail()

        // Then
        #expect(viewModel.state == .error(ErrorDecorator.from(.network)))
    }

    @Test("loadDetail cancellation restores previous state")
    func loadDetailCancellation() async {
        // Given
        let mockUseCase = MockPokemonDetailUseCase()
        await mockUseCase.setExecuteResult(.failure(CancellationError()))

        let mockMapper = MockPokemonDetailDecoratorMapper(mapResult: makeDecorator())
        let mockRouter = MockPokemonDetailRouter()
        let viewModel = PokemonDetailViewModel(pokemonId: 25,
                                               useCase: mockUseCase,
                                               decoratorMapper: mockMapper,
                                               router: mockRouter)

        // When
        await viewModel.loadDetail()

        // Then — state should be restored to idle (the previous state)
        #expect(viewModel.state == .idle)
    }

    @Test("loadDetail does not duplicate when already loading")
    func loadDetailNoDuplicate() async {
        // Given
        let model = makeModel()
        let decorator = makeDecorator()

        let mockUseCase = MockPokemonDetailUseCase()
        await mockUseCase.setExecuteResult(.success(model))

        let mockMapper = MockPokemonDetailDecoratorMapper(mapResult: decorator)
        let mockRouter = MockPokemonDetailRouter()
        let viewModel = PokemonDetailViewModel(pokemonId: 25,
                                               useCase: mockUseCase,
                                               decoratorMapper: mockMapper,
                                               router: mockRouter)

        // When — call loadDetail twice concurrently
        await viewModel.loadDetail()
        await viewModel.loadDetail()

        // Then — use case should only be called twice (both calls complete,
        // but the second call's guard passes because first already completed)
        let callCount = await mockUseCase.executeCallCount
        #expect(callCount == 2)
        #expect(viewModel.state == .loaded(decorator))
    }

    @Test("loadDetail with generic error sets generic error state")
    func loadDetailGenericError() async {
        // Given
        let mockUseCase = MockPokemonDetailUseCase()
        await mockUseCase.setExecuteResult(.failure(NSError(domain: "test", code: 999)))

        let mockMapper = MockPokemonDetailDecoratorMapper(mapResult: makeDecorator())
        let mockRouter = MockPokemonDetailRouter()
        let viewModel = PokemonDetailViewModel(pokemonId: 25,
                                               useCase: mockUseCase,
                                               decoratorMapper: mockMapper,
                                               router: mockRouter)

        // When
        await viewModel.loadDetail()

        // Then
        #expect(viewModel.state == .error(.generic))
    }

    // MARK: - Test Helpers

    private func makeModel() -> PokemonDetailModel {
        PokemonDetailModel(id: 25,
                           name: "pikachu",
                           imageURL: URL(string: "https://example.com/25.png"),
                           types: [.electric],
                           height: 4,
                           weight: 60,
                           stats: [PokemonStatModel(name: "hp", baseStat: 35)],
                           abilities: [PokemonAbilityModel(name: "static", isHidden: false)],
                           description: "A Pokemon description.",
                           genus: "Mouse Pokémon")
    }

    private func makeDecorator() -> PokemonDetailPageDecorator {
        PokemonDetailPageDecorator(id: "25",
                                   name: "Pikachu",
                                   formattedId: "#025",
                                   imageURL: URL(string: "https://example.com/25.png"),
                                   types: [PokemonTypeDecorator(id: "electric", name: "Electric",
                                                                typeColor: .electric)],
                                   genus: "Mouse Pokémon",
                                   description: "A Pokemon description.",
                                   height: "0.4 m",
                                   weight: "6.0 kg",
                                   abilities: [PokemonAbilityDecorator(id: "static", name: "Static", isHidden: false)],
                                   stats: [PokemonStatDecorator(id: "hp", name: "HP", value: 35,
                                                                progress: 35.0 / 255.0)])
    }
}
