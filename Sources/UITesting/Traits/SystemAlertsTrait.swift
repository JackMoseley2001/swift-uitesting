import XCTest

/// A trait that says how to answer a system alert.
protocol SystemAlertAnswering {
    /// The answer, and the alerts it is for.
    var systemAlertRule: SystemAlertRule { get }
}

/// A trait that answers the system's alerts for a test.
///
/// Create one with ``UITestTrait/systemAlerts(_:for:)``.
public struct SystemAlertsTrait: UITestTrait, SystemAlertAnswering {
    /// How the alerts are answered.
    public let answer: SystemAlertAnswer

    /// The resources that are reset before the launch, and whose alerts are answered.
    /// Empty if every alert is answered.
    public let resources: [XCUIProtectedResource]

    var systemAlertRule: SystemAlertRule {
        let services = resources.map(\.systemAlertService)
        // The alert for a resource without a name cannot be told from the others, so
        // the rule is for every alert.
        return SystemAlertRule(answer: answer, services: services.contains(nil) ? [] : services.compactMap { $0 })
    }

    @MainActor
    public func willLaunch(_ context: UITestContext) async throws {
        for resource in resources {
            context.app.resetAuthorizationStatus(for: resource)
        }
    }
}

extension UITestTrait where Self == SystemAlertsTrait {
    /// Answers the system's alerts for the test, so that the test does not have to.
    ///
    /// ```swift
    /// @UITest(traits: .systemAlerts(.allow, for: .microphone, .camera))
    /// func recordsAVideo(app: XCUIApplication) throws {
    ///     try app[RecorderID.recordButton].tap()
    ///
    ///     #expect(app[RecorderID.status].label == "Recording", within: .seconds(5))
    /// }
    /// ```
    ///
    /// With resources, the trait also resets the app's authorization for them before
    /// the launch, as ``UITestTrait/resetAuthorization(for:)`` does, so that the system
    /// asks again and gets this answer. Without resources, it answers every alert that
    /// it can and resets nothing.
    ///
    /// ## Which alerts it can answer
    ///
    /// `.allow` and `.deny` work in any language, on the alerts that say which of their
    /// buttons allows and which refuses. On iOS 27.2 these are the alerts for the
    /// camera, the microphone and photos, and the alert for contacts for `.deny` only.
    ///
    /// The alerts for location and notifications do not say. Answer them by label,
    /// which is in the language of the device:
    ///
    /// ```swift
    /// @UITest(traits: .systemAlerts(.button("Allow While Using App"), for: .location))
    /// ```
    ///
    /// ## Which alerts a trait is for
    ///
    /// A trait for the camera, the microphone, photos or contacts answers only the
    /// alerts for the resources it names. The alerts for other resources cannot be
    /// told apart, so a trait that names one of those answers every alert that has
    /// its button.
    ///
    /// ## Several traits
    ///
    ///
    /// A test can give several, and can override its suite. The last one that is for
    /// an alert, and whose button the alert has, decides:
    ///
    /// ```swift
    /// @UITestSuite(traits: .systemAlerts(.allow))
    /// final class RecorderTests: XCTestCase {
    ///     @UITest(traits: .systemAlerts(.deny, for: .microphone))
    ///     func explainsThatItNeedsTheMicrophone(app: XCUIApplication) throws { /* ... */ }
    /// }
    /// ```
    ///
    /// An alert is answered while an action or an expectation of this library waits,
    /// and when it gets in the way of an action on the app. An alert that no trait
    /// answers is left for the test to answer with ``SystemAlert``.
    ///
    /// - Parameters:
    ///   - answer: Whether to allow, to refuse, or to tap a button with a label.
    ///   - resources: The resources to reset and to answer for, such as `.microphone`.
    ///     Leave them out to answer every alert and reset nothing.
    public static func systemAlerts(_ answer: SystemAlertAnswer, for resources: XCUIProtectedResource...) -> Self {
        SystemAlertsTrait(answer: answer, resources: resources)
    }
}

extension XCUIProtectedResource {
    /// The name the system gives this resource in the identifier of its alert, or
    /// `nil` if its alert has no identifier or has not been checked.
    var systemAlertService: String? {
        switch self {
        case .camera: "kTCCServiceCamera"
        case .microphone: "kTCCServiceMicrophone"
        case .photos: "kTCCServicePhotos"
        case .contacts: "kTCCServiceAddressBook"
        default: nil
        }
    }
}
