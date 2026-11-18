import XCTest

/// Every element of a family of identifiers, in the order XCTest reports them.
///
/// You get one by looking a family up in the app or in another element, with `all:`:
///
/// ```swift
/// #expect(app[all: InboxID.row].count == 3)
/// #expect(app[all: InboxID.row].map(\.label) == ["Ada", "Grace", "Linus"])
/// try app[all: InboxID.row][0].tap()
/// ```
///
/// The family is declared in an `ElementIDs` group with `family()`, and the elements
/// are the ones of its kind whose identifier the family gave.
///
/// ## Nothing here waits
///
/// ``count``, ``isEmpty``, ``elements`` and ``map(_:)`` say what the app shows at the
/// moment they are read, and are read again each time. To wait, pass a timeout to
/// `#expect` or `#require`:
///
/// ```swift
/// #expect(app[all: InboxID.row].count == 3, within: .seconds(5))
/// ```
///
/// ## Lists that load their rows as they are scrolled to
///
/// A SwiftUI `List` or `LazyVStack`, like a table or a collection view, only creates
/// the rows near the ones on screen. The elements here are the ones that exist, so
/// for a long list the count is of the rows that are loaded, not of the data behind
/// the list.
///
/// ## The elements
///
/// Each element is the one that was at its position when it was asked for. From
/// then on it is found by its own identifier, exactly as `app[InboxID.row(1234)]`
/// finds it, so it stays the same row if the list changes, and its actions wait and
/// fail in the same way:
///
/// ```swift
/// for row in app[all: InboxID.row].elements {
///     try row.swipeAction("Delete")
///     try row.waitToDisappear()
/// }
/// ```
///
/// The identifier of each element has to be read from the app to do this, so
/// ``elements`` and ``map(_:)`` take one more request to the app for each element.
/// ``count`` takes one in all.
///
/// ## Anything else
///
/// Use ``query`` for the parts of `XCUIElementQuery` that this type does not have.
@MainActor
public struct UITestElements<Kind: ElementKind> {
    /// The underlying XCTest query, which matches the elements of the family's kind
    /// whose identifier belongs to the family.
    public let query: XCUIElementQuery

    /// How the elements of the family are told from other elements.
    let match: ElementFamilyMatch

    /// The element the family was looked up in.
    let scope: XCUIElement

    /// The app the family was looked up in, if it was looked up in an app or in an
    /// element that was.
    let app: XCUIApplication?

    /// Looks one identifier up in what the family was looked up in.
    let find: (ElementID<Kind>) -> UITestElement<Kind>

    /// - Parameters:
    ///   - scope: The element to look in.
    ///   - app: The app that `scope` is or was looked up in, if that is known.
    ///   - find: Looks one identifier up in `scope`, the way its own subscript does.
    init<Value>(
        _ family: ElementIDFamily<Kind, Value>,
        in scope: XCUIElement,
        app: XCUIApplication?,
        find: @escaping (ElementID<Kind>) -> UITestElement<Kind>
    ) {
        let match = ElementFamilyMatch(family)
        self.query = scope.descendants(matching: XCUIElement.ElementType(Kind.elementType)).matching(match.predicate)
        self.match = match
        self.scope = scope
        self.app = app
        self.find = find
    }

    /// How many elements of the family there are, read without waiting.
    ///
    /// ```swift
    /// #expect(app[all: InboxID.row].count == 3)
    /// ```
    public var count: Int {
        query.count
    }

    /// Whether there is no element of the family, read without waiting.
    ///
    /// ```swift
    /// #expect(app[all: InboxID.row].isEmpty, within: .seconds(5))
    /// ```
    public var isEmpty: Bool {
        count == 0
    }

    /// The elements of the family that exist now, in the order XCTest reports them,
    /// which for a list is normally the order they are in on screen.
    ///
    /// ```swift
    /// for row in app[all: InboxID.row].elements {
    ///     #expect(row.isEnabled)
    /// }
    /// ```
    ///
    /// Each one is found by its own identifier from then on, so it stays the same
    /// element if the others change.
    public var elements: [UITestElement<Kind>] {
        query.allElementsBoundByIndex.map { find(ElementID($0.identifier)) }
    }

    /// Returns the element at a position among the elements of the family, counting
    /// from zero.
    ///
    /// ```swift
    /// try app[all: InboxID.row][0].tap()
    /// ```
    ///
    /// If an element is there, the result is that element, found by its own
    /// identifier from then on.
    ///
    /// If none is there yet, the result stands for whichever element comes to be at
    /// the position, so an action on it waits for one. A failure then names it by the
    /// family and the position, as in `InboxID.row(…)[2]`, and that is also its
    /// ``UITestElement/accessibilityIdentifier``, because it has no identifier of
    /// its own to give.
    ///
    /// - Parameter index: The position of the element, where the first is at zero.
    public subscript(index: Int) -> UITestElement<Kind> {
        let found = query.element(boundBy: index)
        guard found.exists else {
            return UITestElement(
                element: found,
                accessibilityIdentifier: match.description(ofElementAt: index),
                // An element of another kind at the same position need not be the one
                // that was meant, so a failure does not point one out.
                elementOfAnyKind: nil,
                scope: scope,
                app: app
            )
        }
        return find(ElementID(found.identifier))
    }

    /// Returns the results of calling a closure with each element that exists now, in
    /// the order XCTest reports them.
    ///
    /// ```swift
    /// #expect(app[all: InboxID.row].map(\.label) == ["Ada", "Grace", "Linus"])
    /// ```
    ///
    /// - Parameter transform: A closure that takes an element and returns a value.
    public func map<T>(_ transform: (UITestElement<Kind>) throws -> T) rethrows -> [T] {
        try elements.map(transform)
    }
}

extension XCUIElement {
    /// Returns every element inside this one that belongs to a family of identifiers.
    ///
    /// ```swift
    /// #expect(app[all: InboxID.row].count == 3)
    /// ```
    ///
    /// The family says what kind of element it is for, and only elements of that kind
    /// are found. Use it on the app to look everywhere, or on another element to look
    /// only inside it.
    ///
    /// - Parameter family: The family of identifiers that the app gave the elements.
    public subscript<Kind: ElementKind, Value>(all family: ElementIDFamily<Kind, Value>) -> UITestElements<Kind> {
        UITestElements(family, in: self, app: self as? XCUIApplication, find: { self[$0] })
    }
}

extension UITestElement {
    /// Returns every element inside this one that belongs to a family of identifiers.
    ///
    /// ```swift
    /// #expect(app[InboxID.list][all: InboxID.row].count == 3)
    /// ```
    ///
    /// - Parameter family: The family of identifiers that the app gave the elements.
    public subscript<Child: ElementKind, Value>(all family: ElementIDFamily<Child, Value>) -> UITestElements<Child> {
        UITestElements(family, in: element, app: app, find: { self[$0] })
    }
}
