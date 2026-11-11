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
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: false,
                                              onFinished: { finishedCalled = true })

        await viewModel.startAnimation()

        #expect(viewModel.state == .finished)
        #expect(finishedCalled == true)
    }

    @Test("startAnimation with reduced motion completes quickly")
    func startAnimationWithReducedMotion() async {
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: true,
                                              onFinished: { finishedCalled = true })

        await viewModel.startAnimation()

        #expect(viewModel.state == .finished)
        #expect(finishedCalled == true)
    }

    @Test("startAnimation does not re-enter if already started")
    func startAnimationDoesNotReEnter() async {
        var finishCount = 0
        let viewModel = SplashScreenViewModel(reduceMotion: true,
                                              onFinished: { finishCount += 1 })

        await viewModel.startAnimation()
        await viewModel.startAnimation()

        #expect(finishCount == 1)
    }

    @Test("startAnimation calls onFinished on completion")
    func startAnimationCallsOnFinished() async {
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: true,
                                              onFinished: { finishedCalled = true })

        await viewModel.startAnimation()

        #expect(finishedCalled == true)
    }

    @Test("startAnimation does not call onFinished on cancellation")
    func startAnimationDoesNotCallOnFinishedOnCancellation() async {
        var finishedCalled = false
        let viewModel = SplashScreenViewModel(reduceMotion: false,
                                              onFinished: { finishedCalled = true })

        let task = Task {
            await viewModel.startAnimation()
        }
        task.cancel()
        await task.value

        #expect(finishedCalled == false)
    }

    @Test("ViewModel does not import SwiftUI")
    func viewModelHasNoSwiftUIDependency() {
        let viewModel = SplashScreenViewModel(reduceMotion: false,
                                              onFinished: {})

        #expect(viewModel.state == .idle)
    }
}
