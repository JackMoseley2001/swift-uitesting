import SwiftUI
import UITestingCore

/// A marker that takes three seconds to move across the screen, and a line of text
/// that appears when it has arrived, so that UI tests can tell whether the app is
/// running with or without animations.
struct AnimationView: View {
    @Environment(\.launchTraits) private var launchTraits
    @State private var isMoved = false
    @State private var hasArrived = false

    var body: some View {
        VStack(spacing: 24) {
            Text(launchTraits.animationsDisabled ? "Animations disabled" : "Animations enabled")
                .accessibilityIdentifier(AnimationID.status)

            Button("Move") {
                hasArrived = false
                if #available(iOS 17.0, *) {
                    withAnimation(.linear(duration: 3)) {
                        isMoved.toggle()
                    } completion: {
                        hasArrived = true
                    }
                } else {
                    // iOS 16 does not say when an animation ends, so the marker has
                    // arrived when the time the animation takes has gone by.
                    withAnimation(.linear(duration: 3)) {
                        isMoved.toggle()
                    }
                    let duration: Duration = launchTraits.animationsDisabled ? .zero : .seconds(3)
                    Task {
                        try? await Task.sleep(for: duration)
                        hasArrived = true
                    }
                }
            }
            .accessibilityIdentifier(AnimationID.moveButton)

            Text(isMoved ? "Right" : "Left")
                .frame(maxWidth: .infinity, alignment: isMoved ? .trailing : .leading)
                .accessibilityIdentifier(AnimationID.marker)

            if hasArrived {
                Text("Arrived")
                    .accessibilityIdentifier(AnimationID.arrived)
            }
        }
        .padding()
    }
}
