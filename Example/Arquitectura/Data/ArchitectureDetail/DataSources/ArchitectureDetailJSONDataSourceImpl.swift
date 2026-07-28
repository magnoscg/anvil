import Foundation
import os

// MARK: - ArchitectureDetailJSONDataSourceImpl

/// Implementation that loads architecture details from a bundled JSON file.
/// JSON is loaded and decoded once during initialization and cached for all subsequent calls.
struct ArchitectureDetailJSONDataSourceImpl: ArchitectureDetailJSONDataSource {
    // MARK: - Constants

    private enum Constants {
        static let fileName = "architecture_details"
        static let fileExtension = "json"
    }

    // MARK: - Static Properties

    private nonisolated static let logger = Logger(subsystem: "com.magnos.Arquitectura",
                                                   category: "ArchitectureDetailJSON")

    // MARK: - Properties

    private let cachedFeatures: [ArchitectureDetailDTO]

    // MARK: - Init

    init(bundle: Bundle = .main) {
        do {
            self.cachedFeatures = try Self.loadFeatures(from: bundle)
        } catch {
            Self.logger.error("Failed to load architecture details JSON: \(error.localizedDescription)")
            self.cachedFeatures = []
        }
    }

    // MARK: - ArchitectureDetailJSONDataSource

    func loadFeatureDetails() throws -> [ArchitectureDetailDTO] {
        cachedFeatures
    }

    func loadFeatureDetail(id: String) throws -> ArchitectureDetailDTO? {
        cachedFeatures.first { $0.id == id }
    }
}

// MARK: - Private Methods

private extension ArchitectureDetailJSONDataSourceImpl {
    static func loadFeatures(from bundle: Bundle) throws -> [ArchitectureDetailDTO] {
        guard let url = bundle.url(forResource: Constants.fileName, withExtension: Constants.fileExtension) else {
            throw DataSourceError.fileNotFound("\(Constants.fileName).\(Constants.fileExtension)")
        }

        let data = try Data(contentsOf: url)
        let response = try JSONDecoder().decode(ArchitectureDetailResponseDTO.self, from: data)
        return response.features
    }
}
