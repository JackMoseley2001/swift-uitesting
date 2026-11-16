import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `#expect`, which records a failure if its condition does not hold.
public struct ExpectMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        try ExpectationExpansion.expand(node, as: .expect, in: context)
    }
}
