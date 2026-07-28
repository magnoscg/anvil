import Foundation

// MARK: - ArchitectureFactory

/// Factory for creating Architecture feature components with proper dependency injection
/// All dependencies are injected - no default values
@MainActor
enum ArchitectureFactory {
    // MARK: - Public Methods

    /// Creates the Architecture view with all dependencies injected
    /// - Parameter appRouter: The app router for navigation
    /// - Returns: Configured ArchitectureView
    static func makeView(appRouter: AppRouter) -> ArchitectureView {
        let viewModel = makeViewModel(appRouter: appRouter)
        return ArchitectureView(viewModel: viewModel)
    }
}

// MARK: - Private Factory Methods

private extension ArchitectureFactory {
    // MARK: - DataSources

    static func makeStaticDataSource() -> ArchitectureStaticDataSource {
        ArchitectureStaticDataSourceImpl()
    }

    // MARK: - Repositories

    static func makeRepository() -> ArchitectureRepository {
        ArchitectureRepositoryImpl(staticDataSource: makeStaticDataSource())
    }

    // MARK: - UseCases

    static func makeUseCase(repository: ArchitectureRepository) -> ArchitectureUseCase {
        ArchitectureUseCaseImpl(repository: repository)
    }

    // MARK: - Navigation

    static func makeRouter(appRouter: AppRouter) -> ArchitectureRouter {
        ArchitectureRouterImpl(appRouter: appRouter)
    }

    // MARK: - Mappers

    static func makeDecoratorMapper() -> ArchitectureDecoratorMapper {
        ArchitectureDecoratorMapperImpl()
    }

    // MARK: - ViewModels

    static func makeViewModel(appRouter: AppRouter) -> ArchitectureViewModel {
        let repository = makeRepository()
        let useCase = makeUseCase(repository: repository)
        let router = makeRouter(appRouter: appRouter)
        let decoratorMapper = makeDecoratorMapper()

        return ArchitectureViewModel(useCase: useCase,
                                     router: router,
                                     decoratorMapper: decoratorMapper)
    }
}
