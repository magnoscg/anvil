import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDTOMapperTests

@Suite
@MainActor
struct ArchitectureDTOMapperTests {
    // MARK: - Single Mapping Tests

    @Test("Map single DTO to model correctly")
    func mapSingleDTOToModel() {
        let mapper = ArchitectureDTOMapperImpl()
        let dto = ArchitectureDTO(id: "test-id",
                                  name: "Test Feature",
                                  description: "Test Description",
                                  category: "architecture",
                                  isImplemented: true)

        let model = mapper.map(dto)

        #expect(model.id == "test-id")
        #expect(model.name == "Test Feature")
        #expect(model.description == "Test Description")
        #expect(model.category == .architecture)
        #expect(model.isImplemented == true)
    }

    @Test("Map DTO with false isImplemented")
    func mapDTOWithFalseIsImplemented() {
        let mapper = ArchitectureDTOMapperImpl()
        let dto = ArchitectureDTO(id: "pending-id",
                                  name: "Pending Feature",
                                  description: "Not implemented yet",
                                  category: "ui",
                                  isImplemented: false)

        let model = mapper.map(dto)

        #expect(model.isImplemented == false)
        #expect(model.category == .ui)
    }

    // MARK: - Category Mapping Tests

    @Test("Map all valid categories correctly", arguments: [("architecture", ArchitectureModel.Category.architecture),
                                                            ("ui", ArchitectureModel.Category.ui),
                                                            ("networking", ArchitectureModel.Category.networking),
                                                            ("persistence", ArchitectureModel.Category.persistence),
                                                            ("security", ArchitectureModel.Category.security),
                                                            ("testing", ArchitectureModel.Category.testing)])
    func mapCategoryCorrectly(categoryString: String, expectedCategory: ArchitectureModel.Category) {
        let mapper = ArchitectureDTOMapperImpl()
        let dto = ArchitectureDTO(id: "test",
                                  name: "Test",
                                  description: "Test",
                                  category: categoryString,
                                  isImplemented: true)

        let model = mapper.map(dto)

        #expect(model.category == expectedCategory)
    }

    @Test("Map unknown category defaults to architecture")
    func mapUnknownCategoryDefaultsToArchitecture() {
        let mapper = ArchitectureDTOMapperImpl()
        let dto = ArchitectureDTO(id: "test",
                                  name: "Test",
                                  description: "Test",
                                  category: "unknown_category",
                                  isImplemented: true)

        let model = mapper.map(dto)

        #expect(model.category == .architecture)
    }

    // MARK: - Array Mapping Tests

    @Test("Map array of DTOs to models")
    func mapArrayOfDTOs() {
        let mapper = ArchitectureDTOMapperImpl()
        let dtos = [ArchitectureDTO(id: "1",
                                    name: "Feature 1",
                                    description: "Description 1",
                                    category: "architecture",
                                    isImplemented: true),
                    ArchitectureDTO(id: "2",
                                    name: "Feature 2",
                                    description: "Description 2",
                                    category: "ui",
                                    isImplemented: false)]

        let models = mapper.map(dtos)

        #expect(models.count == 2)
        #expect(models[0].id == "1")
        #expect(models[0].category == .architecture)
        #expect(models[1].id == "2")
        #expect(models[1].category == .ui)
    }

    @Test("Map empty array returns empty array")
    func mapEmptyArrayReturnsEmpty() {
        let mapper = ArchitectureDTOMapperImpl()

        let models = mapper.map([])

        #expect(models.isEmpty)
    }
}
