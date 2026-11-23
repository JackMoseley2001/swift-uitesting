import XCTest

/// The parts of entering text that do not need a running app.
enum TextEntry {
    /// The key that deletes the character before the cursor, as `typeText(_:)` takes it.
    static let deleteKey = XCUIKeyboardKey.delete.rawValue

    /// The identifier of the screen that watchOS shows to type into a field.
    static let watchInputIdentifier = "TextInputHost"

    /// Returns the text in a field from what XCTest reports for it.
    ///
    /// An empty field reports its placeholder as its value, so a value that is the same
    /// as the placeholder is read as no text.
    static func text(value: Any?, placeholder: String?) -> String {
        guard let value = value as? String else { return "" }
        if let placeholder, !placeholder.isEmpty, value == placeholder { return "" }
        return value
    }

    /// Returns the keys to type to delete the given text, with the cursor at its end.
    static func deletion(of text: String) -> String {
        String(repeating: deleteKey, count: text.count)
    }

    /// Empties a field without relying on where its cursor is.
    ///
    /// Deleting removes what is before the cursor. The first round deletes from
    /// wherever the cursor is. If text is left, it was after the cursor, so each later
    /// round moves the cursor towards the end first. It stops when the field is
    /// empty, or when a round that moved the cursor removed nothing.
    ///
    /// - Parameters:
    ///   - text: Reads the text in the field.
    ///   - moveToEnd: Moves the cursor towards the end of the text.
    ///   - type: Types keys into the field.
    /// - Returns: Whether the field ended up empty.
    static func clear(text: () -> String, moveToEnd: () -> Void, type: (String) -> Void) -> Bool {
        var remaining = text()
        var hasMoved = false
        while !remaining.isEmpty {
            type(deletion(of: remaining))

            let now = text()
            if now.count >= remaining.count, hasMoved { return false }
            remaining = now
            if !remaining.isEmpty {
                moveToEnd()
                hasMoved = true
            }
        }
        return true
    }

    /// How long the screen to type on is waited for before the field is tapped again.
    static let inputPatience = Duration.seconds(4)

    /// Waits for the screen to type on that watchOS opens when a field is tapped, and
    /// taps the field again each time the screen has not shown for a while.
    ///
    /// - Parameters:
    ///   - timeout: How long to wait for the screen in all.
    ///   - polling: What checks for the screen.
    ///   - isShowing: Whether the screen to type on is showing.
    ///   - tapAgain: Taps the field again.
    /// - Returns: Whether the screen showed.
    static func waitForInput(
        within timeout: Duration,
        polling: ExpectationPolling = ExpectationPolling(),
        isShowing: () -> Bool,
        tapAgain: () -> Void
    ) -> Bool {
        var remaining = timeout
        while true {
            let patience = min(inputPatience, remaining)
            if polling.wait(timeout: patience, until: isShowing) == .met { return true }
            remaining -= patience
            guard remaining > .zero else { return false }
            tapAgain()
        }
    }
}
