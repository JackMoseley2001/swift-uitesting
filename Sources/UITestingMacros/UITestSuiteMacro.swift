import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements `@UITestSuite`.
///
/// Adds an extension that conforms the class to `UITestSuite` and returns the macro's
/// arguments as the suite's traits, and isolates each `@UITest` function to the main actor.
public struct UITestSuiteMacro: ExtensionMacro, MemberAttributeMacro {
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
        let conformance = protocols.isEmpty ? "" : ": \(RuntimeName.qualifiedSuiteProtocol)"
        let access = classDecl.memberAccessModifier.map { "\($0) " } ?? ""
        let traits = node.traitExpressions.map(\.trimmedDescription).joined(separator: ", ")

        // `nonisolated` lets the property satisfy the protocol when the class is isolated to a global actor.
        let decl: DeclSyntax = """
            extension \(type.trimmed)\(raw: conformance) {
                \(raw: access)nonisolated static var \(raw: RuntimeName.suiteTraits): [any \(raw: RuntimeName.qualifiedTraitProtocol)] {
                    [\(raw: traits)]
                }
            }
            """
        return [decl.cast(ExtensionDeclSyntax.self)]
    }

    /// Adds `@MainActor` to the functions and computed properties of the suite, because
    /// the UI testing APIs that tests and their helpers call are isolated to the main actor.
    ///
    /// Members that state their own isolation are left alone, and so are overrides,
    /// which have to keep the isolation of what they override.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        let attributes: AttributeListSyntax
        let modifiers: DeclModifierListSyntax
        if let function = member.as(FunctionDeclSyntax.self) {
            attributes = function.attributes
            modifiers = function.modifiers
        } else if let variable = member.as(VariableDeclSyntax.self), variable.isComputed {
            attributes = variable.attributes
            modifiers = variable.modifiers
        } else {
            return []
        }

        guard
            !attributes.containsGlobalActor,
            !modifiers.contains(.nonisolated),
            !modifiers.contains(.override)
        else {
            return []
        }
        return ["@\(raw: RuntimeName.mainActor)"]
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
