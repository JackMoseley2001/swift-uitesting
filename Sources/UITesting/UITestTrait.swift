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
/// It can do something with the app just before it launches:
///
/// ```swift
/// struct ForgetPhotosAccess: UITestTrait {
///     func willLaunch(_ context: UITestContext) async throws {
///         context.app.resetAuthorizationStatus(for: .photos)
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
/// test's own. `prepare(_:)`, `willLaunch(_:)` and `setUp(_:)` run in that order, and
/// `tearDown(_:)` runs in reverse.
///
/// Each step runs for every trait before the next step starts: every trait prepares
/// the launch, then every trait's `willLaunch(_:)` runs, then the app is launched,
/// and then every trait is set up.
public protocol UITestTrait: Sendable {
    /// Configures the launch of the app, before it is launched.
    ///
    /// Add launch arguments, environment variables or payloads here. Throw `XCTSkip`
    /// to skip the test.
    ///
    /// - Parameter launch: The launch configuration to modify. It already holds the
    ///   changes made by the traits listed before this one.
    func prepare(_ launch: inout LaunchConfiguration) throws

    /// Performs work just before the app is launched.
    ///
    /// The app in the context has its launch arguments and environment set, but is
    /// not running yet. Use this for work that has to be done before the app starts
    /// and needs the app or the test case, such as resetting a permission.
    ///
    /// If this throws, the app is not launched and the test fails.
    ///
    /// This is called once, before the first launch. It is not called again by
    /// ``UITestContext/relaunch(with:)``. In a test with the
    /// ``UITestTrait/manualLaunch`` trait, it is called before the test body.
    ///
    /// If this throws, `tearDown(_:)` is still called for this trait and for the
    /// traits before it, so work done here can be undone there.
    ///
    /// - Parameter context: The app and the test that is running.
    @MainActor func willLaunch(_ context: UITestContext) async throws

    /// Performs work after the app has launched and before the test body runs.
    ///
    /// - Parameter context: The app and the test that is running.
    @MainActor func setUp(_ context: UITestContext) async throws

    /// Performs work after the test body has finished, whether it passed or failed.
    ///
    /// This is called for every trait whose `willLaunch(_:)` was called, in reverse
    /// order. That is every trait, unless a trait's `willLaunch(_:)` threw: then it
    /// is called for that trait and the ones before it, and `setUp(_:)` has not run
    /// for any of them.
    ///
    /// - Parameter context: The app and the test that is running.
    @MainActor func tearDown(_ context: UITestContext) async throws
}

extension UITestTrait {
    public func prepare(_ launch: inout LaunchConfiguration) throws {}

    @MainActor public func willLaunch(_ context: UITestContext) async throws {}

    @MainActor public func setUp(_ context: UITestContext) async throws {}

    @MainActor public func tearDown(_ context: UITestContext) async throws {}
}

extension LaunchConfiguration {
    /// Creates the launch configuration for a UI test by applying each trait in order.
    init(applying traits: [any UITestTrait]) throws {
        self = try LaunchConfiguration().applying(traits)
    }

    /// Returns a copy of this configuration with each trait applied in order, on top of what it already holds.
    func applying(_ traits: [any UITestTrait]) throws -> LaunchConfiguration {
        var launch = self
        for trait in traits {
            try trait.prepare(&launch)
        }
        launch.markAsUITesting()
        return launch
    }
}
