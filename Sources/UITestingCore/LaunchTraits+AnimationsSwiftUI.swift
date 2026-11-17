#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Runs this view without animations if the UI test that launched the app asked for that.
    ///
    /// Add it to the root view of the app:
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    ///         .uiTestAnimationsDisabled()
    /// }
    /// ```
    ///
    /// A UI test asks with the `animationsDisabled` trait. From then on:
    ///
    /// - The animations that UIKit runs happen at once, everywhere in the app. These
    ///   include pushes on a navigation stack and the presentation of sheets.
    /// - SwiftUI's own animations, from `withAnimation` or an `animation` modifier,
    ///   happen at once in this view and the views inside it.
    ///
    /// A screen that is pushed onto a navigation stack or presented as a sheet is a
    /// view hierarchy of its own, which the modifier on the root view does not reach.
    /// Add the modifier to those screens as well if they have SwiftUI animations:
    ///
    /// ```swift
    /// .navigationDestination(for: Route.self) { route in
    ///     RouteView(route)
    ///         .uiTestAnimationsDisabled()
    /// }
    /// ```
    ///
    /// Does nothing if the test did not ask, so it is safe to leave in the app.
    ///
    /// - Parameter traits: The launch traits to read. The default is the traits the
    ///   app was launched with.
    public func uiTestAnimationsDisabled(_ traits: LaunchTraits = .current) -> some View {
        modifier(UITestAnimationsModifier(isDisabled: traits.animationsDisabled))
    }
}

private struct UITestAnimationsModifier: ViewModifier {
    let isDisabled: Bool

    init(isDisabled: Bool) {
        self.isDisabled = isDisabled
        #if canImport(UIKit) && !os(watchOS)
            if isDisabled {
                UIView.setAnimationsEnabled(false)
            }
        #endif
    }

    func body(content: Content) -> some View {
        if isDisabled {
            content.transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        } else {
            content
        }
    }
}
#endif
