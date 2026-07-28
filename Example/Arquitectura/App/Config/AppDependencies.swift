import Foundation

// MARK: - AppDependencies

/// Shared app-level dependencies created at the composition root and injected through factories.
struct AppDependencies {
    // MARK: - Properties

    let apiClient: APIClient

    // MARK: - Init

    init() {
        do {
            let configuration = try EnvironmentConfigurationImpl()
            apiClient = APIClientImpl(configuration: configuration)
        } catch {
            fatalError("Failed to initialize AppDependencies: \(error)")
        }
    }
}
