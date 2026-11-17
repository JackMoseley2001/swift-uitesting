import SwiftSyntax

extension AttributeSyntax {
    /// The expressions passed for the variadic `traits:` parameter, in order.
    ///
    /// The first carries the label and the rest follow it without one.
    var traitExpressions: [ExprSyntax] {
        guard let arguments = arguments?.as(LabeledExprListSyntax.self) else { return [] }
        return arguments
            .drop { $0.label?.text != MacroParameter.traits }
            .enumerated()
            .prefix { index, argument in index == 0 || argument.label == nil }
            .map(\.element.expression)
    }
}

extension AttributeSyntax {
    /// The expression passed for the `arguments:` parameter, if there is one.
    var argumentsExpression: ExprSyntax? {
        arguments?.as(LabeledExprListSyntax.self)?
            .first { $0.label?.text == MacroParameter.arguments }?
            .expression
    }
}

extension AttributeListSyntax {
    /// Whether the list has an attribute with the given name, written with or without a module prefix.
    func contains(attributeNamed name: String) -> Bool {
        contains { element in
            element.as(AttributeSyntax.self)?.attributeName.lastComponentName == name
        }
    }
}

extension TypeSyntax {
    /// The name of the type without any module or enclosing type, or `nil` for a type that has no single name.
    var lastComponentName: String? {
        if let identifier = self.as(IdentifierTypeSyntax.self) {
            return identifier.name.text
        }
        if let member = self.as(MemberTypeSyntax.self) {
            return member.name.text
        }
        return nil
    }
}

extension DeclModifierListSyntax {
    /// Whether the list has a modifier with the given keyword.
    func contains(_ keyword: Keyword) -> Bool {
        contains { $0.name.tokenKind == .keyword(keyword) }
    }
}

extension AttributeListSyntax {
    /// Whether one of the attributes looks like a global actor, such as `@MainActor`.
    ///
    /// A macro cannot look a type up, so this goes by the convention that the names of
    /// global actors end in "Actor".
    var containsGlobalActor: Bool {
        contains { element in
            element.as(AttributeSyntax.self)?.attributeName.lastComponentName?.hasSuffix("Actor") == true
        }
    }
}

extension VariableDeclSyntax {
    /// Whether this declares a computed property, which has accessors and no storage.
    var isComputed: Bool {
        guard bindings.count == 1, let accessors = bindings.first?.accessorBlock else { return false }
        switch accessors.accessors {
        case .getter:
            return true
        case .accessors(let list):
            // `willSet` and `didSet` are observers on a stored property.
            return list.contains { accessor in
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.get), .keyword(.set), .keyword(._read), .keyword(._modify): true
                default: false
                }
            }
        }
    }
}
