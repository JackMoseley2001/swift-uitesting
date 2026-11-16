/// The names of the macros this plugin implements, as they are written where they are used.
///
/// Refer to these rather than repeating the names as string literals, so that one macro
/// can recognise or mention another consistently.
enum MacroName {
    static let uiTestSuite = "UITestSuite"
    static let uiTest = "UITest"
    static let expect = "expect"

    /// A second name for `expect`, for files that also import Swift Testing.
    static let uiTestingExpect = "UITestingExpect"
}

/// The labels of the macros' parameters.
enum MacroParameter {
    static let traits = "traits"
    static let within = "within"
}

/// The names of the declarations that macro expansions refer to.
enum RuntimeName {
    /// The module that declares the macros and the runtime they expand into.
    static let module = "UITesting"

    static let suiteProtocol = "UITestSuite"
    static let qualifiedSuiteProtocol = "\(module).\(suiteProtocol)"
    static let qualifiedTraitProtocol = "\(module).UITestTrait"
    static let qualifiedRunner = "\(module).UITestRunner"
    static let suiteTraits = "suiteTraits"

    /// The type passed to a test body, and the name of its property that holds the app.
    static let context = "UITestContext"
    static let contextApplication = "app"

    /// The XCTest class every suite inherits from.
    static let testCase = "XCTestCase"
    static let application = "XCUIApplication"

    /// The prefix XCTest uses to recognise a test method.
    static let testMethodPrefix = "test"

    /// The prefix of the test method generated for a `@UITest` function.
    static let generatedTestMethodPrefix = "test_"

    static let mainActor = "MainActor"

    /// The functions that `#expect` expands into.
    static let qualifiedExpect = "\(module).__expect"
    static let qualifiedExpectEqual = "\(module).__expectEqual"
}
