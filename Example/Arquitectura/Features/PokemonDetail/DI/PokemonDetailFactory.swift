import Foundation

// MARK: - PokemonDetailFactory

/// Factory for creating PokemonDetail feature components with proper dependency injection
@MainActor
enum PokemonDetailFactory {
    // MARK: - Public Methods

    /// Creates the PokemonDetail view with all dependencies injected
    /// - Parameters:
    ///   - pokemonId: The Pokemon's unique identifier
    ///   - appRouter: The app router instance for navigation
    ///   - dependencies: The app-level dependencies
    /// - Returns: Configured PokemonDetailView
    static func makeView(pokemonId: Int, appRouter: AppRouter, dependencies: AppDependencies) -> PokemonDetailView {
        let viewModel = makeViewModel(pokemonId: pokemonId, appRouter: appRouter, apiClient: dependencies.apiClient)
        return PokemonDetailView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension PokemonDetailFactory {
    // MARK: - DataSources

    static func makeRemoteDataSource(apiClient: APIClient) -> PokemonDetailRemoteDataSource {
        PokemonDetailRemoteDataSourceImpl(apiClient: apiClient)
    }

    // MARK: - Mappers

    static func makeDTOMapper() -> PokemonDetailDTOMapper {
        PokemonDetailDTOMapperImpl()
    }

    // MARK: - Repositories

    static func makeRepository(apiClient: APIClient) -> PokemonDetailRepository {
        PokemonDetailRepositoryImpl(remoteDataSource: makeRemoteDataSource(apiClient: apiClient),
                                    dtoMapper: makeDTOMapper())
    }

    // MARK: - UseCases

    static func makeUseCase(apiClient: APIClient) -> PokemonDetailUseCase {
        PokemonDetailUseCaseImpl(repository: makeRepository(apiClient: apiClient))
    }

    // MARK: - Decorator Mappers

    static func makeDecoratorMapper() -> PokemonDetailDecoratorMapper {
        PokemonDetailDecoratorMapperImpl()
    }

    // MARK: - Routers

    static func makeRouter(appRouter: AppRouter) -> PokemonDetailRouter {
        PokemonDetailRouterImpl(appRouter: appRouter)
    }

    // MARK: - ViewModels

    static func makeViewModel(pokemonId: Int, appRouter: AppRouter, apiClient: APIClient) -> PokemonDetailViewModel {
        PokemonDetailViewModel(pokemonId: pokemonId,
                               useCase: makeUseCase(apiClient: apiClient),
                               decoratorMapper: makeDecoratorMapper(),
                               router: makeRouter(appRouter: appRouter))
    }
}
