import SwiftUI

// MARK: - EnergyBeamsView

/// Displays animated energy beams radiating from the center
struct EnergyBeamsView: View {
    // MARK: - Properties

    private let beamCount = 12

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(0 ..< beamCount, id: \.self) { index in
                BeamView(angle: Double(index) * (360.0 / Double(beamCount)),
                         delay: Double(index) * 0.05)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EnergyBeamsView()
    }
}
