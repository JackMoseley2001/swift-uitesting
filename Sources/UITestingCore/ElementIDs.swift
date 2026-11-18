/// A group of typed accessibility identifiers that the app gives to its elements and a
/// UI test finds them by.
///
/// Declare a group in code that is compiled into both the app and its UI test target,
/// such as a shared framework or a file that is a member of both targets. Each
/// identifier is a static member whose type says what kind of element it identifies:
///
/// ```swift
/// enum LoginID: ElementIDs {
///     static var title: StaticText { element() }
///     static var emailField: TextField { element() }
///     static var signInButton: Button { element() }
/// }
/// ```
///
/// The app tags a view with a member, and a UI test finds the element with the same
/// member, so the identifier is never written as a string in either place and the
/// test does not have to say what kind of element to look for:
///
/// ```swift
/// // In the app
/// Button("Sign in") { signIn() }
///     .accessibilityIdentifier(LoginID.signInButton)
///
/// // In a UI test
/// try app[LoginID.signInButton].tap()
/// ```
///
/// ## Kinds of element
///
/// Inside a group, the names `Button`, `StaticText`, `TextField` and the others listed
/// under ``ElementKinds`` are the types of identifier for each kind of element. They
/// follow the element types that XCTest reports, which is what a UI test matches
/// against. A SwiftUI `Text` is a `StaticText`, and on iOS a `Toggle` is a `Switch`.
/// Use `AnyElement` when the kind does not matter or differs between platforms.
///
/// ## Identifiers do not clash between groups
///
/// The string an element gets is the group's ``namespace``, a full stop, and the name
/// of the member. The namespace defaults to the name of the group's type, so
/// `LoginID.title` is `"LoginID.title"` and `SettingsID.title` is `"SettingsID.title"`.
/// Within one group, the compiler stops two members from sharing a name.
///
/// ## Elements in a list
///
/// Use a static function to identify one element out of many, such as the row for a
/// particular item, and pass its arguments on to ``element(_:name:)``:
///
/// ```swift
/// enum InboxID: ElementIDs {
///     static var list: Table { element() }
///     static func row(_ id: Int) -> Cell { element(id) }
///     static func deleteButton(row: Int) -> Button { element(row) }
/// }
///
/// // In the app
/// ForEach(messages) { message in
///     MessageRow(message)
///         .accessibilityIdentifier(InboxID.row(message.id))
/// }
///
/// // In a UI test
/// try app[InboxID.row(1234)].tap()
/// ```
///
/// `InboxID.row(1234)` is `"InboxID.row(1234)"`, and `InboxID.deleteButton(row: 1234)`
/// is `"InboxID.deleteButton(row: 1234)"`.
///
/// When a UI test needs every row, to count them or to check their order, declare
/// the rows as a family with ``family(name:)``. A family is called in the same way
/// and gives the same identifiers:
///
/// ```swift
/// static var row: Cell.Family<Int> { family() }
///
/// // In a UI test
/// try app[InboxID.row(1234)].tap()
/// #expect(app[all: InboxID.row].count == 3)
/// ```
///
/// ## Matching identifiers the app already has
///
/// Create the identifier from the string the app uses:
///
/// ```swift
/// enum LegacyID: ElementIDs {
///     static var signInButton: Button { Button("sign-in-button") }
/// }
/// ```
///
/// - Important: Declare each identifier as a computed property or a function, as
///   above. A stored property, such as `static let title: StaticText = element()`,
///   cannot work out its own name, so every one in the group would get the same
///   identifier. A debug build stops when it reaches one, and says how to fix it.
///   A release build does not check, and never stops for this.
public protocol ElementIDs {
    /// The prefix that keeps this group's identifiers apart from every other group's.
    ///
    /// The default is the name of the type, including any types it is nested in and
    /// without its module, so it is the same in the app and in the UI test target.
    /// `LoginScreen.ID` has the namespace `"LoginScreen.ID"`.
    ///
    /// Provide your own to keep identifiers stable when the type is renamed. Return
    /// `nil` to use each name as it is, with no prefix. Without a prefix, it is up to
    /// you to make sure that names do not clash with those of other groups.
    static var namespace: String? { get }
}

extension ElementIDs {
    public static var namespace: String? {
        TypeName.withoutModule(Self.self)
    }

    /// Creates the identifier for the member it is called from.
    ///
    /// Call it from a static computed property or function whose type is the kind of
    /// identifier you want. The name of the identifier is the name of that member:
    ///
    /// ```swift
    /// static var signInButton: Button { element() }
    /// ```
    ///
    /// Pass a function's arguments on, so that each element gets its own identifier:
    ///
    /// ```swift
    /// static func row(_ id: Int) -> Cell { element(id) }
    /// ```
    ///
    /// Each value is described the way `print` shows it. Use values whose description
    /// does not change between runs, such as integers, strings and UUIDs.
    ///
    /// - Important: Do not call it from a stored property, such as
    ///   `static let title: StaticText = element()`. A stored property gives the name
    ///   of the group's type in place of its own, so every one in the group would get
    ///   the same identifier. A debug build stops there, with a message that names
    ///   the group and says how to fix it. A release build does not check, and never
    ///   stops for this.
    ///
    /// - Parameters:
    ///   - values: The values that tell this element apart from the others the
    ///     function identifies. Pass the function's arguments, in order.
    ///   - name: The name of the identifier. The default is the name of the member
    ///     that this is called from. Pass your own to keep an identifier stable when
    ///     the member is renamed. A name that is the same as the name of the group's
    ///     type is what a stored property gives, so a debug build stops for it too.
    public static func element<Kind: ElementKind>(
        _ values: Any...,
        name: String = #function
    ) -> ElementID<Kind> {
        assert(
            !ElementName.isFromStoredProperty(name, in: Self.self),
            ElementName.storedPropertyMessage(member: name, in: Self.self)
        )
        let name = ElementName.make(member: name, values: values)
        guard let namespace else { return ElementID(name) }
        return ElementID("\(namespace).\(name)")
    }
}
