import Foundation

// MARK: - PokemonListFactory

/// Factory for creating PokemonList feature components with proper dependency injection
@MainActor
enum PokemonListFactory {
    // MARK: - Public Methods

    /// Creates the PokemonList view with all dependencies injected
    /// - Parameters:
    ///   - appRouter: The app router for navigation
    ///   - dependencies: The app-level dependencies
    /// - Returns: Configured PokemonListView
    static func makeView(appRouter: AppRouter, dependencies: AppDependencies) -> PokemonListView {
        let router = makeRouter(appRouter: appRouter)
        let viewModel = makeViewModel(router: router, apiClient: dependencies.apiClient)
        return PokemonListView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension PokemonListFactory {
    // MARK: - DataSources

    static func makeRemoteDataSource(apiClient: APIClient) -> PokemonListRemoteDataSource {
        PokemonListRemoteDataSourceImpl(apiClient: apiClient)
    }

    // MARK: - Mappers

    static func makeDTOMapper() -> PokemonListDTOMapper {
        PokemonListDTOMapperImpl()
    }

    // MARK: - Repositories

    static func makeRepository(apiClient: APIClient) -> PokemonListRepository {
        PokemonListRepositoryImpl(remoteDataSource: makeRemoteDataSource(apiClient: apiClient),
                                  dtoMapper: makeDTOMapper())
    }

    // MARK: - UseCases

    static func makeUseCase(apiClient: APIClient) -> PokemonListUseCase {
        PokemonListUseCaseImpl(repository: makeRepository(apiClient: apiClient))
    }

    // MARK: - Decorator Mappers

    static func makeDecoratorMapper() -> PokemonListDecoratorMapper {
        PokemonListDecoratorMapperImpl()
    }

    // MARK: - Navigation

    static func makeRouter(appRouter: AppRouter) -> PokemonListRouter {
        PokemonListRouterImpl(appRouter: appRouter)
    }

    // MARK: - ViewModels

    static func makeViewModel(router: PokemonListRouter, apiClient: APIClient) -> PokemonListViewModel {
        PokemonListViewModel(useCase: makeUseCase(apiClient: apiClient),
                             decoratorMapper: makeDecoratorMapper(),
                             router: router)
    }
}
