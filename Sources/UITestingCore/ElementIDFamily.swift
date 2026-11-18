/// A family of typed accessibility identifiers, one for each value, for elements that
/// the app shows many of, such as the rows of a list.
///
/// Declare a family as a static computed property of an ``ElementIDs`` group, and
/// create it with ``ElementIDs/family(name:)``. Inside a group, its type is written
/// with the short name of the kind, as in `Cell.Family<Int>`:
///
/// ```swift
/// enum InboxID: ElementIDs {
///     static var row: Cell.Family<Int> { family() }
/// }
/// ```
///
/// Call the family with a value to get the identifier of one element. It reads the
/// same as a function that returns an identifier, and gives the same string:
///
/// ```swift
/// // In the app
/// ForEach(messages) { message in
///     MessageRow(message)
///         .accessibilityIdentifier(InboxID.row(message.id))   // "InboxID.row(1234)"
/// }
///
/// // In a UI test
/// try app[InboxID.row(1234)].tap()
/// ```
///
/// What a family adds is that a UI test can ask for every element in it, to count
/// them or to check their order:
///
/// ```swift
/// #expect(app[all: InboxID.row].count == 3)
/// ```
///
/// The elements of a family are the ones whose identifier starts with the family's
/// name and an opening bracket, so `InboxID.row` does not take in an element
/// identified by `InboxID.rowTitle`.
public struct ElementIDFamily<Kind: ElementKind, Value>: Sendable {
    /// The namespace of the group that the family was declared in.
    let namespace: String?

    /// The name of the member that declares the family.
    let name: String

    init(namespace: String?, name: String) {
        self.namespace = namespace
        self.name = name
    }

    /// Returns the identifier of the element for a value.
    ///
    /// ```swift
    /// InboxID.row(1234)   // "InboxID.row(1234)"
    /// ```
    ///
    /// The value is described the way `print` shows it. Use values whose description
    /// does not change between runs, such as integers, strings and UUIDs.
    ///
    /// - Parameter value: The value that tells this element apart from the others in
    ///   the family, such as the `id` of the item that a row shows.
    public func callAsFunction(_ value: Value) -> ElementID<Kind> {
        ElementID(identifier(for: value))
    }

    /// What the identifier of every element in the family starts with, such as
    /// `"InboxID.row("`.
    ///
    /// It ends with the bracket that opens the value, so that it does not match an
    /// identifier whose name only starts with the name of the family.
    package var accessibilityIdentifierPrefix: String {
        // A value with an empty description leaves only the closing bracket after the prefix.
        String(identifier(for: "").dropLast())
    }

    private func identifier(for value: Any) -> String {
        let name = ElementName.make(member: name, values: [value])
        guard let namespace else { return name }
        return "\(namespace).\(name)"
    }
}

extension ElementID {
    /// The type of a family of identifiers for this kind of element, where each
    /// element is told apart by a value.
    ///
    /// Inside an ``ElementIDs`` group, write it after the short name of the kind:
    ///
    /// ```swift
    /// static var row: Cell.Family<Int> { family() }
    /// ```
    public typealias Family<Value> = ElementIDFamily<Kind, Value>
}

extension ElementIDs {
    /// Creates the family of identifiers for the member it is called from.
    ///
    /// Call it from a static computed property whose type is the kind of family you
    /// want. The name of the family is the name of that property:
    ///
    /// ```swift
    /// static var row: Cell.Family<Int> { family() }
    /// ```
    ///
    /// `InboxID.row(1234)` is then `"InboxID.row(1234)"`, which is what
    /// `static func row(_ id: Int) -> Cell { element(id) }` gives, so a function can
    /// become a family without any identifier changing.
    ///
    /// - Parameter name: The name of the family. The default is the name of the
    ///   property that this is called from. Pass your own to keep the identifiers
    ///   stable when the property is renamed. To keep the identifiers of a function
    ///   that has an argument label, pass the function's name:
    ///   `family(name: "deleteButton(row:)")` gives `"InboxID.deleteButton(row: 1234)"`.
    public static func family<Kind: ElementKind, Value>(
        name: String = #function
    ) -> ElementIDFamily<Kind, Value> {
        ElementIDFamily(namespace: namespace, name: name)
    }
}
