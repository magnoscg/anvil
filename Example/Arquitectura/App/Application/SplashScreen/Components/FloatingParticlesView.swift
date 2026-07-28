import SwiftUI

// MARK: - FloatingParticlesView

/// Displays floating particles that gently move across the screen
struct FloatingParticlesView: View {
    // MARK: - Properties

    @State
    private var particles: [Particle] = []
    @State
    private var viewSize: CGSize = .zero

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            Canvas { context, _ in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let yOffset = sin(time + particle.phaseOffset) * 10
                    let xOffset = cos(time * 0.5 + particle.phaseOffset) * 5

                    let rect = CGRect(x: particle.x + xOffset,
                                      y: particle.y + yOffset,
                                      width: particle.size,
                                      height: particle.size)

                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            viewSize = newSize
            particles = generateParticles(in: newSize)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Private Methods

    private func generateParticles(in size: CGSize) -> [Particle] {
        (0 ..< 30).map { _ in
            Particle(x: CGFloat.random(in: 0 ... size.width),
                     y: CGFloat.random(in: 0 ... size.height),
                     size: CGFloat.random(in: 1 ... 3),
                     opacity: Double.random(in: 0.1 ... 0.3),
                     phaseOffset: Double.random(in: 0 ... .pi * 2))
        }
    }
}

// MARK: - Particle

private struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let phaseOffset: Double
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FloatingParticlesView()
    }
}
