import SwiftUI

// MARK: - StaggeredAppearModifier

/// Applies a staggered fade+slide entrance animation with accessibility support
struct StaggeredAppearModifier: ViewModifier {
    // MARK: - Properties

    let delay: Double
    let offset: CGFloat

    @State
    private var isVisible = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offset)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = true
                        }
                    }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    func staggeredAppear(delay: Double, offset: CGFloat = 20) -> some View {
        modifier(StaggeredAppearModifier(delay: delay, offset: offset))
    }
}
