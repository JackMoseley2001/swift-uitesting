/// The names of the macros this plugin implements, as they are written where they are used.
///
/// Refer to these rather than repeating the names as string literals, so that one macro
/// can recognise or mention another consistently.
enum MacroName {
    static let uiTestSuite = "UITestSuite"
}

/// The names of the declarations that macro expansions refer to.
enum RuntimeName {
    /// The module that declares the macros and the runtime they expand into.
    static let module = "UITesting"

    static let suiteProtocol = "\(module).UITestSuite"
    static let traitProtocol = "\(module).UITestTrait"
    static let suiteTraits = "suiteTraits"

    /// The XCTest class every suite inherits from.
    static let testCase = "XCTestCase"
}
