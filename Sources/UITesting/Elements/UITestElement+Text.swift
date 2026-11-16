import XCTest

extension UITestElement where Kind: TextEntryKind {
    /// The text in the field, read without waiting.
    ///
    /// This is an empty string when the field is empty, where `XCUIElement` reports the
    /// field's placeholder. A secure field reports a bullet for each character.
    public var text: String {
        TextEntry.text(value: element.value, placeholder: element.placeholderValue)
    }

    /// Types text at the end of the field, once the field exists and is enabled.
    ///
    /// The field is tapped first, to give it the keyboard.
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
        try wait(toBe: .enabled, inOrderTo: "type into", within: timeout, filePath: filePath, line: line)
        focusAtEnd()
        element.typeText(text)
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
        try clear(within: timeout, filePath: filePath, line: line)
        element.typeText(text)
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
        try wait(toBe: .enabled, inOrderTo: "clear", within: timeout, filePath: filePath, line: line)
        focusAtEnd()

        // Deleting from the cursor can leave text behind if the cursor was not at the
        // end, so check and go again.
        for _ in 0..<3 where !text.isEmpty {
            element.typeText(TextEntry.deletion(of: text))
        }
        guard text.isEmpty else {
            let failure = "Could not clear \(accessibilityIdentifier): it still held \"\(text)\" after deleting"
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }

    /// Gives the field the keyboard, with the cursor after its last character.
    func focusAtEnd() {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tap()
    }
}

extension UITestElement where Kind: SingleLineTextEntryKind {
    /// Presses the Return key in the field, once the field exists and is enabled.
    ///
    /// This is what a person does to finish with a field: it runs the field's submit
    /// action, and in most apps it puts the keyboard away.
    ///
    /// ```swift
    /// try app[SearchID.field].enter("swift")
    /// try app[SearchID.field].submit()
    /// ```
    ///
    /// Multi-line fields do not have this, because Return starts a new line in them.
    /// To put the keyboard away there, see ``XCTest/XCUIApplication/dismissKeyboard(within:filePath:line:)``.
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
        try wait(toBe: .enabled, inOrderTo: "submit", within: timeout, filePath: filePath, line: line)
        focusAtEnd()
        element.typeText(XCUIKeyboardKey.return.rawValue)
    }
}
