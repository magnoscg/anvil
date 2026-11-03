import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDetailRepositoryTests

@Suite
@MainActor
struct ArchitectureDetailRepositoryTests {
    // MARK: - Tests

    @Test("getFeatureDetail returns a mapped model for a bundled feature")
    func returnsMappedModel() async throws {
        let dataSource = ArchitectureDetailJSONDataSourceImpl()
        let features = try await dataSource.loadFeatureDetails()
        let firstFeature = try #require(features.first)
        let repository = ArchitectureDetailRepositoryImpl(dataSource: dataSource,
                                                          mapper: ArchitectureDetailDTOMapperImpl())

        let model = try await repository.getFeatureDetail(id: firstFeature.id)

        #expect(model?.id == firstFeature.id)
    }

    @Test("getFeatureDetail throws a DomainError when the catalogue cannot be loaded")
    func missingCatalogueThrowsDomainError() async {
        let repository = ArchitectureDetailRepositoryImpl(dataSource: ArchitectureDetailJSONDataSourceImpl(fileURL: nil),
                                                          mapper: ArchitectureDetailDTOMapperImpl())

        do {
            _ = try await repository.getFeatureDetail(id: "any")
            Issue.record("Expected an error to be thrown")
        } catch {
            #expect(error is DomainError)
        }
    }
}
