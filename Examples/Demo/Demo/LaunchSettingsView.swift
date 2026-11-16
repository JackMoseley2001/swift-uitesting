import SwiftUI
import UITestingCore

/// Shows the settings the app was launched with, so that UI tests can check the traits
/// that change them.
struct LaunchSettingsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(spacing: 8) {
            row("Language", Locale.preferredLanguages.first ?? "", AccessibilityID.preferredLanguage)
            row("Region", Locale.current.region?.identifier ?? "", AccessibilityID.region)
            row(
                "Beta features",
                UserDefaults.standard.bool(forKey: DefaultsKey.showsBetaFeatures) ? "on" : "off",
                AccessibilityID.betaFeatures
            )
            row("Orientation", verticalSizeClass == .compact ? "landscape" : "portrait", AccessibilityID.orientation)
        }
        .font(.footnote)
    }

    private func row(_ title: String, _ value: String, _ identifier: AccessibilityID) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .accessibilityIdentifier(identifier)
        }
    }
}
