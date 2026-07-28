import SwiftUI

// MARK: - SplashLogoView

/// Displays the Swift logo with glow effects for the splash screen
struct SplashLogoView: View {
    // MARK: - Properties

    let scale: CGFloat
    let opacity: Double
    let glowIntensity: Double

    // MARK: - Body

    var body: some View {
        ZStack {
            glowLayers
                .opacity(opacity)

            logoImage
        }
    }

    // MARK: - Private Views

    private var glowLayers: some View {
        Group {
            Circle()
                .fill(AppColors.swiftOrange.opacity(0.15))
                .containerRelativeFrame(.horizontal) { length, _ in
                    length * 0.7
                }
                .blur(radius: 60)
                .scaleEffect(glowIntensity)

            Circle()
                .fill(AppColors.swiftOrange.opacity(0.3))
                .frame(width: 150, height: 150)
                .blur(radius: 30)
                .scaleEffect(glowIntensity * 0.9)
        }
    }

    private var logoImage: some View {
        Image(systemName: "swift")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)
            .foregroundStyle(LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing))
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

// MARK: - Previews

#Preview("Visible") {
    ZStack {
        Color.black.ignoresSafeArea()
        SplashLogoView(scale: 1.0, opacity: 1.0, glowIntensity: 1.0)
    }
}

#Preview("Faded") {
    ZStack {
        Color.black.ignoresSafeArea()
        SplashLogoView(scale: 0.8, opacity: 0.5, glowIntensity: 0.5)
    }
}
