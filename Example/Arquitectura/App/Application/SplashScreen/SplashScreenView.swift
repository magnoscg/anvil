import SwiftUI

// MARK: - SplashScreenView

struct SplashScreenView: View {
    // MARK: - Properties

    @State
    private var viewModel: SplashScreenViewModel

    /// Visual properties owned by the View — animated via .onChange(of: state)
    @State
    private var logoScale: CGFloat = 0.8
    @State
    private var logoOpacity: Double = 0
    @State
    private var glowIntensity: Double = 0.5
    @State
    private var textOpacity: Double = 0
    @State
    private var particlesOpacity: Double = 0
    @State
    private var showRays = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Init

    init(viewModel: SplashScreenViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            FloatingParticlesView()
                .opacity(particlesOpacity)

            mainContent
        }
        .task {
            await viewModel.startAnimation()
        }
        .onChange(of: viewModel.state) { _, newState in
            applyAnimations(for: newState)
        }
    }

    // MARK: - Private Views

    private var backgroundLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(gradient: Gradient(colors: [AppColors.nightBlue,
                                                       AppColors.deepBlack,
                                                       .black]),
                           center: .center,
                           startRadius: 20,
                           endRadius: 600)
                .ignoresSafeArea()
        }
    }

    private var mainContent: some View {
        VStack {
            Spacer()

            logoSection
                .frame(maxHeight: .infinity)

            poweredByText
        }
    }

    private var logoSection: some View {
        ZStack {
            SplashLogoView(scale: logoScale,
                           opacity: logoOpacity,
                           glowIntensity: glowIntensity)

            if showRays {
                EnergyBeamsView()
            }
        }
    }

    private var poweredByText: some View {
        Text("splash.poweredBy")
            .font(.footnote.weight(.semibold))
            .tracking(8)
            .foregroundStyle(.white.opacity(0.9))
            .shadow(color: .white.opacity(0.1), radius: 8, x: 0, y: 0)
            .opacity(textOpacity)
            .offset(y: -220)
    }
}

// MARK: - Animation Logic

private extension SplashScreenView {
    /// Applies animations based on the current state transition.
    /// Each phase maps to specific visual property changes with appropriate animation curves.
    /// When Reduce Motion is enabled, sets final values instantly without animation.
    func applyAnimations(for state: SplashScreenState) {
        if reduceMotion {
            applyReducedMotion(for: state)
            return
        }

        switch state {
        case .idle:
            break

        case let .animating(phase):
            applyPhaseAnimation(phase)

        case .finished:
            withAnimation(.linear(duration: 0)) {
                glowIntensity = 0
            }
        }
    }

    /// Sets visual properties instantly without animation for Reduce Motion users.
    func applyReducedMotion(for state: SplashScreenState) {
        switch state {
        case .idle:
            break

        case .animating(.logoFadeIn):
            logoOpacity = 1.0
            logoScale = 1.0
            textOpacity = 1.0
            particlesOpacity = 0.6
            showRays = true

        case .animating:
            break

        case .finished:
            withAnimation(.linear(duration: 0)) {
                glowIntensity = 0
            }
        }
    }

    func applyPhaseAnimation(_ phase: SplashAnimationPhase) {
        switch phase {
        case .logoFadeIn:
            withAnimation(.easeOut(duration: 1.2)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }

        case .raysAppear:
            showRays = true
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowIntensity = 1.2
            }

        case .particlesFadeIn:
            withAnimation(.easeIn(duration: 2.0)) {
                particlesOpacity = 0.6
            }

        case .textReveal:
            withAnimation(.easeOut(duration: 1.5)) {
                textOpacity = 1.0
            }

        case .complete:
            break
        }
    }
}

// MARK: - Previews

#Preview {
    SplashScreenView(viewModel: SplashScreenViewModel(onFinished: {}))
}
