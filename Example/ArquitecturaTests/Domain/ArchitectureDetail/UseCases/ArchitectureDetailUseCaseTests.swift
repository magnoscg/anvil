import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDetailUseCaseTests

@Suite
@MainActor
struct ArchitectureDetailUseCaseTests {
    // MARK: - Helper Methods

    private func makeDetailModel(id: String = "test-id",
                                 name: String = "Test Feature",
                                 icon: String = "building.2",
                                 version: String? = "1.0",
                                 category: ArchitectureDetailModel.Category = .architecture,
                                 subtitle: String = "Test subtitle",
                                 isImplemented: Bool = true,
                                 filesInvolved: [ArchitectureDetailModel.FileInfo] = [],
                                 implementationDetails: String = "Implementation details",
                                 codeExample: ArchitectureDetailModel.CodeExample? = nil,
                                 bestPractices: [ArchitectureDetailModel.BestPractice] = [])
        -> ArchitectureDetailModel {
        ArchitectureDetailModel(id: id,
                                name: name,
                                icon: icon,
                                version: version,
                                category: category,
                                subtitle: subtitle,
                                isImplemented: isImplemented,
                                filesInvolved: filesInvolved,
                                implementationDetails: implementationDetails,
                                codeExample: codeExample,
                                bestPractices: bestPractices)
    }

    // MARK: - Tests

    @Test("Execute returns feature from repository")
    func executeReturnsFeature() async throws {
        let expectedFeature = makeDetailModel(id: "test-id",
                                              name: "Clean Architecture",
                                              subtitle: "A layered architecture pattern",
                                              isImplemented: true)
        let mockRepository = ArchitectureDetailRepositoryMock()
        mockRepository.getFeatureDetailResult = .success(expectedFeature)
        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)

        let result = try await useCase.execute(id: "test-id")

        #expect(result?.id == expectedFeature.id)
        #expect(result?.name == expectedFeature.name)
    }

    @Test("Execute returns nil when feature not found")
    func executeReturnsNilWhenNotFound() async throws {
        let mockRepository = ArchitectureDetailRepositoryMock()
        mockRepository.getFeatureDetailResult = .success(nil)
        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)

        let result = try await useCase.execute(id: "nonexistent-id")

        #expect(result.isNil)
    }

    @Test("Execute calls repository with correct id")
    func executeCallsRepositoryWithCorrectId() async throws {
        let mockRepository = ArchitectureDetailRepositoryMock()
        mockRepository.getFeatureDetailResult = .success(nil)
        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)
        let expectedId = "specific-feature-id"

        _ = try await useCase.execute(id: expectedId)

        #expect(mockRepository.getFeatureDetailLastId == expectedId)
        #expect(mockRepository.getFeatureDetailCallCount == 1)
    }

    @Test("Execute propagates the repository's DomainError")
    func executePropagatesError() async {
        let mockRepository = ArchitectureDetailRepositoryMock()
        mockRepository.getFeatureDetailResult = .failure(DomainError.parsing)
        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)

        await #expect(throws: DomainError.parsing) { try await useCase.execute(id: "test-id") }
    }
}
