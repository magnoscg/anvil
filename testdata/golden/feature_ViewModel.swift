import Foundation

// MARK: - ArticleViewModel

/// ViewModel for the Article feature.
@MainActor
@Observable
final class ArticleViewModel {
    // MARK: - Properties

    private(set) var state: ArticleState = .idle
    private(set) var items: [ArticleDecorator] = []

    private let useCase: ArticleUseCase
    private let decoratorMapper: ArticleDecoratorMapper
    private let router: ArticleRouter

    // MARK: - Init

    init(useCase: ArticleUseCase,
         decoratorMapper: ArticleDecoratorMapper,
         router: ArticleRouter) {
        self.useCase = useCase
        self.decoratorMapper = decoratorMapper
        self.router = router
    }

    // MARK: - Public Methods

    func load() async {
        guard state != .loading else { return }

        let previousState = state
        state = .loading

        do {
            let models = try await useCase.execute()
            let decorators = models.map { decoratorMapper.map($0) }
            items = decorators
            state = .loaded
        } catch is CancellationError {
            state = previousState
        } catch let error as DomainError {
            state = .error(ErrorDecorator.from(error))
        } catch {
            state = .error(.generic)
        }
    }

    func navigateToDetail(id: String) {
        router.navigateToDetail(id: id)
    }
}
