import XCTest

extension UITestElement where Kind: TextEntryKind {
    /// The text in the field, read without waiting.
    ///
    /// This is an empty string when the field is empty, where `XCUIElement` reports the
    /// field's placeholder. A secure field reports a bullet for each character.
    public var text: String {
        TextEntry.text(value: element.value, placeholder: element.placeholderValue)
    }

    // tvOS has no touch screen, so XCTest has no taps, drags or swipes there.
    #if !os(tvOS)
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
        try wait(toBe: .enabled, inOrderTo: "type into", within: timeout, filePath: filePath, line: line)
        element.tap()
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
        element.tap()

        // The result is checked, so this does not depend on where the tap put the cursor.
        let isEmpty = TextEntry.clear(
            text: { text },
            moveToEnd: { tapAfterLastCharacter() },
            type: { element.typeText($0) }
        )
        guard isEmpty else {
            let failure = "Could not clear \(reference.name): it still held \"\(text)\" after deleting"
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }

    /// Taps the trailing corner of the field, which puts the cursor after the last
    /// character in most fields.
    ///
    /// This is a guess about the field's layout, so it is only used by
    /// ``clear(within:filePath:line:)``, which checks what the field holds afterwards.
    private func tapAfterLastCharacter() {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tap()
    }
    #endif
}

#if !os(tvOS)
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
        try wait(toBe: .enabled, inOrderTo: "submit", within: timeout, filePath: filePath, line: line)
        element.tap()
        element.typeText(XCUIKeyboardKey.return.rawValue)
    }
}
#endif
