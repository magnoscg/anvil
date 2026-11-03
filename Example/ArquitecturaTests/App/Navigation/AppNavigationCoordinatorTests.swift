import Foundation
import SwiftUI
import Testing
@testable import Arquitectura

// MARK: - AppNavigationCoordinatorTests

@Suite
@MainActor
struct AppNavigationCoordinatorTests {
    // MARK: - Deep Link Tests

    @Test("handleDeepLink pushes feature route for valid URL")
    func handleDeepLinkPushesFeatureRoute() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://feature?id=clean-architecture"))

        coordinator.handleDeepLink(url)

        #expect(!appRouter.path.isEmpty)
    }

    @Test("handleDeepLink ignores URL with missing id")
    func handleDeepLinkIgnoresMissingId() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://feature"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.isEmpty)
    }

    @Test("handleDeepLink ignores URL with empty id")
    func handleDeepLinkIgnoresEmptyId() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://feature?id="))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.isEmpty)
    }

    @Test("handleDeepLink ignores unknown host")
    func handleDeepLinkIgnoresUnknownHost() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://unknown?id=test"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.isEmpty)
    }

    @Test("handleDeepLink ignores overly long id")
    func handleDeepLinkIgnoresLongId() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let longId = String(repeating: "a", count: 257)
        let url = try #require(URL(string: "arquitectura://feature?id=\(longId)"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.isEmpty)
    }

    // MARK: - Pokemon Deep Link Tests

    @Test("handleDeepLink pushes pokemon detail for valid pokemon URL")
    func handleDeepLinkPushesPokemonDetail() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://pokemon?id=25"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.count == 2)
    }

    @Test("handleDeepLink pushes pokedex list for valid pokedex URL")
    func handleDeepLinkPushesPokedex() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://pokedex"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.count == 1)
    }

    @Test("handleDeepLink ignores pokemon URL with invalid id")
    func handleDeepLinkIgnoresInvalidPokemonId() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://pokemon?id=abc"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.isEmpty)
    }

    @Test("handleDeepLink ignores pokemon URL with zero id")
    func handleDeepLinkIgnoresZeroPokemonId() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let url = try #require(URL(string: "arquitectura://pokemon?id=0"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.isEmpty)
    }

    // MARK: - Deep Link Stack Tests

    @Test("handleDeepLink replaces the current stack instead of pushing on top")
    func handleDeepLinkReplacesStack() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        appRouter.push(ArchitectureRoute.detail(featureId: "first"))
        appRouter.push(ArchitectureRoute.detail(featureId: "second"))
        appRouter.push(ArchitectureRoute.detail(featureId: "third"))
        let url = try #require(URL(string: "arquitectura://pokemon?id=25"))
        var expectedPath = NavigationPath()
        expectedPath.append(PokemonListRoute.list)
        expectedPath.append(PokemonListRoute.detail(pokemonId: 25))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path == expectedPath)
    }

    @Test("handleDeepLink keeps the current stack when the URL is invalid")
    func invalidDeepLinkKeepsStack() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        appRouter.push(ArchitectureRoute.detail(featureId: "current"))
        let url = try #require(URL(string: "arquitectura://pokemon?id=abc"))

        coordinator.handleDeepLink(url)

        #expect(appRouter.path.count == 1)
    }

    @Test("restoreNavigationState is ignored after a deep link was handled")
    func restoreIgnoredAfterDeepLink() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let savedData = try makeSavedPathData(featureIds: ["saved-1", "saved-2"])
        let url = try #require(URL(string: "arquitectura://pokedex"))
        var expectedPath = NavigationPath()
        expectedPath.append(PokemonListRoute.list)

        coordinator.handleDeepLink(url)
        coordinator.restoreNavigationState(from: savedData)

        #expect(appRouter.path == expectedPath)
    }

    @Test("restoreNavigationState still applies after an ignored deep link")
    func restoreAppliesAfterIgnoredDeepLink() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let savedData = try makeSavedPathData(featureIds: ["saved-1", "saved-2"])
        let url = try #require(URL(string: "arquitectura://unknown"))

        coordinator.handleDeepLink(url)
        coordinator.restoreNavigationState(from: savedData)

        #expect(appRouter.path.count == 2)
    }

    @Test("handleDeepLink after restoration replaces the restored stack")
    func deepLinkAfterRestoreReplacesStack() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let savedData = try makeSavedPathData(featureIds: ["saved-1", "saved-2"])
        let url = try #require(URL(string: "arquitectura://feature?id=deep-link"))
        var expectedPath = NavigationPath()
        expectedPath.append(ArchitectureRoute.detail(featureId: "deep-link"))

        coordinator.restoreNavigationState(from: savedData)
        coordinator.handleDeepLink(url)

        #expect(appRouter.path == expectedPath)
    }

    // MARK: - State Persistence Tests

    @Test("restoreNavigationState restores from valid data")
    func restoreFromValidData() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)

        appRouter.push(ArchitectureRoute.detail(featureId: "test-feature"))
        let codableRep = try #require(appRouter.path.codable)
        let data = try JSONEncoder().encode(codableRep)

        appRouter.popToRoot()
        #expect(appRouter.path.isEmpty)

        coordinator.restoreNavigationState(from: data)

        #expect(!appRouter.path.isEmpty)
    }

    @Test("restoreNavigationState does nothing for nil data")
    func restoreFromNilData() {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)

        coordinator.restoreNavigationState(from: nil)

        #expect(appRouter.path.isEmpty)
    }

    @Test("restoreNavigationState handles corrupted data gracefully")
    func restoreFromCorruptedData() {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        let corruptedData = "not valid json".data(using: .utf8)!

        coordinator.restoreNavigationState(from: corruptedData)

        #expect(appRouter.path.isEmpty)
    }

    @Test("encodeNavigationState returns data for non-empty path")
    func encodeNonEmptyPath() throws {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        appRouter.push(ArchitectureRoute.detail(featureId: "test"))

        let data = try #require(coordinator.encodeNavigationState())

        #expect(data.count > 0)
    }

    @Test("encodeNavigationState returns data for empty path")
    func encodeEmptyPath() {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)

        let data = coordinator.encodeNavigationState()

        #expect(data != nil)
    }

    // MARK: - Debounced Save Tests

    @Test("saveNavigationStateDebounced calls persist closure")
    func debouncedSaveCallsPersist() async {
        let appRouter = AppRouterImpl()
        let coordinator = AppNavigationCoordinator(appRouter: appRouter)
        appRouter.push(ArchitectureRoute.detail(featureId: "test"))

        let persistedData = await withCheckedContinuation { continuation in
            coordinator.saveNavigationStateDebounced { data in
                continuation.resume(returning: data)
            }
        }

        #expect(persistedData != nil)
    }

    // MARK: - Helpers

    private func makeSavedPathData(featureIds: [String]) throws -> Data {
        var path = NavigationPath()
        for featureId in featureIds {
            path.append(ArchitectureRoute.detail(featureId: featureId))
        }
        let codableRepresentation = try #require(path.codable)
        return try JSONEncoder().encode(codableRepresentation)
    }
}
