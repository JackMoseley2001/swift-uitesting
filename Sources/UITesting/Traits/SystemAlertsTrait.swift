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
        if let problem = Self.problem(with: systemAlertRule, marked: SystemAlertChoice.systemMarksAlerts) {
            throw SystemAlertChoiceError(message: problem)
        }
        if !SystemAlertChoice.systemMarksAlerts, !systemAlertRule.services.isEmpty {
            // The test's log says why the alert was left, for whoever reads a failure.
            XCTContext.runActivity(named: Self.notAnsweredNote) { _ in }
        }
    }

    /// Returns what is wrong with a rule that could answer no alert on this system,
    /// or `nil` if it can.
    ///
    /// `.allow` and `.deny` with nothing to fall back on need an alert that marks its
    /// buttons, which none does before iOS 27. A rule for named resources is left
    /// alone, because it answers nothing there in any case.
    static func problem(with rule: SystemAlertRule, marked: Bool) -> String? {
        guard !marked, rule.services.isEmpty, rule.answer.button.needsMarkedButtons else { return nil }
        let name = rule.answer == .allow ? "allow" : "deny"
        return "The .systemAlerts(.\(name)) trait cannot answer an alert before iOS 27, where no alert says "
            + "which button allows or refuses. Give a label or a position to fall back on, "
            + "as in .systemAlerts(.\(name)(orTapButtonAt: \(name == "allow" ? 1 : 0)))"
    }

    /// What the test's log says where a trait for named resources answers nothing.
    static let notAnsweredNote =
        "The .systemAlerts trait for named resources answers alerts from iOS 27 only. "
        + "Answer the alert in the test with SystemAlert.current"
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
    /// Before iOS 27 no alert says which of its buttons allows. Give `.allow` and
    /// `.deny` a label or a position to fall back on there, as in
    /// `.systemAlerts(.allow(orTapButtonAt: 1))`. Without one, the test fails before
    /// the launch with a message that says so.
    ///
    /// With resources, the trait answers alerts from iOS 27 only. Before that an alert
    /// does not say which resource it asks for, so the trait resets the resources and
    /// leaves the alert for the test to answer with ``SystemAlert``. Without resources
    /// it answers every alert on any version.
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
