import XCTest

/// An element found by a typed identifier, whose actions wait for it to be ready.
///
/// You get one by looking an identifier up in the app or in another element:
///
/// ```swift
/// try app[LoginID.signInButton].tap()
/// ```
///
/// XCTest's own `tap()` fails at once if the element is not there yet. The actions on
/// this type wait first, for as long as the test's ``UITestTrait/actionTimeout(_:)``
/// allows, and end the test with a message that says what went wrong if the element
/// never becomes ready.
///
/// ## Reading from the element
///
/// The properties of `XCUIElement` are available directly, and are read without waiting:
///
/// ```swift
/// #expect(app[LoginID.title].label == "Welcome")
/// #expect(!app[LoginID.errorMessage].exists)
/// ```
///
/// To wait for a value, pass a timeout to `#expect` or `#require`.
///
/// ## Anything else
///
/// Use ``element`` for the parts of `XCUIElement` that this type does not have, such
/// as swipes:
///
/// ```swift
/// app[InboxID.list].element.swipeUp()
/// ```
@MainActor
@dynamicMemberLookup
public struct UITestElement<Kind: ElementKind> {
    /// The underlying XCTest element.
    public let element: XCUIElement

    /// The accessibility identifier the element was looked up by.
    public let accessibilityIdentifier: String

    /// The element with the same identifier whatever its kind, used to explain why a lookup found nothing.
    let elementOfAnyKind: XCUIElement?

    /// Reads a property of the underlying `XCUIElement`, without waiting.
    public subscript<Value>(dynamicMember keyPath: KeyPath<XCUIElement, Value>) -> Value {
        element[keyPath: keyPath]
    }

    /// Returns the element inside this one that the app gave a typed identifier.
    ///
    /// ```swift
    /// try app[InboxID.row(1234)][MessageRowID.deleteButton].tap()
    /// ```
    ///
    /// - Parameter id: The identifier that the app gave the element.
    public subscript<Child: ElementKind>(id: ElementID<Child>) -> UITestElement<Child> {
        element[id]
    }
}
