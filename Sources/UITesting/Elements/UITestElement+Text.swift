import XCTest

extension UITestElement where Kind: TextEntryKind {
    /// The text in the field, read without waiting.
    ///
    /// This is an empty string when the field is empty, where `XCUIElement` reports the
    /// field's placeholder. A secure field reports a bullet for each character.
    public var text: String {
        TextEntry.text(value: element.value, placeholder: element.placeholderValue)
    }

    /// Types text into the field, once the field exists and is enabled.
    ///
    /// The field is tapped first, to give it the keyboard. In a field that already
    /// holds text, the new text goes in wherever that tap puts the cursor, which is
    /// usually the end but is not certain. Use ``replaceText(with:within:filePath:line:)``
    /// to be sure of what the field holds afterwards.
    ///
    /// ```swift
    /// try app[LoginID.emailField].enter("ada@example.com")
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to type.
    ///   - timeout: How long to wait for the field. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the field is not ready in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func enter(
        _ text: String,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let keyboard = try focus(inOrderTo: "type into", within: timeout, filePath: filePath, line: line)
        keyboard.type(text)
        keyboard.finish()
    }

    /// Replaces whatever is in the field with new text, once the field exists and is enabled.
    ///
    /// ```swift
    /// try app[ProfileID.nameField].replaceText(with: "Grace Hopper")
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text the field should hold afterwards.
    ///   - timeout: How long to wait for the field. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the field is not ready in time, or could
    ///   not be cleared. The failure is recorded at the line of the call, and the test ends.
    public func replaceText(
        with text: String,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let keyboard = try focus(inOrderTo: "replace the text of", within: timeout, filePath: filePath, line: line)
        guard empty(with: keyboard) else {
            keyboard.finish()
            try failToClear(filePath: filePath, line: line)
        }
        keyboard.type(text)
        keyboard.finish()
    }

    /// Deletes whatever is in the field, once the field exists and is enabled.
    ///
    /// - Parameter timeout: How long to wait for the field. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the field is not ready in time, or could
    ///   not be cleared. The failure is recorded at the line of the call, and the test ends.
    public func clear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let keyboard = try focus(inOrderTo: "clear", within: timeout, filePath: filePath, line: line)
        let isEmpty = empty(with: keyboard)
        keyboard.finish()
        guard isEmpty else { try failToClear(filePath: filePath, line: line) }
    }

    /// Deletes whatever is in the field, and returns whether it ended up empty.
    ///
    /// The result is checked, so this does not depend on where the tap put the cursor.
    private func empty(with keyboard: TextKeyboard) -> Bool {
        TextEntry.clear(
            text: keyboard.text,
            moveToEnd: keyboard.moveToEnd,
            selectAll: keyboard.selectAll,
            type: keyboard.type
        )
    }

    private func failToClear(filePath: StaticString, line: UInt) throws -> Never {
        let failure = "Could not clear \(reference.name): it still held \"\(text)\" after deleting"
        ExpectationReporter.report(message: failure, filePath: filePath, line: line)
        throw RequirementFailedError(message: failure)
    }

    /// Waits for the field and taps it, and returns what to type into.
    ///
    /// On watchOS a field cannot be typed into where it is. A tap on it opens a screen
    /// with a keyboard and a text view, and the field has the text when that screen is
    /// closed with its button for done. Everywhere else the field itself is typed into.
    fileprivate func focus(
        inOrderTo intent: String,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws -> TextKeyboard {
        try wait(toBe: readiness, inOrderTo: intent, within: timeout, filePath: filePath, line: line)
        #if os(tvOS) || os(watchOS)
        // The keyboard of tvOS and the screen to type on of watchOS belong to the app,
        // not to the field.
        let app = try owningApp(inOrderTo: intent, filePath: filePath, line: line)
        #endif
        #if os(tvOS)
        // On tvOS a field that is selected opens a keyboard that fills the screen, with
        // a text view of its own. The field has the text as it is typed, and the
        // remote's menu button closes the keyboard.
        try moveFocus(inOrderTo: intent, filePath: filePath, line: line)
        XCUIRemote.shared.press(.select)
        let keyboard = app.keyboards.firstMatch
        let timeout = timeout ?? ActionTimeout.current
        guard ExpectationPolling().wait(timeout: timeout, until: { keyboard.exists }) == .met else {
            let failure = "Could not \(intent) \(reference.name): "
                + "the keyboard did not show within \(ExpectationFailure.describe(timeout))"
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
        return TextKeyboard(
            text: { text },
            type: { app.typeText($0) },
            // The cursor is at the end of the text when the keyboard opens.
            moveToEnd: {},
            finish: {
                guard keyboard.exists else { return }
                XCUIRemote.shared.press(.menu)
                _ = ExpectationPolling().wait(timeout: .seconds(2), until: { !keyboard.exists })
            }
        )
        #else
        element.tapOrClick()
        #endif
        #if os(watchOS)
        let host = app.otherElements[TextEntry.watchInputIdentifier].firstMatch
        let view = host.textViews.firstMatch
        let timeout = timeout ?? ActionTimeout.current
        // A tap on a field of a screen that has just shown is sometimes lost, and the
        // screen to type on never opens. The field is tapped again while it is still
        // the one on the screen.
        let showed = TextEntry.waitForInput(
            within: timeout,
            isShowing: { view.exists },
            tapAgain: { if !host.exists, element.exists { element.tapOrClick() } }
        )
        guard showed else {
            let failure = "Could not \(intent) \(reference.name): "
                + "the screen to type on did not show within \(ExpectationFailure.describe(timeout))"
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
        return TextKeyboard(
            text: { TextEntry.text(value: view.value, placeholder: view.placeholderValue) },
            type: { view.typeText($0) },
            moveToEnd: { view.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tap() },
            finish: {
                // The buttons of the bar are the one to cancel and then the one for done.
                let buttons = host.navigationBars.buttons
                buttons.element(boundBy: buttons.count - 1).tap()
                _ = ExpectationPolling().wait(timeout: .seconds(2), until: { !host.exists })
            }
        )
        #elseif !os(tvOS)
        return TextKeyboard(
            text: { text },
            type: { element.typeText($0) },
            moveToEnd: { tapAfterLastCharacter() },
            finish: {},
            selectAll: selectAll
        )
        #endif
    }

    /// What the field has to be before it is typed into.
    ///
    /// On macOS a text view reports that it is disabled even when it can be typed
    /// into, so there it only has to exist.
    private var readiness: ElementRequirement {
        #if os(macOS)
        Kind.elementType == .textView ? .exists : .enabled
        #else
        .enabled
        #endif
    }

    #if !os(tvOS)
    /// Moves the cursor towards the end of the text, with a tap on the trailing corner
    /// of the field, which puts the cursor after the last character in most fields.
    ///
    /// This is a guess about the field's layout, so it is only used by
    /// ``clear(within:filePath:line:)``, which checks what the field holds afterwards.
    /// Selects all of the text with the keyboard, on visionOS only.
    ///
    /// Before visionOS 26 the keys that go to the end of the text do not move the
    /// cursor of an editor for several lines, so its text is selected to be deleted.
    private var selectAll: (() -> Void)? {
        #if os(visionOS)
        { element.typeKey(XCUIKeyboardKey(rawValue: "a"), modifierFlags: .command) }
        #else
        nil
        #endif
    }

    private func tapAfterLastCharacter() {
        #if os(visionOS)
        // On visionOS a tap in a field puts the cursor at the start of the text, and a
        // tap away from the text takes the keyboard from the field. The keys that go
        // to the end of the text are used there.
        element.typeKey(.downArrow, modifierFlags: .command)
        #else
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tapOrClick()
        #endif
    }
    #endif
}

extension UITestElement where Kind: SingleLineTextEntryKind {
    /// Presses the Return key in the field, once the field exists and is enabled.
    ///
    /// This runs the field's submit action, as it does for a person.
    ///
    /// ```swift
    /// try app[SearchID.field].enter("swift")
    /// try app[SearchID.field].submit()
    /// ```
    ///
    /// Multi-line fields do not have this, because Return starts a new line in them.
    ///
    /// - Parameter timeout: How long to wait for the field. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the field is not ready in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func submit(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let keyboard = try focus(inOrderTo: "submit", within: timeout, filePath: filePath, line: line)
        // On watchOS the field is submitted when the screen to type on is closed.
        #if !os(watchOS)
        keyboard.type(XCUIKeyboardKey.return.rawValue)
        #endif
        // On tvOS Return closes the keyboard, and finishing does nothing more.
        keyboard.finish()
    }
}

/// What text is typed into, once a field has been tapped.
struct TextKeyboard {
    /// Reads the text that is there.
    let text: () -> String

    /// Types keys.
    let type: (String) -> Void

    /// Moves the cursor towards the end of the text.
    let moveToEnd: () -> Void

    /// Ends the typing. On watchOS this closes the screen to type on.
    let finish: () -> Void

    /// Selects all of the text, where the platform has a way to that does not depend
    /// on where the cursor is.
    var selectAll: (() -> Void)?
}
