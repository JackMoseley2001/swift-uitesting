import SwiftUI
import UITestingCore

/// Shows the settings the app was launched with, so that UI tests can check the traits
/// that change them.
struct LaunchSettingsView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                row("Language", Locale.preferredLanguages.first ?? "", LaunchSettingsID.preferredLanguage)
                row("Region", Locale.current.region?.identifier ?? "", LaunchSettingsID.region)
                row(
                    "Beta features",
                    UserDefaults.standard.bool(forKey: DefaultsKey.showsBetaFeatures) ? "on" : "off",
                    LaunchSettingsID.betaFeatures
                )
                row("Orientation", verticalSizeClass == .compact ? "landscape" : "portrait", LaunchSettingsID.orientation)
            }
            .font(.footnote)
            .padding()
        }
    }

    private func row(_ title: String, _ value: String, _ identifier: LaunchSettingsID.StaticText) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .accessibilityIdentifier(identifier)
        }
    }
}
