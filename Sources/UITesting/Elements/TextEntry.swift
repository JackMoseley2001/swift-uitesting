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

    /// Returns how many times the key that goes down a line is pressed to take the
    /// cursor from anywhere in the given text to its end.
    ///
    /// It is once for each line, because the key takes the cursor of the last line to
    /// the end of it. A line that is too long for the field takes more, which a later
    /// round of ``clear(text:moveToEnd:type:)`` makes up for.
    static func downKeys(toEndOf text: String) -> Int {
        text.split(separator: "\n", omittingEmptySubsequences: false).count
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
}
