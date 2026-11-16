#if canImport(UIKit) && !os(watchOS)
import UIKit

extension LaunchTraits {
    /// Turns UIKit's animations off if the UI test that launched the app asked for that.
    ///
    /// Call this once when the app starts, such as in
    /// `application(_:didFinishLaunchingWithOptions:)`:
    ///
    /// ```swift
    /// LaunchTraits.current.applyAnimationSetting()
    /// ```
    ///
    /// This covers animations that UIKit runs, which include pushes on a navigation
    /// stack and the presentation of sheets. A SwiftUI app should use
    /// `uiTestAnimationsDisabled()` on its root view, which does this and turns
    /// SwiftUI's own animations off as well.
    ///
    /// Does nothing if the test did not ask, so it is safe to leave in the app.
    @MainActor
    public func applyAnimationSetting() {
        guard animationsDisabled else { return }
        UIView.setAnimationsEnabled(false)
    }
}
#endif
