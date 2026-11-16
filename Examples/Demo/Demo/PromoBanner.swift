import SwiftUI
import UITestingCore

/// A banner that is shown only when the app is launched with the promo banner argument.
struct PromoBanner: View {
    @Environment(\.launchTraits) private var launchTraits

    var body: some View {
        if launchTraits.hasArgument(LaunchArgument.showPromoBanner) {
            Text("Free delivery this week")
                .accessibilityIdentifier(AccessibilityID.promoBanner)
        }
    }
}

#Preview {
    PromoBanner()
        .environment(\.launchTraits, LaunchTraits(arguments: [LaunchArgument.showPromoBanner]))
}
