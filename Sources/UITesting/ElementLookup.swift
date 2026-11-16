import XCTest

extension XCUIElement {
    /// Returns the element inside this one that the app gave a typed identifier.
    ///
    /// The identifier says what kind of element it is for, so the lookup is the same
    /// as asking for that kind yourself: with an identifier for a button,
    /// `app[LoginID.signInButton]` finds what `app.buttons["LoginID.signInButton"]` does.
    ///
    /// ```swift
    /// app[LoginID.signInButton].tap()
    /// #expect(app[LoginID.title].label == "Welcome")
    /// ```
    ///
    /// Use it on the app to look everywhere, or on another element to look only
    /// inside it:
    ///
    /// ```swift
    /// app[InboxID.row(1234)][MessageRowID.deleteButton].tap()
    /// ```
    ///
    /// If the element exists but is a different kind from the one its identifier
    /// declares, it is not found. Declare the identifier as `AnyElement` to match an
    /// element of any kind.
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript<Kind: ElementKind>(id: ElementID<Kind>) -> XCUIElement {
        descendants(matching: XCUIElement.ElementType(Kind.elementType))[id.accessibilityIdentifier]
    }
}

extension XCUIElementQuery {
    /// Returns the element in this query that the app gave a typed identifier.
    ///
    /// Use this to choose the query yourself. The kind that the identifier declares
    /// is not used:
    ///
    /// ```swift
    /// app.tables.cells[InboxID.row(1234)].tap()
    /// ```
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript<Kind: ElementKind>(id: ElementID<Kind>) -> XCUIElement {
        self[id.accessibilityIdentifier]
    }
}
