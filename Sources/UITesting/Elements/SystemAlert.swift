// System alerts belong to SpringBoard, which is only on iOS and iPadOS.
#if os(iOS)
import XCTest

/// An alert that the system shows over the app, such as a request for permission.
///
/// The alert is not part of the app, so it cannot be found with the app's
/// identifiers. Use ``current`` to reach the one that is showing:
///
/// ```swift
/// @UITest(traits: .resetAuthorization(for: .microphone))
/// func recordsAfterAccessIsAllowed(app: XCUIApplication) throws {
///     try app[RecorderID.recordButton].tap()
///     try SystemAlert.current.allow()
///
///     #expect(app[RecorderID.status].label == "Recording")
/// }
/// ```
///
/// Like the actions of ``UITestElement``, the actions here wait first, for as long as
/// the test's ``UITestTrait/actionTimeout(_:)`` allows, and end the test with a
/// message that says what went wrong.
///
/// ## Choosing a button
///
/// Some alerts say which of their buttons allows and which refuses. For those,
/// ``allow(within:filePath:line:)`` and ``deny(within:filePath:line:)`` work in any
/// language. On iOS 27.2 these are the alerts for the camera, the microphone and
/// photos, and the alert for contacts for refusing only.
///
/// The alerts for location and notifications do not say, and neither do buttons such
/// as "Allow Once". For those, use ``tap(_:within:filePath:line:)`` with the label.
/// The system writes the labels in the language of the device, not the language the
/// app was launched in, and they can change between versions of iOS. A failed tap
/// lists the labels the alert has. ``tapButton(at:within:filePath:line:)`` chooses by
/// position instead.
///
/// ## Answering without a call
///
/// The ``UITestTrait/systemAlerts(_:for:)`` trait answers alerts for a whole test or
/// suite, so that the test does not have to.
///
/// ## After a failure
///
/// A permission alert stays on the screen after the app that asked has ended. If a
/// test fails while one is showing, and the alert says which button refuses, it is
/// refused, so that the next test does not start underneath it.
///
/// ## Alerts the app shows
///
/// An alert that the app presents itself is part of the app. Give its buttons
/// identifiers and look them up in the app as usual.
@MainActor
public struct SystemAlert {
    /// The underlying XCTest element.
    public let element: XCUIElement

    /// The system alert that is showing, or the next one to show.
    public static var current: SystemAlert {
        SystemAlert(element: XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch)
    }

    /// Whether a system alert is showing, read without waiting.
    public var isShowing: Bool {
        element.exists
    }

    /// The title of the alert, read without waiting. Empty if no alert is showing.
    public var title: String {
        element.exists ? element.label : ""
    }

    /// The labels of the alert's buttons in order, read without waiting. Empty if no
    /// alert is showing.
    public var buttons: [String] {
        element.exists ? buttonElements().map(\.info.label) : []
    }

