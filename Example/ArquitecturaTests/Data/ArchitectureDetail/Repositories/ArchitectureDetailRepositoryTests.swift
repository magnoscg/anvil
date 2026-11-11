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

    @Test("getFeatureDetail throws DomainError.parsing when the catalogue is invalid")
    func invalidCatalogueThrowsParsing() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "invalid-catalogue-\(UUID().uuidString).json")
        try Data("not valid json".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let repository =
            ArchitectureDetailRepositoryImpl(dataSource: ArchitectureDetailJSONDataSourceImpl(fileURL: fileURL),
                                             mapper: ArchitectureDetailDTOMapperImpl())

        await #expect(throws: DomainError.parsing) { try await repository.getFeatureDetail(id: "any") }
    }

    @Test("getFeatureDetail throws DomainError.unknown when the catalogue file is missing")
    func missingCatalogueThrowsDomainError() async {
        let repository =
            ArchitectureDetailRepositoryImpl(dataSource: ArchitectureDetailJSONDataSourceImpl(fileURL: nil),
                                             mapper: ArchitectureDetailDTOMapperImpl())

        await #expect(throws: DomainError.unknown) { try await repository.getFeatureDetail(id: "any") }
    }
}
