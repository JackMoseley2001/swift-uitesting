import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `#require` for a condition, which records a failure and throws if the
/// condition does not hold.
public struct RequireMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        try ExpectationExpansion.expand(node, as: .require, in: context)
    }
}

/// Implements `#require` for an optional value, which returns the value, or records a
/// failure and throws if there is none.
public struct RequireValueMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        try ExpectationExpansion.expand(node, as: .requireValue, in: context)
    }
}
