import Foundation

// MARK: - ArchitectureDetailJSONDataSourceImpl

/// Loads architecture details from the bundled JSON file.
/// Creating it does no I/O, so Factories can build it cheaply on every destination evaluation.
/// The file is read and decoded off the main actor when details are requested,
/// and a missing or invalid file is thrown instead of being reported as an empty catalogue.
struct ArchitectureDetailJSONDataSourceImpl: ArchitectureDetailJSONDataSource {
    // MARK: - Constants

    private enum Constants {
        static let fileName = "architecture_details"
        static let fileExtension = "json"
    }

    // MARK: - Properties

    private let fileURL: URL?

    // MARK: - Init

    init(bundle: Bundle = .main) {
        fileURL = bundle.url(forResource: Constants.fileName, withExtension: Constants.fileExtension)
    }

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    // MARK: - ArchitectureDetailJSONDataSource

    func loadFeatureDetails() async throws -> [ArchitectureDetailDTO] {
        guard let fileURL else {
            throw DataSourceError.fileNotFound("\(Constants.fileName).\(Constants.fileExtension)")
        }
        return try await Self.decodeFeatures(at: fileURL)
    }

    func loadFeatureDetail(id: String) async throws -> ArchitectureDetailDTO? {
        try await loadFeatureDetails().first { $0.id == id }
    }
}

// MARK: - Private Methods

private extension ArchitectureDetailJSONDataSourceImpl {
    @concurrent
    nonisolated static func decodeFeatures(at fileURL: URL) async throws -> [ArchitectureDetailDTO] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ArchitectureDetailResponseDTO.self, from: data).features
    }
}
