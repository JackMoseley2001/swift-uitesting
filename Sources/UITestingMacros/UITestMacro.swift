import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements `@UITest`.
///
/// Adds a test method beside the function it is attached to. XCTest discovers and runs
/// the method, which launches the app with the test's traits and then calls the function.
public struct UITestMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let function = declaration.as(FunctionDeclSyntax.self),
            !function.modifiers.contains(.static),
            !function.modifiers.contains(.class)
        else {
            context.diagnose(Diagnostic(node: node, message: UITestDiagnostic.requiresInstanceMethod))
            return []
        }

        guard isInsideSuite(context) else {
            context.diagnose(Diagnostic(node: node, message: UITestDiagnostic.requiresSuite))
            return []
        }

        var isValid = true
        let name = function.name.text.filter { $0 != "`" }

        if let genericParameters = function.genericParameterClause {
            context.diagnose(Diagnostic(node: genericParameters, message: UITestDiagnostic.isGeneric))
            isValid = false
        }

        if let returnType = function.signature.returnClause?.type, !returnType.isVoid {
            context.diagnose(Diagnostic(node: returnType, message: UITestDiagnostic.returnsValue))
            isValid = false
        }

        // With `arguments:`, the test is run once for each of them, and the one parameter
        // that is not the app or the context receives the argument.
        let argumentsExpression = node.argumentsExpression
        var argumentParameter: FunctionParameterSyntax?
        var usesContext = false

        var arguments: [String] = []
        for parameter in function.signature.parameterClause.parameters {
            let label = parameter.firstName.tokenKind == .wildcard ? "" : "\(parameter.firstName.text): "
            if let value = argumentValue(for: parameter) {
                usesContext = true
                arguments.append(label + value)
            } else if argumentsExpression != nil, argumentParameter == nil {
                argumentParameter = parameter
                arguments.append(label + Self.argumentName)
            } else {
                let message =
                    argumentsExpression == nil
                    ? UITestDiagnostic.unsupportedParameter(parameter)
                    : UITestDiagnostic.secondArgumentParameter(parameter)
                context.diagnose(Diagnostic(node: parameter.type, message: message))
                isValid = false
            }
        }

        if let argumentsExpression, argumentParameter == nil, isValid {
            context.diagnose(Diagnostic(node: argumentsExpression, message: UITestDiagnostic.noArgumentParameter))
            isValid = false
        }

        // XCTest runs every method that takes no arguments and whose name starts with "test",
        // so it would also call such a function directly, without launching the app.
        if arguments.isEmpty, isValid, name.hasPrefix(RuntimeName.testMethodPrefix) {
            context.diagnose(
                Diagnostic(
                    node: function.name,
                    message: UITestDiagnostic.nameStartsWithTest(name),
                    fixIts: FixIt.removingTestPrefix(from: function.name, named: name).map { [$0] } ?? []
                )
            )
            isValid = false
        }

        guard isValid else { return [] }

        let effects = function.signature.effectSpecifiers
        let call = [
            effects?.throwsClause != nil ? "try " : "",
            effects?.asyncSpecifier != nil ? "await " : "",
            "self.\(function.name.text)(\(arguments.joined(separator: ", ")))"
        ].joined()

        let traits = node.traitExpressions.map(\.trimmedDescription).joined(separator: ", ")
        let traitsArgument = traits.isEmpty ? "" : ", \(MacroParameter.traits): [\(traits)]"
        let contextParameter = usesContext ? "context" : "_"

        var argumentsArgument = ""
        var closureParameters = contextParameter
        if let argumentsExpression, let argumentParameter {
            let parameterName = (argumentParameter.secondName ?? argumentParameter.firstName).text
            argumentsArgument =
                ", \(RuntimeName.runnerArguments): \(argumentsExpression.trimmedDescription)"
                + ", \(RuntimeName.runnerArgumentName): \"\(parameterName)\""
            closureParameters = "\(Self.argumentName), \(contextParameter)"
        }

        // The generated method needs the same availability as the function it calls.
        let availability = function.attributes
            .filter { $0.as(AttributeSyntax.self)?.attributeName.lastComponentName == "available" }
            .map { "\($0.trimmedDescription)\n" }
            .joined()

        return [
            """
            \(raw: availability)@\(raw: RuntimeName.mainActor)
            func \(raw: RuntimeName.generatedTestMethodPrefix)\(raw: name)() async throws {
                try await \(raw: RuntimeName.qualifiedRunner).run(self\(raw: traitsArgument)\(raw: argumentsArgument)) { \(raw: closureParameters) in
                    \(raw: call)
                }
            }
            """
        ]
    }

    /// The name the generated method gives to the argument of the run it is making.
    private static let argumentName = "argument"

    /// Whether the function is declared where a UI test can run: in a class that is a UI test
    /// suite, or in an extension, where the compiler checks that the type is a suite instead.
    private static func isInsideSuite(_ context: some MacroExpansionContext) -> Bool {
        guard let enclosing = context.lexicalContext.first else { return false }

        if let classDecl = enclosing.as(ClassDeclSyntax.self) {
            let conformsByHand =
                classDecl.inheritanceClause?.inheritedTypes.contains {
                    $0.type.lastComponentName == RuntimeName.suiteProtocol
                } ?? false
            return conformsByHand || classDecl.attributes.contains(attributeNamed: MacroName.uiTestSuite)
        }

        return enclosing.is(ExtensionDeclSyntax.self)
    }

    /// The expression that provides a value for a parameter of a test function, or `nil` if
    /// the parameter has a type that a UI test cannot be given.
    private static func argumentValue(for parameter: FunctionParameterSyntax) -> String? {
        switch parameter.type.lastComponentName {
        case RuntimeName.application: "context.\(RuntimeName.contextApplication)"
        case RuntimeName.context: "context"
        default: nil
        }
    }
}

