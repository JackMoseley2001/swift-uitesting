enum TypeName {
    /// Returns the name of a type with the types it is nested in, and without its module.
    ///
    /// The app and its UI test target are separate modules, so a name that both can
    /// work out must leave the module off. Contexts that have no name, which the runtime
    /// gives to private and local types, are left off too.
    static func withoutModule(_ type: Any.Type) -> String {
        let components = components(of: String(reflecting: type))
            .dropFirst()
            .filter { !$0.hasPrefix("(") }
        guard !components.isEmpty else { return String(describing: type) }
        return components.joined(separator: ".")
    }

    /// Splits a qualified type name at each full stop that is not inside brackets.
    private static func components(of qualifiedName: String) -> [Substring] {
        var components: [Substring] = []
        var depth = 0
        var start = qualifiedName.startIndex

        for index in qualifiedName.indices {
            switch qualifiedName[index] {
            case "<", "(", "[":
                depth += 1
            case ">", ")", "]":
                depth -= 1
            case "." where depth == 0:
                components.append(qualifiedName[start..<index])
                start = qualifiedName.index(after: index)
            default:
                break
            }
        }
        components.append(qualifiedName[start...])
        return components
    }
}
