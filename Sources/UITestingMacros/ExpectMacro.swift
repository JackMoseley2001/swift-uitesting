import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements `#expect`.
///
/// Wraps the condition in a closure, so that it can be evaluated again while waiting,
/// and passes it to a function that reports a failure at the place the macro was used.
/// A comparison with `==` passes each side separately, so that a failure can show how
/// the two values differ.
public struct ExpectMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // The compiler rejects a call without a condition before it reaches the macro, so an empty
        // argument list means this version of swift-syntax could not parse the call. That happens
        // when the macro is written with a module name, which older versions do not understand.
        guard let condition = node.arguments.first?.expression else {
            throw DiagnosticsError(diagnostics: [Diagnostic(node: node, message: ExpectDiagnostic.missingCondition)])
        }

        // The condition runs in a closure that is not `async`.
        if let awaitKeyword = condition.tokens(viewMode: .sourceAccurate).first(where: { $0.tokenKind == .keyword(.await) }) {
            throw DiagnosticsError(
                diagnostics: [Diagnostic(node: awaitKeyword, message: ExpectDiagnostic.awaitInCondition)]
            )
        }

        if condition.is(BooleanLiteralExprSyntax.self) {
            context.diagnose(Diagnostic(node: condition, message: ExpectDiagnostic.constantCondition))
        }

        var arguments: [String]
        let function: String
        if let (lhs, rhs) = equalityOperands(of: condition) {
            function = RuntimeName.qualifiedExpectEqual
            arguments = ["{ \(lhs.trimmedDescription) }", "{ \(rhs.trimmedDescription) }", "{ $0 == $1 }"]
        } else {
            function = RuntimeName.qualifiedExpect
            arguments = ["{ \(condition.trimmedDescription) }"]
        }

        arguments.append("expression: \(StringLiteralExprSyntax(content: sourceCode(of: condition)))")

        for argument in node.arguments.dropFirst() {
            if argument.label?.text == MacroParameter.within {
                arguments.append("timeout: \(argument.expression.trimmedDescription)")
            } else if argument.label == nil {
                arguments.append("comment: \(argument.expression.trimmedDescription)")
            }
        }

        if let location = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .filePath) {
            arguments.append("filePath: \(location.file)")
            arguments.append("line: \(location.line)")
        } else {
            arguments.append("filePath: #filePath")
            arguments.append("line: #line")
        }

        return """
            \(raw: function)(
                \(raw: arguments.joined(separator: ",\n    "))
            )
            """
    }

    /// The two sides of the condition, if it is a comparison with `==` at the top level.
    ///
    /// A comparison with `nil` is left whole, because `nil` on its own has no type.
    private static func equalityOperands(of condition: ExprSyntax) -> (lhs: ExprSyntax, rhs: ExprSyntax)? {
        // The condition usually arrives with its operators already folded into a tree.
        // If it is still a flat sequence, fold it to find the operator that is applied last.
        var folded = condition
        if let sequence = condition.as(SequenceExprSyntax.self) {
            guard let result = try? OperatorTable.standardOperators.foldSingle(sequence) else { return nil }
            folded = result
        }

        guard
            let comparison = folded.as(InfixOperatorExprSyntax.self),
            comparison.operator.as(BinaryOperatorExprSyntax.self)?.operator.text == "==",
            !comparison.leftOperand.is(NilLiteralExprSyntax.self),
            !comparison.rightOperand.is(NilLiteralExprSyntax.self)
        else {
            return nil
        }
        return (comparison.leftOperand, comparison.rightOperand)
    }

    /// The condition as written, on one line.
    private static func sourceCode(of condition: ExprSyntax) -> String {
        condition.trimmedDescription
            .split(whereSeparator: \.isNewline)
            .map { $0.drop(while: \.isWhitespace) }
            .joined(separator: " ")
    }
}

enum ExpectDiagnostic: String, DiagnosticMessage {
    case missingCondition
    case awaitInCondition
    case constantCondition

    var message: String {
        switch self {
        case .missingCondition:
            """
            '#\(MacroName.expect)' could not read its condition; \
            writing a module name before the macro requires swift-syntax 603 or later
            """
        case .awaitInCondition:
            "'#\(MacroName.expect)' cannot await inside its condition; await the value first and pass the result"
        case .constantCondition:
            "'#\(MacroName.expect)' is given a constant, so it will always have the same result"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "UITestingMacros", id: "\(MacroName.expect).\(rawValue)")
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .missingCondition, .awaitInCondition: .error
        case .constantCondition: .warning
        }
    }
}
