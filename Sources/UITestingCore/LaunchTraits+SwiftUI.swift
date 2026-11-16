#if canImport(SwiftUI)
import SwiftUI

extension EnvironmentValues {
    /// The launch traits that views read from the SwiftUI environment.
    ///
    /// The default is ``LaunchTraits/current``, so views can read what a UI test passed
    /// to the app without anything being injected:
    ///
    /// ```swift
    /// struct PromoBanner: View {
    ///     @Environment(\.launchTraits) private var launchTraits
    ///
    ///     var body: some View {
    ///         if launchTraits.hasArgument("--show-promo-banner") {
    ///             Text("Free delivery this week")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Override the value to show the same states in previews and unit tests:
    ///
    /// ```swift
    /// #Preview {
    ///     PromoBanner()
    ///         .environment(\.launchTraits, LaunchTraits(arguments: ["--show-promo-banner"]))
    /// }
    /// ```
    ///
    /// Environment values are not available in a view's initialiser. To set up state
    /// when a view is created, read ``LaunchTraits/current`` directly instead.
    @Entry public var launchTraits: LaunchTraits = .current
}
#endif
