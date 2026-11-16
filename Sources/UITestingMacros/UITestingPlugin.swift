import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct UITestingPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        UITestSuiteMacro.self,
        UITestMacro.self,
    ]
}
