import XCTest

extension XCUIElementQuery {
    /// Returns the element in this query that the app gave a typed identifier.
    ///
    /// ```swift
    /// app.buttons[LoginID.signInButton].tap()
    /// app.staticTexts[InboxID.row(1234)].label
    /// ```
    ///
    /// This is the same lookup as the query's subscript that takes a string, with the
    /// string taken from the identifier's `accessibilityIdentifier`.
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript(id: some ElementID) -> XCUIElement {
        self[id.accessibilityIdentifier]
    }
}

extension XCUIElement {
    /// Returns the element inside this one that the app gave a typed identifier,
    /// whatever type of element it is.
    ///
    /// Use it on the app when the type of the element does not matter, or on another
    /// element to look only inside it:
    ///
    /// ```swift
    /// app[LoginID.signInButton].tap()
    /// app[InboxID.row(1234)][MessageRowID.deleteButton].tap()
    /// ```
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript(id: some ElementID) -> XCUIElement {
        descendants(matching: .any)[id.accessibilityIdentifier]
    }
}
