import SwiftUI

// MARK: - MyAppApp

@main
struct MyAppApp: App {
    // MARK: - Properties

    @State
    private var appRouter = AppRouterImpl()

    private let dependencies: AppDependencies

    // MARK: - Init

    init() {
        do {
            dependencies = try AppDependencies()
        } catch {
            preconditionFailure("Failed to initialize AppDependencies: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootNavigationView(appRouter: appRouter,
                               dependencies: dependencies)
        }
    }
}
