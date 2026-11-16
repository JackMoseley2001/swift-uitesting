import XCTest

/// The parts of entering text that do not need a running app.
enum TextEntry {
    /// The key that deletes the character before the cursor, as `typeText(_:)` takes it.
    static let deleteKey = XCUIKeyboardKey.delete.rawValue

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
}
