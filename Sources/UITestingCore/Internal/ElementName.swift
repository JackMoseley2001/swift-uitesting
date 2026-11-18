enum ElementName {
    /// Returns the name of an identifier from the member that declares it and the values passed to it.
    ///
    /// A property gives its own name. A function gives its name followed by the values
    /// in brackets, each with its argument label if the function has as many arguments
    /// as there are values: `deleteButton(row:)` with `7` gives `deleteButton(row: 7)`.
    static func make(member: String, values: [Any]) -> String {
        guard let bracket = member.firstIndex(of: "(") else {
            return member + list(values.map { String(describing: $0) })
        }
        let base = String(member[..<bracket])
        let labels = member[member.index(after: bracket)...]
            .dropLast()
            .split(separator: ":", omittingEmptySubsequences: false)
            .dropLast()

        guard labels.count == values.count else {
            return base + list(values.map { String(describing: $0) })
        }
        return base + list(zip(labels, values).map { label, value in
            label == "_" ? String(describing: value) : "\(label): \(value)"
        })
    }

    /// Returns whether a member's name is the one that a stored property of a type gives.
    ///
    /// `#function` in the initialiser of a stored property is not the name of the
    /// property. It is the name of the type that declares it, without the types it is
    /// nested in or its generic arguments: `static let title: StaticText = element()`
    /// in `LoginScreen.ID` gives `ID`. A computed property gives its own name, and a
    /// function gives its name followed by brackets, so neither is mistaken for one
    /// unless a computed property has the same name as its type.
    static func isFromStoredProperty(_ member: String, in type: Any.Type) -> Bool {
        member == TypeName.unqualified(type)
    }

    /// Returns the explanation to stop with when an identifier is declared as a stored property.
    static func storedPropertyMessage(member: String, in type: Any.Type) -> String {
        """
        An identifier in \(TypeName.withoutModule(type)) was given the name "\(member)", which is the \
        name of the group and not of one of its members. That is what a stored property gives, such \
        as `static let title: StaticText = element()`: it cannot work out its own name, so every \
        stored identifier in the group would be the same string. Declare each one as a computed \
        property instead: `static var title: StaticText { element() }`.
        """
    }

    private static func list(_ values: [String]) -> String {
        values.isEmpty ? "" : "(\(values.joined(separator: ", ")))"
    }
}
