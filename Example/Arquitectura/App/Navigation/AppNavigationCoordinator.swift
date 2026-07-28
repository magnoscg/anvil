import Foundation
import os
import SwiftUI

// MARK: - AppNavigationCoordinator

/// Coordinates navigation logic: deep link parsing, state persistence, and debounced saves.
/// Extracted from RootNavigationView so the View remains a thin shell.
@MainActor
@Observable
final class AppNavigationCoordinator {
    // MARK: - Static

    private nonisolated static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magnos.Arquitectura",
                                                   category: "Navigation")

    // MARK: - Properties

    private var appRouter: AppRouter
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - Deep Linking

    /// Handles deep links for navigation.
    /// URL format: `arquitectura://feature/detail?id=123`
    func handleDeepLink(_ url: URL) {
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
                appRouter.push(ArchitectureRoute.detail(featureId: id))
            } else {
                Self.logger.warning("Deep link ignored: missing or invalid feature id")
            }

        case "pokemon":
            if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let pokemonId = Int(idString),
               pokemonId > 0 {
                Self.logger.debug("Deep link: navigating to pokemon \(pokemonId)")
                appRouter.push(PokemonListRoute.list)
                appRouter.push(PokemonListRoute.detail(pokemonId: pokemonId))
            } else {
                Self.logger.warning("Deep link ignored: missing or invalid pokemon id")
            }

        case "pokedex":
            Self.logger.debug("Deep link: navigating to pokedex")
            appRouter.push(PokemonListRoute.list)

        default:
            Self.logger.warning("Deep link ignored: unknown host '\(host, privacy: .public)'")
        }
    }

    // MARK: - State Persistence

    /// Restores navigation state from persisted data.
    /// - Parameter data: The previously encoded NavigationPath data, or nil.
    func restoreNavigationState(from data: Data?) {
        guard let data else { return }

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
