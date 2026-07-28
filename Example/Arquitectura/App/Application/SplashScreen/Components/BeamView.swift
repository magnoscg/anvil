import SwiftUI

// MARK: - BeamView

/// A single animated energy beam for the splash screen
struct BeamView: View {
    // MARK: - Properties

    let angle: Double
    let delay: Double

    @State
    private var progress: CGFloat = 0.0
    @State
    private var opacity: Double = 0.0
    @State
    private var viewCenter: CGPoint = .zero

    /// Environment value for reduce motion preference
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Constants

    private let startRadius: CGFloat = 220
    private let endRadius: CGFloat = 90

    // MARK: - Init

    init(angle: Double, delay: Double) {
        self.angle = angle
        self.delay = delay
    }

    // MARK: - Body

    var body: some View {
        beamShape
            .position(x: viewCenter.x,
                      y: viewCenter.y - (startRadius - (startRadius - endRadius) * progress))
            .rotationEffect(.degrees(angle))
            .opacity(opacity)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                viewCenter = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
            }
            .task(id: angle) {
                await animateBeam()
            }
            .onDisappear {
                withAnimation(.linear(duration: 0)) {
                    opacity = 0
                }
            }
    }

    // MARK: - Private Views

    private var beamShape: some View {
        Capsule()
            .fill(LinearGradient(colors: [.clear, .orange.opacity(0.8), .white],
                                 startPoint: .top,
                                 endPoint: .bottom))
            .frame(width: 1.5, height: 60)
            .overlay(Capsule()
                .fill(Color.white.opacity(0.8))
                .frame(width: 0.5, height: 60)
                .blur(radius: 1))
    }

    // MARK: - Private Methods

    private func animateBeam() async {
        // Skip animations if user prefers reduced motion
        if reduceMotion {
            opacity = 1.0
            progress = 1.0
            return
        }

        do {
            try await Task.sleep(for: .seconds(delay))

            // Beam shooting in animation
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8)) {
                opacity = 1.0
                progress = 1.0
            }

            // Wait for initial animation to mostly complete
            try await Task.sleep(for: .seconds(1.0))

            // Continuous subtle pulse after arrival
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                opacity = 0.4
            }
        } catch {
            // Animation cancelled, ignore
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BeamView(angle: 0, delay: 0)
    }
}