    /// Taps the button that gives the app what it asked for, once the alert is showing.
    ///
    /// The button is found by the identifier the system gives it, so this does not
    /// depend on the language of the device. On an alert with several ways to allow,
    /// such as the one for location, use ``tap(_:within:filePath:line:)`` to say which.
    ///
    /// - Parameter timeout: How long to wait for the alert. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if no alert shows in time, or the alert does
    ///   not say which button allows. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func allow(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(.allow, within: timeout, filePath: filePath, line: line)
    }

    /// Taps the button that refuses what the app asked for, once the alert is showing.
    ///
    /// The button is found by the identifier the system gives it, so this does not
    /// depend on the language of the device.
    ///
    /// - Parameter timeout: How long to wait for the alert. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if no alert shows in time, or the alert does
    ///   not say which button refuses. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func deny(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(.deny, within: timeout, filePath: filePath, line: line)
    }

    /// Waits for a system alert to show.
    ///
    /// - Parameter timeout: How long to wait for the alert. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if no alert shows in time. The failure is
    ///   recorded at the line of the call, and the test ends.
    public func waitToAppear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(inOrderTo: "find a system alert", within: timeout, filePath: filePath, line: line)
    }

    /// Waits for the system alert to go away.
    ///
    /// - Parameter timeout: How long to wait for the alert to go. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if an alert is still showing when the time
    ///   is up. The failure is recorded at the line of the call, and the test ends.
    public func waitToDisappear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let timeout = timeout ?? ActionTimeout.current
        let title = title
        guard ExpectationPolling().wait(timeout: timeout, until: { !element.exists }) == .met else {
            try fail(SystemAlertChoice.alertStayed(titled: title, after: timeout), filePath: filePath, line: line)
        }
    }

    /// Taps the button with a label, once the alert is showing.
    ///
    /// ```swift
    /// try SystemAlert.current.tap("Don’t Allow")
    /// ```
    ///
    /// The label has to match exactly. The system uses a typographic apostrophe in
    /// labels such as "Don’t Allow".
    ///
    /// - Parameters:
    ///   - label: The label of the button, as the alert shows it.
    ///   - timeout: How long to wait for the alert. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if no alert shows in time, or the alert has
    ///   no button with this label. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func tap(
        _ label: String,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(.label(label), within: timeout, filePath: filePath, line: line)
    }

    /// Taps the button at a position, once the alert is showing.
    ///
    /// The position counts from 0 in the order of ``buttons``.
    ///
    /// ```swift
    /// try SystemAlert.current.tapButton(at: 1)
    /// ```
    ///
    /// - Parameters:
    ///   - index: The position of the button.
    ///   - timeout: How long to wait for the alert. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if no alert shows in time, or the alert has
    ///   no button at this position. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func tapButton(
        at index: Int,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(.index(index), within: timeout, filePath: filePath, line: line)
    }

    private func tap(
        _ button: SystemAlertButton,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws {
        try wait(
            inOrderTo: "tap \(button.description) in a system alert",
            within: timeout,
            filePath: filePath,
            line: line
        )

        let buttons = buttonElements()
        let choice = SystemAlertChoice.position(
            of: button,
            inAlertTitled: element.label,
            withButtons: buttons.map(\.info)
        )
        switch choice {
        case .success(let position): buttons[position].element.tap()
        case .failure(let error): try fail(error.message, filePath: filePath, line: line)
        }
    }

    /// Answers the alert as the rules say, if it is showing and a rule is for it.
    ///
    /// - Returns: Whether a button was tapped.
    @discardableResult
    func answer(with rules: SystemAlertRules) -> Bool {
        guard element.exists else { return false }
        let buttons = buttonElements()
        let position = rules.positionOfButton(
            inAlertWithIdentifier: element.identifier,
            buttons: buttons.map(\.info)
        )
        guard let position else { return false }
        buttons[position].element.tap()
        return true
    }

    /// Refuses a permission alert that a failed test left showing.
    ///
    /// The alert outlives the app that asked, so it would otherwise still be there when
    /// the next test starts. An alert that does not say which button refuses is left alone.
    static func refuseLeftover() {
        let alert = current
        guard alert.element.exists else { return }
        let buttons = alert.buttonElements()
        let choice = SystemAlertChoice.position(of: .deny, inAlertTitled: "", withButtons: buttons.map(\.info))
        if case .success(let position) = choice {
            buttons[position].element.tap()
        }
    }

    /// The alert's buttons in order, without the repeats that the system reports.
    private func buttonElements() -> [(element: XCUIElement, info: SystemAlertButtonInfo)] {
        let elements = element.buttons.allElementsBoundByIndex
        let infos = elements.map { SystemAlertButtonInfo(label: $0.label, identifier: $0.identifier) }
        return SystemAlertChoice.positionsWithoutRepeats(in: infos).map { (elements[$0], infos[$0]) }
    }

    private func wait(
        inOrderTo intent: String,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws {
        let timeout = timeout ?? ActionTimeout.current
        guard ExpectationPolling().wait(timeout: timeout, until: { element.exists }) == .met else {
            try fail(SystemAlertChoice.noAlert(inOrderTo: intent, after: timeout), filePath: filePath, line: line)
        }
    }

    /// Records a failure at the line of the call and ends the test.
    private func fail(_ message: String, filePath: StaticString, line: UInt) throws -> Never {
        ExpectationReporter.report(message: message, filePath: filePath, line: line)
        throw RequirementFailedError(message: message)
    }
}
#endif
