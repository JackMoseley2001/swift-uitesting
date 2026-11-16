import XCTest

/// A reusable piece of configuration or behaviour that applies to a UI test or to a whole suite.
///
/// Every requirement has a default implementation that does nothing, so a trait
/// implements only the steps it needs.
///
/// A trait can configure how the app is launched:
///
/// ```swift
/// struct SkipOnboarding: UITestTrait {
///     func prepare(_ launch: inout LaunchConfiguration) {
///         launch.arguments.append("--skip-onboarding")
///     }
/// }
/// ```
///
/// Or it can act on the test itself, without sending anything to the app:
///
/// ```swift
/// struct Landscape: UITestTrait {
///     func setUp(_ context: UITestContext) async throws {
///         XCUIDevice.shared.orientation = .landscapeLeft
///     }
///
///     func tearDown(_ context: UITestContext) async throws {
///         XCUIDevice.shared.orientation = .portrait
///     }
/// }
/// ```
///
/// To make a trait available with leading-dot syntax, add a static member in an
/// extension of `UITestTrait`:
///
/// ```swift
/// extension UITestTrait where Self == SkipOnboarding {
///     static var skipOnboarding: Self { SkipOnboarding() }
/// }
/// ```
///
/// ## Order
///
/// Traits are applied in the order they are listed, with a suite's traits before a
/// test's own. `prepare(_:)` and `setUp(_:)` run in that order, and
/// `tearDown(_:)` runs in reverse.
public protocol UITestTrait: Sendable {
    /// Configures the launch of the app, before it is launched.
    ///
    /// Add launch arguments, environment variables or payloads here. Throw `XCTSkip`
    /// to skip the test.
    ///
    /// - Parameter launch: The launch configuration to modify. It already holds the
    ///   changes made by the traits listed before this one.
    func prepare(_ launch: inout LaunchConfiguration) throws

    /// Performs work after the app has launched and before the test body runs.
    ///
    /// - Parameter context: The app and the test that is running.
    @MainActor func setUp(_ context: UITestContext) async throws

    /// Performs work after the test body has finished, whether it passed or failed.
    ///
    /// This is called for every trait whose `setUp(_:)` was called.
    ///
    /// - Parameter context: The app and the test that is running.
    @MainActor func tearDown(_ context: UITestContext) async throws
}

extension UITestTrait {
    public func prepare(_ launch: inout LaunchConfiguration) throws {}

    @MainActor public func setUp(_ context: UITestContext) async throws {}

    @MainActor public func tearDown(_ context: UITestContext) async throws {}
}

extension LaunchConfiguration {
    /// Creates the launch configuration for a UI test by applying each trait in order.
    init(applying traits: [any UITestTrait]) throws {
        self.init()
        for trait in traits {
            try trait.prepare(&self)
        }
        markAsUITesting()
    }
}
