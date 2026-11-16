import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements `@UITestSuite`.
///
/// Adds an extension that conforms the class to `UITestSuite` and returns the macro's
/// arguments as the suite's traits.
public struct UITestSuiteMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: UITestSuiteDiagnostic.requiresTestCaseClass))
            return []
        }

        guard classDecl.inheritanceClause != nil else {
            context.diagnose(
                Diagnostic(
                    node: classDecl.name,
                    message: UITestSuiteDiagnostic.requiresTestCaseClass,
                    fixIts: [.inheritFromTestCase(classDecl)]
                )
            )
            return []
        }

        // The compiler passes the conformance only when the class does not already have it.
        let conformance = protocols.isEmpty ? "" : ": \(RuntimeName.suiteProtocol)"
        let access = classDecl.memberAccessModifier.map { "\($0) " } ?? ""
        let traits = node.traitExpressions.map(\.trimmedDescription).joined(separator: ", ")

        // `nonisolated` lets the property satisfy the protocol when the class is isolated to a global actor.
        let decl: DeclSyntax = """
            extension \(type.trimmed)\(raw: conformance) {
                \(raw: access)nonisolated static var \(raw: RuntimeName.suiteTraits): [any \(raw: RuntimeName.traitProtocol)] {
                    [\(raw: traits)]
                }
            }
            """
        return [decl.cast(ExtensionDeclSyntax.self)]
    }
}

extension AttributeSyntax {
    /// The expressions passed for the variadic `traits:` parameter, in order.
    ///
    /// The first carries the label and the rest follow it without one.
    fileprivate var traitExpressions: [ExprSyntax] {
        guard let arguments = arguments?.as(LabeledExprListSyntax.self) else { return [] }
        return arguments
            .drop { $0.label?.text != MacroParameter.traits }
            .enumerated()
            .prefix { index, argument in index == 0 || argument.label == nil }
            .map(\.element.expression)
    }
}

extension ClassDeclSyntax {
    /// The access modifier a member needs in order to satisfy a public protocol requirement,
    /// or `nil` if the default access level is enough.
    fileprivate var memberAccessModifier: String? {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open): return "public"
            case .keyword(.package): return "package"
            default: continue
            }
        }
        return nil
    }
}

extension FixIt {
    /// Adds `XCTestCase` as the superclass of a class that has no inheritance clause.
    fileprivate static func inheritFromTestCase(_ classDecl: ClassDeclSyntax) -> FixIt {
        let inheritance = InheritanceClauseSyntax(
            colon: .colonToken(trailingTrivia: .space),
            inheritedTypes: InheritedTypeListSyntax([
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(RuntimeName.testCase)))
            ])
        )

        // The clause goes after the name, or after the generic parameters if there are any,
        // and takes over the whitespace that followed them.
        var fixed = classDecl
        if let genericParameters = classDecl.genericParameterClause {
            fixed.genericParameterClause = genericParameters.with(\.trailingTrivia, [])
            fixed.inheritanceClause = inheritance.with(\.trailingTrivia, genericParameters.trailingTrivia)
        } else {
            fixed.name = classDecl.name.with(\.trailingTrivia, [])
            fixed.inheritanceClause = inheritance.with(\.trailingTrivia, classDecl.name.trailingTrivia)
        }

        return FixIt(
            message: UITestSuiteFixIt.inheritFromTestCase,
            changes: [.replace(oldNode: Syntax(classDecl), newNode: Syntax(fixed))]
        )
    }
}

enum UITestSuiteDiagnostic: String, DiagnosticMessage {
    case requiresTestCaseClass

    var message: String {
        switch self {
        case .requiresTestCaseClass:
            "'@\(MacroName.uiTestSuite)' can only be applied to a class that inherits from '\(RuntimeName.testCase)'"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "UITestingMacros", id: "\(MacroName.uiTestSuite).\(rawValue)")
    }

    var severity: DiagnosticSeverity { .error }
}

enum UITestSuiteFixIt: String, FixItMessage {
    case inheritFromTestCase

    var message: String {
        switch self {
        case .inheritFromTestCase: "Inherit from '\(RuntimeName.testCase)'"
        }
    }

    var fixItID: MessageID {
        MessageID(domain: "UITestingMacros", id: "\(MacroName.uiTestSuite).\(rawValue)")
    }
}
