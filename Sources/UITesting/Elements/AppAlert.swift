import XCTest

/// An alert or a confirmation dialog that the app presents.
///
/// SwiftUI gives no way to put an identifier on an alert, so it is reached through
/// the app and not by an identifier:
///
/// ```swift
/// try app[DraftID.deleteButton].tap()
///
/// #expect(app.alert.title == "Delete the draft?")
/// try app.alert.tap("Delete")
/// ```
///
/// `app.alert` is the alert that is showing, and `app.dialog` is the confirmation
/// dialog or action sheet.
///
/// Like the actions of ``UITestElement``, the actions here wait first, for as long as
/// the test's ``UITestTrait/actionTimeout(_:)`` allows, and end the test with a
/// message that says what went wrong. A failed tap lists the buttons there are.
///
/// ## Buttons with identifiers
///
/// A button inside an alert can have an identifier, which does not depend on the
/// language of the app. Look it up in the alert:
///
/// ```swift
/// try app.alert[DraftID.confirmDeleteButton].tap()
/// ```
///
/// XCTest reports a button of an alert twice, one inside the other, so looking the
/// identifier up in the app finds two elements and fails. The lookup in the alert
/// takes the first.
///
/// ## Alerts the system shows
///
/// A request for permission is not part of the app. See ``SystemAlert``.
@MainActor
public struct AppAlert {
    /// The underlying XCTest element.
    public let element: XCUIElement

    /// The app that presents it.
    let app: XCUIApplication

    /// What to call it in the description of a failure.
    let noun: AlertNoun

    /// The area around a dialog shown as a popover, which closes it when tapped.
    let dismissRegion: XCUIElement?

    /// Whether it is showing, read without waiting.
    public var isShowing: Bool {
        element.exists
    }

    /// Its title, read without waiting. Empty if it is not showing.
    public var title: String {
        guard element.exists else { return "" }
        #if os(macOS)
        // On macOS the label of every alert is "alert", and its title is the first text inside it.
        return element.staticTexts.firstMatch.labelOrText
        #elseif os(watchOS)
        // On watchOS an alert is a table, and its title is the first text inside it.
        return element.staticTexts.firstMatch.label
        #else
        return element.label
        #endif
    }

    /// Its message, read without waiting, or `nil` if it has none or is not showing.
    public var message: String? {
        guard element.exists else { return nil }
        let texts = element.staticTexts.allElementsBoundByIndex.map(\.labelOrText)
        return AppAlertText.message(title: title, texts: texts)
    }

    /// The labels of its buttons in order, read without waiting. Empty if it is not showing.
    public var buttons: [String] {
        element.exists ? buttonElements().map(\.info.label) : []
    }

    /// Returns the element inside the alert or dialog that the app gave a typed identifier.
    ///
    /// ```swift
    /// try app.alert[DraftID.confirmDeleteButton].tap()
    /// ```
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript<Kind: ElementKind>(id: ElementID<Kind>) -> UITestElement<Kind> {
        let identifier = id.accessibilityIdentifier
        let type = XCUIElement.ElementType(Kind.elementType)
        return UITestElement(
            element: element.descendants(matching: type).matching(identifier: identifier).firstMatch,
            accessibilityIdentifier: identifier,
            elementOfAnyKind: Kind.elementType == .any
                ? nil : element.descendants(matching: .any).matching(identifier: identifier).firstMatch,
            scope: element,
            app: app
        )
    }

