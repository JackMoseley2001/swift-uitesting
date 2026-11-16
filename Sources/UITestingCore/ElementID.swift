/// A typed accessibility identifier that the app gives to an element and a UI test finds it by.
///
/// Declare identifier types in code that is compiled into both the app and its UI test
/// target, such as a shared framework or a file that is a member of both targets. An
/// enumeration works well, with one case for each element:
///
/// ```swift
/// enum LoginID: ElementID {
///     case emailField
///     case signInButton
/// }
/// ```
///
/// The app tags a view with a case, and a UI test looks the element up with the same
/// case, so the identifier is never written as a string in either place:
///
/// ```swift
/// // In the app
/// Button("Sign in") { signIn() }
///     .accessibilityIdentifier(LoginID.signInButton)
///
/// // In a UI test
/// app.buttons[LoginID.signInButton].tap()
/// ```
///
/// ## Identifiers do not clash between types
///
/// The string an element gets is the type's ``namespace`` followed by the value's
/// ``name``. The namespace defaults to the name of the type, so `LoginID.title` is
/// `"LoginID.title"` and `SettingsID.title` is `"SettingsID.title"`. Within one
/// enumeration, the compiler already stops two cases from sharing a name.
///
/// ## Elements in a list
///
/// Give a case an associated value to identify one element out of many, such as a
/// row for a particular item:
///
/// ```swift
/// enum InboxID: ElementID {
///     case list
///     case row(Int)
///     case deleteButton(row: Int)
/// }
///
/// // In the app
/// ForEach(messages) { message in
///     MessageRow(message)
///         .accessibilityIdentifier(InboxID.row(message.id))
/// }
///
/// // In a UI test
/// app.buttons[InboxID.row(1234)].tap()
/// ```
///
/// `InboxID.row(1234)` is `"InboxID.row(1234)"`. Use simple associated values, such as
/// integers, strings and UUIDs. A value of one of your own types is described with the
/// name of its module, which is different in the app and in the UI test target.
///
/// ## Matching identifiers the app already has
///
/// Give the cases raw string values to choose each name yourself, and return `nil`
/// from ``namespace`` to use the names without a prefix:
///
/// ```swift
/// enum LegacyID: String, ElementID {
///     case signInButton = "sign-in-button"
///
///     static var namespace: String? { nil }
/// }
/// ```
public protocol ElementID {
    /// The prefix that keeps this type's identifiers apart from every other type's.
    ///
    /// The default is the name of the type, including any types it is nested in and
    /// without its module, so it is the same in the app and in the UI test target.
    /// `LoginScreen.ID` has the namespace `"LoginScreen.ID"`.
    ///
    /// Provide your own to keep identifiers stable when a type is renamed. Return
    /// `nil` to use each ``name`` as it is, with no prefix. Without a prefix, it is up
    /// to you to make sure that names do not clash with those of other types.
    static var namespace: String? { get }

    /// The part of the identifier that tells this value apart from others of its type.
    ///
    /// The default for a type with a raw string value is the raw value. For any other
    /// type it is a description of the value: the name of an enumeration case, followed
    /// by its associated values if it has any, such as `"row(1234)"`.
    ///
    /// The description comes from the Swift runtime. Provide your own name if the type
    /// is `CustomStringConvertible`, or if the app is built without reflection metadata.
    var name: String { get }
}

extension ElementID {
    public static var namespace: String? {
        TypeName.withoutModule(Self.self)
    }

    public var name: String {
        String(describing: self)
    }

    /// The string to use as the element's accessibility identifier.
    ///
    /// This is the ``namespace``, a full stop and the ``name``, or the name alone if
    /// there is no namespace. In SwiftUI, pass the value itself to
    /// `accessibilityIdentifier(_:)`. Elsewhere, use this string:
    ///
    /// ```swift
    /// signInButton.accessibilityIdentifier = LoginID.signInButton.accessibilityIdentifier
    /// ```
    public var accessibilityIdentifier: String {
        guard let namespace = Self.namespace else { return name }
        return "\(namespace).\(name)"
    }
}

extension ElementID where Self: RawRepresentable, RawValue == String {
    public var name: String {
        rawValue
    }
}
