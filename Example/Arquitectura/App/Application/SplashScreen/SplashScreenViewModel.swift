import Foundation

// MARK: - SplashScreenViewModel

/// ViewModel for the splash screen state machine.
/// Manages phase transitions and timing only — animations belong in the View layer.
@MainActor
@Observable
final class SplashScreenViewModel {
    // MARK: - Properties

    private(set) var state: SplashScreenState = .idle

    private let onFinished: @MainActor () -> Void
    private let reduceMotion: Bool

    // MARK: - Init

    /// Creates the splash screen ViewModel.
    /// - Parameters:
    ///   - reduceMotion: Whether the user prefers reduced motion.
    ///   - onFinished: Callback invoked when the splash sequence completes.
    init(reduceMotion: Bool = false,
         onFinished: @escaping @MainActor () -> Void) {
        self.reduceMotion = reduceMotion
        self.onFinished = onFinished
    }

    // MARK: - Public Methods

    /// Starts the splash sequence by advancing through animation phases.
    /// The View observes `state` changes and applies animations accordingly.
    func startAnimation() async {
        guard state == .idle else { return }

        if reduceMotion {
            await startWithReducedMotion()
            return
        }

        do {
            state = .animating(.logoFadeIn)

            try await Task.sleep(for: .seconds(0.2))
            state = .animating(.raysAppear)

            try await Task.sleep(for: .seconds(0.5))
            state = .animating(.particlesFadeIn)

            try await Task.sleep(for: .seconds(1.0))
            state = .animating(.textReveal)

            try await Task.sleep(for: .seconds(3))
            state = .animating(.complete)
            state = .finished
            onFinished()

        } catch is CancellationError {
            return
        } catch {
            state = .finished
            onFinished()
        }
    }

    // MARK: - Private Methods

    /// Starts splash with reduced motion (instant state changes, minimal delay).
    private func startWithReducedMotion() async {
        state = .animating(.logoFadeIn)

        do {
            try await Task.sleep(for: .seconds(1.0))
        } catch is CancellationError {
            return
        } catch {}

        state = .finished
        onFinished()
    }
}
