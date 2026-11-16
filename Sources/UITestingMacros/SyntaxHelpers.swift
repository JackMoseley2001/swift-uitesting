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
