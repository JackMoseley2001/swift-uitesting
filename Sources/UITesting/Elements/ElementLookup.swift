import XCTest

extension XCUIElement {
    /// Returns the element inside this one that the app gave a typed identifier.
    ///
    /// The identifier says what kind of element it is for, so the lookup is the same
    /// as asking for that kind yourself: with an identifier for a button,
    /// `app[LoginID.signInButton]` finds what `app.buttons["LoginID.signInButton"]` does.
    ///
    /// The result is a ``UITestElement``, whose actions wait for the element to be ready:
    ///
    /// ```swift
    /// try app[LoginID.signInButton].tap()
    /// #expect(app[LoginID.title].label == "Welcome")
    /// ```
    ///
    /// Use it on the app to look everywhere, or on another element to look only
    /// inside it.
    ///
    /// If the element exists but is a different kind from the one its identifier
    /// declares, it is not found. Declare the identifier as `AnyElement` to match an
    /// element of any kind.
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript<Kind: ElementKind>(id: ElementID<Kind>) -> UITestElement<Kind> {
        let identifier = id.accessibilityIdentifier
        return UITestElement(
            element: descendant(of: Kind.elementType, identifier: identifier),
            accessibilityIdentifier: identifier,
            elementOfAnyKind: Kind.elementType == .any ? nil : descendants(matching: .any)[identifier],
            scope: self,
            app: self as? XCUIApplication
        )
    }
}

extension XCUIElement {
    /// Returns the element of a type inside this one that has an identifier.
    func descendant(of type: UITestingCore.ElementType, identifier: String) -> XCUIElement {
        #if os(watchOS)
        if WrappedFields.wraps(type, systemMarksFields: WrappedFields.systemMarksFields) {
            return descendants(matching: .any).matching(identifier: identifier)
                .descendants(matching: Self.ElementType(type)).firstMatch
        }
        #endif
        return descendants(matching: Self.ElementType(type))[identifier]
    }

    /// Returns the elements of a type inside this one that a predicate matches.
    func descendants(of type: UITestingCore.ElementType, matching predicate: NSPredicate) -> XCUIElementQuery {
        #if os(watchOS)
        if WrappedFields.wraps(type, systemMarksFields: WrappedFields.systemMarksFields) {
            return descendants(matching: .any).matching(predicate).descendants(matching: Self.ElementType(type))
        }
        #endif
        return descendants(matching: Self.ElementType(type)).matching(predicate)
    }
}

/// How a text field of a watch app has its identifier and its label before watchOS 26.
///
/// There the system puts them on an element around the field, of no type, and the
/// field inside has neither. From watchOS 26 the field has them itself, as on every
/// other platform.
enum WrappedFields {
    /// Whether a field has its own identifier and label on the system that is running.
    static var systemMarksFields: Bool {
        if #available(watchOS 26, *) { return true }
        return false
    }

    /// Whether an element of a type is looked up inside the element that has its
    /// identifier or its label.
    ///
    /// - Parameters:
    ///   - type: The type of the element that is looked up.
    ///   - systemMarksFields: Whether a field has its own identifier and label.
    static func wraps(_ type: UITestingCore.ElementType, systemMarksFields: Bool) -> Bool {
        !systemMarksFields && (type == .textField || type == .secureTextField)
    }
}

extension XCUIElementQuery {
    /// Returns the element in this query that the app gave a typed identifier.
    ///
    /// Use this to choose the query yourself. The kind that the identifier declares
    /// is not used to find the element:
    ///
    /// ```swift
    /// try app.tables.cells[InboxID.row(1234)].tap()
    /// ```
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript<Kind: ElementKind>(id: ElementID<Kind>) -> UITestElement<Kind> {
        UITestElement(
            element: self[id.accessibilityIdentifier],
            accessibilityIdentifier: id.accessibilityIdentifier,
            elementOfAnyKind: nil,
            scope: nil,
            app: nil
        )
    }
}