extension TypeSyntax {
    /// Whether the type is `Void` or the empty tuple.
    fileprivate var isVoid: Bool {
        if let tuple = self.as(TupleTypeSyntax.self) {
            return tuple.elements.isEmpty
        }
        return lastComponentName == "Void"
    }
}

extension FixIt {
    /// Renames a function so that it no longer starts with "test", or returns `nil` if nothing
    /// would be left of the name.
    fileprivate static func removingTestPrefix(from token: TokenSyntax, named name: String) -> FixIt? {
        let remainder = name.dropFirst(RuntimeName.testMethodPrefix.count).drop { $0 == "_" }
        guard let first = remainder.first, first.isLetter else { return nil }

        // Lower-case a leading capital, or a leading acronym up to the start of the next word.
        let capitals = remainder.prefix { $0.isUppercase }
        let lowercased = capitals.count > 1 && capitals.count < remainder.count ? capitals.dropLast() : capitals
        let newName = lowercased.lowercased() + remainder.dropFirst(lowercased.count)

        let newToken = TokenSyntax.identifier(newName)
            .with(\.leadingTrivia, token.leadingTrivia)
            .with(\.trailingTrivia, token.trailingTrivia)
        return FixIt(
            message: UITestFixIt.rename(to: newName),
            changes: [.replace(oldNode: Syntax(token), newNode: Syntax(newToken))]
        )
    }
}

struct UITestDiagnostic: DiagnosticMessage {
    let id: String
    let message: String

    static let requiresInstanceMethod = Self(
        id: "requiresInstanceMethod",
        message: "'@\(MacroName.uiTest)' can only be applied to an instance method"
    )

    static let requiresSuite = Self(
        id: "requiresSuite",
        message: "'@\(MacroName.uiTest)' can only be used in a class marked '@\(MacroName.uiTestSuite)'"
    )

    static let isGeneric = Self(
        id: "isGeneric",
        message: "'@\(MacroName.uiTest)' cannot be applied to a generic function"
    )

    static let returnsValue = Self(
        id: "returnsValue",
        message: "'@\(MacroName.uiTest)' cannot be applied to a function that returns a value"
    )

    static func unsupportedParameter(_ parameter: FunctionParameterSyntax) -> Self {
        let name = (parameter.secondName ?? parameter.firstName).text
        return Self(
            id: "unsupportedParameter",
            message: """
                '@\(MacroName.uiTest)' cannot provide a value for parameter '\(name)'; \
                a UI test can only take '\(RuntimeName.application)' and '\(RuntimeName.context)' parameters
                """
        )
    }

    static let noArgumentParameter = Self(
        id: "noArgumentParameter",
        message: """
            '@\(MacroName.uiTest)' has arguments, but the function has no parameter to receive them; \
            add a parameter of the type of one argument
            """
    )

    static func secondArgumentParameter(_ parameter: FunctionParameterSyntax) -> Self {
        let name = (parameter.secondName ?? parameter.firstName).text
        return Self(
            id: "secondArgumentParameter",
            message: """
                '@\(MacroName.uiTest)' cannot provide a value for parameter '\(name)'; \
                a UI test with arguments takes one parameter for the argument, \
                as well as '\(RuntimeName.application)' and '\(RuntimeName.context)' parameters
                """
        )
    }

    static func nameStartsWithTest(_ name: String) -> Self {
        Self(
            id: "nameStartsWithTest",
            message: """
                XCTest would also run '\(name)()' directly, without launching the app; \
                rename it so that it does not start with '\(RuntimeName.testMethodPrefix)'
                """
        )
    }

    var diagnosticID: MessageID {
        MessageID(domain: "UITestingMacros", id: "\(MacroName.uiTest).\(id)")
    }

    var severity: DiagnosticSeverity { .error }
}

struct UITestFixIt: FixItMessage {
    let id: String
    let message: String

    static func rename(to name: String) -> Self {
        Self(id: "rename", message: "Rename to '\(name)'")
    }

    var fixItID: MessageID {
        MessageID(domain: "UITestingMacros", id: "\(MacroName.uiTest).\(id)")
    }
}
