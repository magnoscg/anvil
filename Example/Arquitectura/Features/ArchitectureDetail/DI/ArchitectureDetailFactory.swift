import Foundation

// MARK: - ArchitectureDetailFactory

/// Factory for creating Architecture Detail feature components with proper dependency injection.
/// All dependencies are injected - no default values.
@MainActor
enum ArchitectureDetailFactory {
    // MARK: - Public Methods

    /// Creates the Architecture Detail view with all dependencies injected
    /// - Parameters:
    ///   - featureId: The ID of the feature to display
    ///   - appRouter: The app router for navigation
    /// - Returns: Configured ArchitectureDetailView
    static func makeView(featureId: String,
                         appRouter: AppRouter) -> ArchitectureDetailView {
        let repository = makeRepository()
        let useCase = makeUseCase(repository: repository)
        let router = makeRouter(appRouter: appRouter)
        let decoratorMapper = makeDecoratorMapper()

        let viewModel = ArchitectureDetailViewModel(featureId: featureId,
                                                    useCase: useCase,
                                                    router: router,
                                                    decoratorMapper: decoratorMapper)

        return ArchitectureDetailView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension ArchitectureDetailFactory {
    // MARK: - DataSources

    static func makeJSONDataSource() -> ArchitectureDetailJSONDataSource {
        ArchitectureDetailJSONDataSourceImpl()
    }

    // MARK: - Mappers

    static func makeDTOMapper() -> ArchitectureDetailDTOMapper {
        ArchitectureDetailDTOMapperImpl()
    }

    // MARK: - Repositories

    static func makeRepository() -> ArchitectureDetailRepository {
        ArchitectureDetailRepositoryImpl(dataSource: makeJSONDataSource(),
                                         mapper: makeDTOMapper())
    }

    // MARK: - UseCases

    static func makeUseCase(repository: ArchitectureDetailRepository) -> ArchitectureDetailUseCase {
        ArchitectureDetailUseCaseImpl(repository: repository)
    }

    // MARK: - Navigation

    static func makeRouter(appRouter: AppRouter) -> ArchitectureDetailRouter {
        ArchitectureDetailRouterImpl(appRouter: appRouter)
    }

    // MARK: - DecoratorMappers

    static func makeDecoratorMapper() -> ArchitectureDetailDecoratorMapper {
        ArchitectureDetailDecoratorMapperImpl()
    }
}
