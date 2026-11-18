/// How an element was found, which is how the description of a failure refers to it.
enum ElementReference: Equatable {
    /// By the accessibility identifier that the app gave it.
    case identifier(String)

    /// By the label it shows, as one kind of element, such as "button".
    case label(String, kind: String)

    /// What a failure calls the element, such as `LoginID.signInButton` or
    /// `the button labelled "Continue"`.
    var name: String {
        switch self {
        case .identifier(let identifier): identifier
        case .label(let label, let kind): "the \(kind) labelled \"\(label)\""
        }
    }

    /// What the element was matched by, completing "no button with this … appeared".
    var attribute: String {
        switch self {
        case .identifier: "identifier"
        case .label: "label"
        }
    }

    /// Says that an element of another kind is there, for a lookup that found nothing.
    ///
    /// - Parameter type: The type of the element that is there, such as "staticText",
    ///   or `nil` if it is not known.
    func hint(forElementOfType type: String?) -> String {
        let other = type.map { "An element of type \($0)" } ?? "An element of another kind"
        switch self {
        case .identifier:
            return "\(other) has this identifier. Is the identifier declared as the wrong kind?"
        case .label:
            return "\(other) has this label. Should the lookup be for that kind?"
        }
    }

    /// Says that the lookup matched several elements, where it has to match one.
    ///
    /// - Parameter count: How many elements matched.
    func reasonForMatching(_ count: Int) -> String {
        "\(count) elements match, and a lookup by \(attribute) does not choose between them. "
            + "Look inside the element that holds the one you mean"
    }
}
