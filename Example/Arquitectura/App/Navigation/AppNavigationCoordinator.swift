import Foundation
import os
import SwiftUI

// MARK: - AppNavigationCoordinator

/// Coordinates one window's navigation: deep link parsing, state persistence, and debounced saves.
/// Deep links received before the saved state is restored (for example, the URL that launched
/// the app) are held and applied right after restoration, so they win regardless of whether
/// `.onOpenURL` or the restoration `.task` runs first.
@MainActor
@Observable
final class AppNavigationCoordinator {
    // MARK: - Static

    private nonisolated static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magnos.Arquitectura",
                                                   category: "Navigation")

    // MARK: - Properties

    private let appRouter: AppRouterImpl
    private var saveTask: Task<Void, Never>?
    private var hasRestoredState = false
    private var pendingDeepLink: URL?

    // MARK: - Init

    init(appRouter: AppRouterImpl) {
        self.appRouter = appRouter
    }

    // MARK: - Deep Linking

    /// Handles deep links for navigation.
    /// URL format: `arquitectura://feature?id=123`, `arquitectura://pokemon?id=25`, `arquitectura://pokedex`.
    /// A valid deep link replaces the current stack. Before restoration it is held until
    /// `restoreNavigationState(from:)` runs; a newer link replaces a held one.
    func handleDeepLink(_ url: URL) {
        guard hasRestoredState else {
            pendingDeepLink = url
            return
        }
        navigate(to: url)
    }

    // MARK: - State Persistence

    /// Restores navigation state from persisted data, once per window, and then applies
    /// any deep link received before restoration.
    /// - Parameter data: The previously encoded NavigationPath data, or nil.
    func restoreNavigationState(from data: Data?) {
        guard !hasRestoredState else { return }

        if let data {
            restorePath(from: data)
        }
        hasRestoredState = true

        if let pendingDeepLink {
            self.pendingDeepLink = nil
            navigate(to: pendingDeepLink)
        }
    }

    /// Encodes the current navigation state to Data for persistence.
    /// - Returns: The encoded navigation path, or nil if encoding fails.
    func encodeNavigationState() -> Data? {
        guard let codableRep = appRouter.path.codable else { return nil }

        do {
            return try JSONEncoder().encode(codableRep)
        } catch {
            Self.logger.error("Failed to save navigation state: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Debounces navigation state saves to avoid excessive serialization
    /// during rapid navigation changes (e.g., animated transitions).
    /// - Parameter persist: Closure that receives encoded data and writes it to storage.
    func saveNavigationStateDebounced(persist: @escaping @MainActor (Data?) -> Void) {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                // CancellationError — debounce superseded by a newer save
                return
            }
            guard !Task.isCancelled else { return }
            let data = self?.encodeNavigationState()
            persist(data)
        }
    }
}

// MARK: - Private Methods

private extension AppNavigationCoordinator {
    func navigate(to url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            Self.logger.warning("Deep link ignored: invalid URL components")
            return
        }

        switch host {
        case "feature":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value,
               !id.isEmpty,
               id.count <= 256 {
                Self.logger.debug("Deep link: navigating to feature \(id, privacy: .public)")
                var path = NavigationPath()
                path.append(ArchitectureRoute.detail(featureId: id))
                replaceStack(with: path)
            } else {
                Self.logger.warning("Deep link ignored: missing or invalid feature id")
            }

        case "pokemon":
            if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let pokemonId = Int(idString),
               pokemonId > 0 {
                Self.logger.debug("Deep link: navigating to pokemon \(pokemonId)")
                var path = NavigationPath()
                path.append(PokemonListRoute.list)
                path.append(PokemonListRoute.detail(pokemonId: pokemonId))
                replaceStack(with: path)
            } else {
                Self.logger.warning("Deep link ignored: missing or invalid pokemon id")
            }

        case "pokedex":
            Self.logger.debug("Deep link: navigating to pokedex")
            var path = NavigationPath()
            path.append(PokemonListRoute.list)
            replaceStack(with: path)

        default:
            Self.logger.warning("Deep link ignored: unknown host '\(host, privacy: .public)'")
        }
    }

    func restorePath(from data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let codableRep = try decoder.decode(NavigationPath.CodableRepresentation.self,
                                                from: data)
            appRouter.path = NavigationPath(codableRep)
            Self.logger.debug("Navigation state restored successfully")
        } catch {
            Self.logger.error("Failed to restore navigation state: \(error.localizedDescription, privacy: .public)")
        }
    }

    func replaceStack(with newPath: NavigationPath) {
        appRouter.path = newPath
    }
}
