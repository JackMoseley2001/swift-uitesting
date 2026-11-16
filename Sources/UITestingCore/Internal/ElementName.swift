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

    private static func list(_ values: [String]) -> String {
        values.isEmpty ? "" : "(\(values.joined(separator: ", ")))"
    }
}
