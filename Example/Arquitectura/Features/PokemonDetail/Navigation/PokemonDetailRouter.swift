import Foundation

// MARK: - PokemonDetailRoute

/// Routes available within the PokemonDetail feature.
/// Must be Codable for state preservation with @SceneStorage.
enum PokemonDetailRoute: Hashable, Codable {
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                debugDescription: "PokemonDetailRoute has no cases"))
    }

    func encode(to encoder: Encoder) throws {
        switch self {}
    }
}

// MARK: - PokemonDetailRouter

/// Protocol for PokemonDetail feature navigation.
/// ViewModels depend only on this protocol, not on AppRouter directly.
/// Must be Sendable for Swift 6 strict concurrency.
@MainActor
protocol PokemonDetailRouter: Sendable {
    /// Goes back to the previous screen
    func goBack()
}

// MARK: - PokemonDetailRouterImpl

/// Implementation of PokemonDetailRouter that delegates navigation to the generic AppRouter.
@MainActor
struct PokemonDetailRouterImpl: PokemonDetailRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - Public Methods

    func goBack() {
        appRouter.pop()
    }
}