    /// Waits for it to show.
    ///
    /// - Parameter timeout: How long to wait. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if it does not show in time. The failure is
    ///   recorded at the line of the call, and the test ends.
    public func waitToAppear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let article = noun == .alert ? "an" : "a"
        try wait(inOrderTo: "find \(article) \(noun.full)", within: timeout, filePath: filePath, line: line)
    }

    /// Waits for it to go away.
    ///
    /// - Parameter timeout: How long to wait. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if it is still showing when the time is up.
    ///   The failure is recorded at the line of the call, and the test ends.
    public func waitToDisappear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let timeout = timeout ?? ActionTimeout.current
        let title = title
        guard ExpectationPolling().wait(timeout: timeout, until: { !element.exists }) == .met else {
            try fail(
                SystemAlertChoice.alertStayed(titled: title, after: timeout, noun: noun),
                filePath: filePath,
                line: line
            )
        }
    }

    // tvOS has no touch screen, so XCTest has no taps, drags or swipes there.
    #if !os(tvOS)
    /// Taps the button with a label, once it is showing.
    ///
    /// ```swift
    /// try app.alert.tap("Delete")
    /// ```
    ///
    /// - Parameters:
    ///   - label: The label of the button, as it is shown.
    ///   - timeout: How long to wait for the alert or dialog. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if it does not show in time, or has no
    ///   button with this label. The failure is recorded at the line of the call, and
    ///   the test ends.
    public func tap(
        _ label: String,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(.label(label), within: timeout, filePath: filePath, line: line)
    }

    /// Taps the button at a position, once it is showing.
    ///
    /// The position counts from 0 in the order of ``buttons``.
    ///
    /// - Parameters:
    ///   - index: The position of the button.
    ///   - timeout: How long to wait for the alert or dialog. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if it does not show in time, or has no
    ///   button at this position. The failure is recorded at the line of the call, and
    ///   the test ends.
    public func tapButton(
        at index: Int,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(.index(index), within: timeout, filePath: filePath, line: line)
    }

    /// Closes a dialog without choosing any of its buttons, once it is showing.
    ///
    /// A dialog that is shown as a popover has no button to cancel with. It is closed
    /// by a tap outside it, which is what this does.
    ///
    /// ```swift
    /// try app.dialog.dismiss()
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the dialog. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if it does not show in time, or cannot be
    ///   closed by a tap outside it, as an alert cannot. The failure is recorded at the
    ///   line of the call, and the test ends.
    public func dismiss(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(inOrderTo: "dismiss the \(noun.full)", within: timeout, filePath: filePath, line: line)
        guard let dismissRegion, dismissRegion.exists else {
            let listed = buttons.map { "\"\($0)\"" }.joined(separator: ", ")
            try fail(
                "Could not dismiss the \(noun.full) \"\(title)\": it does not close when tapped outside. "
                    + "Tap one of its buttons: \(listed)",
                filePath: filePath,
                line: line
            )
        }
        dismissRegion.tapOrClick()
        _ = ExpectationPolling().wait(timeout: .seconds(2), until: { !element.exists })
    }

    private func tap(
        _ button: SystemAlertButton,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws {
        let article = noun == .alert ? "an" : "a"
        try wait(
            inOrderTo: "tap \(button.description) in \(article) \(noun.full)",
            within: timeout,
            filePath: filePath,
            line: line
        )

        let buttons = buttonElements()
        let choice = SystemAlertChoice.position(
            of: button,
            inAlertTitled: title,
            withButtons: buttons.map(\.info),
            noun: noun
        )
        switch choice {
        case .success(let position): buttons[position].element.tapOrClick()
        case .failure(let error): try fail(error.message, filePath: filePath, line: line)
        }
    }
    #endif

    private func wait(
        inOrderTo intent: String,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws {
        let timeout = timeout ?? ActionTimeout.current
        guard ExpectationPolling().wait(timeout: timeout, until: { element.exists }) == .met else {
            try fail(
                SystemAlertChoice.noAlert(inOrderTo: intent, after: timeout, noun: noun),
                filePath: filePath,
                line: line
            )
        }
    }

    /// The buttons in order, without the repeats that XCTest reports.
    private func buttonElements() -> [(element: XCUIElement, info: SystemAlertButtonInfo)] {
        let elements = element.buttons.allElementsBoundByIndex
        let infos = elements.map { SystemAlertButtonInfo(label: $0.label, identifier: $0.identifier) }
        return SystemAlertChoice.positionsWithoutRepeats(in: infos).map { (elements[$0], infos[$0]) }
    }

    /// Records a failure at the line of the call and ends the test.
    private func fail(_ message: String, filePath: StaticString, line: UInt) throws -> Never {
        ExpectationReporter.report(message: message, filePath: filePath, line: line)
        throw RequirementFailedError(message: message)
    }
}

extension XCUIApplication {
    /// The alert that the app is showing, or the next one it shows.
    ///
    /// ```swift
    /// try app.alert.tap("Delete")
    /// ```
    @MainActor
    public var alert: AppAlert {
        #if os(macOS)
        // On macOS an alert is a sheet on the window, as a confirmation dialog is.
        AppAlert(element: sheets.firstMatch, app: self, noun: .alert, dismissRegion: nil)
        #elseif os(watchOS)
        AppAlert(element: watchAlertTable, app: self, noun: .alert, dismissRegion: nil)
        #else
        AppAlert(element: alerts.firstMatch, app: self, noun: .alert, dismissRegion: nil)
        #endif
    }

    /// The confirmation dialog or action sheet that the app is showing, or the next one it shows.
    ///
    /// ```swift
    /// try app.dialog.tap("Discard")
    /// ```
    @MainActor
    public var dialog: AppAlert {
        #if os(watchOS)
        // The button that cancels a dialog is not among its buttons on watchOS. It is
        // a button to close the dialog, in the bar above it.
        AppAlert(
            element: watchAlertTable,
            app: self,
            noun: .dialog,
            dismissRegion: buttons[AppAlertText.watchCloseButtonIdentifier].firstMatch
        )
        #else
        AppAlert(
            element: sheets.firstMatch,
            app: self,
            noun: .dialog,
            dismissRegion: descendants(matching: .any)["PopoverDismissRegion"].firstMatch
        )
        #endif
    }

    #if os(watchOS)
    /// The table that holds the text and buttons of an alert or a dialog on watchOS.
    ///
    /// watchOS shows both as a screen of its own, with a bar that has this identifier
    /// in every language, and reports neither as an alert or a sheet.
    @MainActor
    private var watchAlertTable: XCUIElement {
        otherElements
            .containing(.navigationBar, identifier: AppAlertText.watchAlertBarIdentifier)
            .firstMatch
            .tables
            .firstMatch
    }
    #endif
}

/// The parts of reading an alert that do not need a running app.
enum AppAlertText {
    /// The identifier of the bar above an alert or a dialog on watchOS.
    static let watchAlertBarIdentifier = "PUICActionContentChild"

    /// The identifier of the button that closes a dialog on watchOS.
    static let watchCloseButtonIdentifier = "AX_ActionContentControllerCancelButton"

    /// Returns the message of an alert from the text inside it.
    ///
    /// The title is the first text and the message is the one after it.
    static func message(title: String, texts: [String]) -> String? {
        // watchOS reports the title a second time, after the message.
        let rest = texts.first == title ? Array(texts.dropFirst()) : texts
        return rest.first { !$0.isEmpty && $0 != title }
    }
}
