import Foundation

// MARK: - SplashScreenState

/// State machine for splash screen lifecycle
enum SplashScreenState: Equatable {
    case idle
    case animating(SplashAnimationPhase)
    case finished
}

// MARK: - SplashAnimationPhase

/// Animation phases for the splash screen sequence
enum SplashAnimationPhase: Int, CaseIterable {
    case logoFadeIn = 0
    case raysAppear = 1
    case particlesFadeIn = 2
    case textReveal = 3
    case complete = 4

    // MARK: - Properties

    /// Duration for each phase in seconds
    var duration: Duration {
        switch self {
        case .logoFadeIn: .seconds(1.2)
        case .raysAppear: .seconds(0.2)
        case .particlesFadeIn: .seconds(0.5)
        case .textReveal: .seconds(1.0)
        case .complete: .seconds(2.3)
        }
    }
}
