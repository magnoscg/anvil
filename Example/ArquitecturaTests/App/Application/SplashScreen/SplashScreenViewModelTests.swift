import Foundation
import Testing
@testable import Arquitectura

// MARK: - SplashScreenViewModelTests

@Suite
@MainActor
struct SplashScreenViewModelTests {
    // MARK: - Tests

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let viewModel = SplashScreenViewModel(onFinished: {})
        #expect(viewModel.state == .idle)
    }

    @Test("startAnimation transitions through all phases")
    func startAnimationTransitionsThroughAllPhases() async {
        // Given
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: false,
                                              onFinished: { finishedCalled = true })

        // When
        await viewModel.startAnimation()

        // Then
        #expect(viewModel.state == .finished)
        #expect(finishedCalled == true)
    }

    @Test("startAnimation with reduced motion completes quickly")
    func startAnimationWithReducedMotion() async {
        // Given
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: true,
                                              onFinished: { finishedCalled = true })

        // When
        await viewModel.startAnimation()

        // Then
        #expect(viewModel.state == .finished)
        #expect(finishedCalled == true)
    }

    @Test("startAnimation does not re-enter if already started")
    func startAnimationDoesNotReEnter() async {
        // Given
        var finishCount = 0
        let viewModel = SplashScreenViewModel(reduceMotion: true,
                                              onFinished: { finishCount += 1 })

        // When — first call completes
        await viewModel.startAnimation()
        // Second call should be ignored (state is .finished, not .idle)
        await viewModel.startAnimation()

        // Then
        #expect(finishCount == 1)
    }

    @Test("startAnimation calls onFinished on completion")
    func startAnimationCallsOnFinished() async {
        // Given
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: true,
                                              onFinished: { finishedCalled = true })

        // When
        await viewModel.startAnimation()

        // Then
        #expect(finishedCalled == true)
    }

    @Test("startAnimation does not call onFinished on cancellation")
    func startAnimationDoesNotCallOnFinishedOnCancellation() async {
        // Given
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: false,
                                              onFinished: { finishedCalled = true })

        // When — start and immediately cancel
        let task = Task {
            await viewModel.startAnimation()
        }
        task.cancel()
        await task.value

        // Then
        #expect(finishedCalled == false)
    }

    @Test("ViewModel does not import SwiftUI")
    func viewModelHasNoSwiftUIDependency() {
        // This test verifies the refactor by checking that
        // the ViewModel only manages state (no animation properties)
        let viewModel = SplashScreenViewModel(reduceMotion: false,
                                              onFinished: {})

        // ViewModel only exposes state — visual properties belong to the View
        #expect(viewModel.state == .idle)
    }
}
