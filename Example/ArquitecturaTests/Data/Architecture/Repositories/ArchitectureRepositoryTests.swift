import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureRepositoryTests

@Suite
struct ArchitectureRepositoryTests {
    // MARK: - Helper

    private func makeRepository() -> ArchitectureRepository {
        let staticDataSource = ArchitectureStaticDataSourceImpl()
        return ArchitectureRepositoryImpl(staticDataSource: staticDataSource)
    }

    // MARK: - Tests

    @Test("GetFeatures returns all architecture features")
    func getFeaturesReturnsAllFeatures() async throws {
        // Given
        let repository = makeRepository()

        // When
        let features = try await repository.getFeatures()

        // Then
        #expect(features.count > 0)
    }

    @Test("GetFeatures returns features with valid categories")
    func getFeaturesReturnsValidCategories() async throws {
        // Given
        let repository = makeRepository()

        // When
        let features = try await repository.getFeatures()

        // Then
        let categories = Set(features.map(\.category))
        #expect(categories.count >= 3) // At least 3 different categories
    }

    @Test("GetFeatures returns features with unique IDs")
    func getFeaturesReturnsUniqueIds() async throws {
        // Given
        let repository = makeRepository()

        // When
        let features = try await repository.getFeatures()

        // Then
        let ids = features.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("GetFeatures includes implemented and pending features")
    func getFeaturesIncludesBothStatuses() async throws {
        // Given
        let repository = makeRepository()

        // When
        let features = try await repository.getFeatures()

        // Then
        let implementedCount = features.count(where: { $0.isImplemented })
        let pendingCount = features.count(where: { !$0.isImplemented })

        #expect(implementedCount > 0)
        #expect(pendingCount > 0)
    }

    @Test("Repository correctly maps DTOs to domain models")
    func repositoryMapsCorrectly() async throws {
        // Given
        let repository = makeRepository()

        // When
        let features = try await repository.getFeatures()

        // Then
        // Verify at least one feature has all required properties
        let firstFeature = try #require(features.first)
        #expect(!firstFeature.id.isEmpty)
        #expect(!firstFeature.name.isEmpty)
        #expect(!firstFeature.description.isEmpty)
    }
}
