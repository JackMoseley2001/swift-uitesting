/// Asks the app to run without animations.
public struct AnimationsDisabledTrait: UITestTrait {
    public func prepare(_ launch: inout LaunchConfiguration) {
        launch.disableAnimations()
    }
}

extension UITestTrait where Self == AnimationsDisabledTrait {
    /// Asks the app to run without animations, so that a test does not wait for them.
    ///
    /// XCTest waits for the app to stop animating before each action and query, so
    /// animations add their length to a test, and an element that is moving can be
    /// missed. Without them tests are faster and steadier.
    ///
    /// ```swift
    /// @UITestSuite(traits: .animationsDisabled)
    /// final class InboxTests: XCTestCase { … }
    /// ```
    ///
    /// The app has to act on the request. In a SwiftUI app, add
    /// `uiTestAnimationsDisabled()` from `UITestingCore` to the root view, and to
    /// pushed or presented screens that have SwiftUI animations. In a UIKit app, call
    /// `LaunchTraits.current.applyAnimationSetting()` when the app starts. Without
    /// one of these the trait does nothing.
    public static var animationsDisabled: Self {
        AnimationsDisabledTrait()
    }
}
