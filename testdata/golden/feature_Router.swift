import Foundation

// MARK: - ArticleRoute

/// Routes available within the Article feature
enum ArticleRoute: Hashable, Codable {
    case detail(id: String)
}

// MARK: - ArticleRouter

/// Protocol for Article feature navigation
@MainActor
protocol ArticleRouter: Sendable {
    func navigateToDetail(id: String)
    func goBack()
}

// MARK: - ArticleRouterImpl

/// Implementation of ArticleRouter using AppRouter
@MainActor
struct ArticleRouterImpl: ArticleRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - Public Methods

    func navigateToDetail(id: String) {
        appRouter.push(ArticleRoute.detail(id: id))
    }

    func goBack() {
        appRouter.pop()
    }
}
