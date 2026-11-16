import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The functions an expectation macro expands into.
struct ExpectationKind {
    /// The function that is given the first argument of the macro.
    let function: String

    /// The function that is given each side of a comparison with `==`, for macros whose
    /// first argument is a condition.
    let equalityFunction: String?

    /// What the first argument of the macro is called in diagnostics.
    let argumentName: String

    static let expect = ExpectationKind(
        function: RuntimeName.qualifiedExpect,
        equalityFunction: RuntimeName.qualifiedExpectEqual,
        argumentName: "condition"
    )

    static let require = ExpectationKind(
        function: RuntimeName.qualifiedRequire,
        equalityFunction: RuntimeName.qualifiedRequireEqual,
        argumentName: "condition"
    )

    static let requireValue = ExpectationKind(
        function: RuntimeName.qualifiedRequireValue,
        equalityFunction: nil,
        argumentName: "value"
    )
}

/// The expansion shared by `#expect` and `#require`.
///
/// Wraps the first argument in a closure, so that it can be evaluated again while waiting,
/// and passes it to a function with its source code and the place the macro was used.
/// A comparison with `==` passes each side separately, so that a failure can show how
/// the two values differ.
enum ExpectationExpansion {
    static func expand(
        _ node: some FreestandingMacroExpansionSyntax,
        as kind: ExpectationKind,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let name = node.macroName.text

        // The compiler rejects a call without a first argument before it reaches the macro, so an
        // empty argument list means this version of swift-syntax could not parse the call. That
        // happens when the macro is written with a module name, which older versions do not understand.
        guard let subject = node.arguments.first?.expression else {
            throw DiagnosticsError(
                diagnostics: [Diagnostic(node: node, message: ExpectationDiagnostic.missingArgument(kind.argumentName, of: name))]
            )
        }

        // The argument runs in a closure that is not `async`.
        if let awaitKeyword = subject.tokens(viewMode: .sourceAccurate).first(where: { $0.tokenKind == .keyword(.await) }) {
            throw DiagnosticsError(
                diagnostics: [Diagnostic(node: awaitKeyword, message: ExpectationDiagnostic.awaitInArgument(kind.argumentName, of: name))]
            )
        }

        if kind.equalityFunction != nil, subject.is(BooleanLiteralExprSyntax.self) {
            context.diagnose(Diagnostic(node: subject, message: ExpectationDiagnostic.constantCondition(name: name)))
        }

        var arguments: [String]
        let function: String
        if let equalityFunction = kind.equalityFunction, let (lhs, rhs) = equalityOperands(of: subject) {
            function = equalityFunction
            arguments = ["{ \(lhs.trimmedDescription) }", "{ \(rhs.trimmedDescription) }", "{ $0 == $1 }"]
        } else {
            function = kind.function
            arguments = ["{ \(subject.trimmedDescription) }"]
        }

        arguments.append("expression: \(StringLiteralExprSyntax(content: sourceCode(of: subject)))")

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

    /// The expression as written, on one line.
    private static func sourceCode(of expression: ExprSyntax) -> String {
        expression.trimmedDescription
            .split(whereSeparator: \.isNewline)
            .map { $0.drop(while: \.isWhitespace) }
            .joined(separator: " ")
    }
}

struct ExpectationDiagnostic: DiagnosticMessage {
    let id: String
    let message: String
    let severity: DiagnosticSeverity

    /// - Parameters:
    ///   - argument: What the macro's first argument is called.
    ///   - name: The name the macro was written with.
    static func missingArgument(_ argument: String, of name: String) -> ExpectationDiagnostic {
        ExpectationDiagnostic(
            id: "missingArgument",
            message: """
                '#\(name)' could not read its \(argument); \
                writing a module name before the macro requires swift-syntax 603 or later
                """,
            severity: .error
        )
    }

    static func awaitInArgument(_ argument: String, of name: String) -> ExpectationDiagnostic {
        ExpectationDiagnostic(
            id: "awaitInArgument",
            message: "'#\(name)' cannot await inside its \(argument); await the value first and pass the result",
            severity: .error
        )
    }

    static func constantCondition(name: String) -> ExpectationDiagnostic {
        ExpectationDiagnostic(
            id: "constantCondition",
            message: "'#\(name)' is given a constant, so it will always have the same result",
            severity: .warning
        )
    }

    var diagnosticID: MessageID {
        MessageID(domain: "UITestingMacros", id: "expectation.\(id)")
    }
}
