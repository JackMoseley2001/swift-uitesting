import MacroTesting
import SwiftSyntaxMacroExpansion
import Testing

@testable import UITestingMacros

@Suite(.macros([MacroName.uiTest: UITestMacro.self]))
struct UITestMacroTests {
    @Test
    func functionWithoutParameters() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton() {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func functionTakingTheApp() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(app: XCUIApplication) {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton(app: XCUIApplication) {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { context in
                        self.showsSignInButton(app: context.app)
                    }
                }
            }
            """
        }
    }

    @Test
    func functionTakingTheContextWithoutALabel() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(_ context: UITestContext) {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton(_ context: UITestContext) {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { context in
                        self.showsSignInButton(context)
                    }
                }
            }
            """
        }
    }

    @Test
    func functionTakingTheAppAndTheContext() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(in application: XCUIApplication, context: UITesting.UITestContext) {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton(in application: XCUIApplication, context: UITesting.UITestContext) {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { context in
                        self.showsSignInButton(in: context.app, context: context)
                    }
                }
            }
            """
        }
    }

    @Test
    func asyncThrowingFunction() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(app: XCUIApplication) async throws {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton(app: XCUIApplication) async throws {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { context in
                        try await self.showsSignInButton(app: context.app)
                    }
                }
            }
            """
        }
    }

    @Test
    func throwingFunction() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() throws {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton() throws {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        try self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func asyncFunction() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() async {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton() async {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        await self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func traitsArePassedToTheRunner() {
        assertMacro {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests: XCTestCase {
                @UITest(traits: .loggedIn(as: "Ada"), .launchArgument("--skip-onboarding"))
                func showsHome(app: XCUIApplication) {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests: XCTestCase {
                func showsHome(app: XCUIApplication) {
                }

                @MainActor
                func test_showsHome() async throws {
                    try await UITesting.UITestRunner.run(self, traits: [.loggedIn(as: "Ada"), .launchArgument("--skip-onboarding")]) { context in
                        self.showsHome(app: context.app)
                    }
                }
            }
            """
        }
    }

    @Test
    func availabilityIsCopiedToTheTestMethod() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @available(iOS 18, *)
                @UITest
                func showsSignInButton() {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @available(iOS 18, *)
                func showsSignInButton() {
                }

                @available(iOS 18, *)
                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func functionReturningVoidIsAccepted() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() -> Void {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func showsSignInButton() -> Void {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func classThatConformsByHandIsAccepted() {
        assertMacro {
            """
            final class LoginTests: XCTestCase, UITestSuite {
                @UITest
                func showsSignInButton() {
                }
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase, UITestSuite {
                func showsSignInButton() {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func extensionIsAccepted() {
        assertMacro {
            """
            extension LoginTests {
                @UITest
                func showsSignInButton() {
                }
            }
            """
        } expansion: {
            """
            extension LoginTests {
                func showsSignInButton() {
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { _ in
                        self.showsSignInButton()
                    }
                }
            }
            """
        }
    }

    @Test
    func propertyIsRejected() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                var showsSignInButton: Bool { true }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                ┬──────
                ╰─ 🛑 '@UITest' can only be applied to an instance method
                var showsSignInButton: Bool { true }
            }
            """
        }
    }

    @Test
    func staticMethodIsRejected() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                static func showsSignInButton() {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                ┬──────
                ╰─ 🛑 '@UITest' can only be applied to an instance method
                static func showsSignInButton() {
                }
            }
            """
        }
    }

    @Test
    func classWithoutUITestSuiteIsRejected() {
        assertMacro {
            """
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() {
                }
            }
            """
        } diagnostics: {
            """
            final class LoginTests: XCTestCase {
                @UITest
                ┬──────
                ╰─ 🛑 '@UITest' can only be used in a class marked '@UITestSuite'
                func showsSignInButton() {
                }
            }
            """
        }
    }

    @Test
    func structIsRejected() {
        assertMacro {
            """
            struct LoginTests {
                @UITest
                func showsSignInButton() {
                }
            }
            """
        } diagnostics: {
            """
            struct LoginTests {
                @UITest
                ┬──────
                ╰─ 🛑 '@UITest' can only be used in a class marked '@UITestSuite'
                func showsSignInButton() {
                }
            }
            """
        }
    }

    @Test
    func functionOutsideATypeIsRejected() {
        assertMacro {
            """
            @UITest
            func showsSignInButton() {
            }
            """
        } diagnostics: {
            """
            @UITest
            ┬──────
            ╰─ 🛑 '@UITest' can only be used in a class marked '@UITestSuite'
            func showsSignInButton() {
            }
            """
        }
    }

    @Test
    func unsupportedParameterIsRejected() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(app: XCUIApplication, retries count: Int) {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(app: XCUIApplication, retries count: Int) {
                                                                            ┬──
                                                                            ╰─ 🛑 '@UITest' cannot provide a value for parameter 'count'; a UI test can only take 'XCUIApplication' and 'UITestContext' parameters
                }
            }
            """
        }
    }

    @Test
    func functionReturningAValueIsRejected() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() -> Bool {
                    true
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() -> Bool {
                                            ┬───
                                            ╰─ 🛑 '@UITest' cannot be applied to a function that returns a value
                    true
                }
            }
            """
        }
    }

    @Test
    func genericFunctionIsRejected() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton<Screen>() {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton<Screen>() {
                                      ┬───────
                                      ╰─ 🛑 '@UITest' cannot be applied to a generic function
                }
            }
            """
        }
    }

    @Test
    func functionWithoutParametersNamedLikeAnXCTestTestOffersARename() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func testShowsSignInButton() {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func testShowsSignInButton() {
                     ┬────────────────────
                     ╰─ 🛑 XCTest would also run 'testShowsSignInButton()' directly, without launching the app; rename it so that it does not start with 'test'
                        ✏️ Rename to 'showsSignInButton'
                }
            }
            """
        } fixes: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton() {
                }
            }
            """
        }
    }

    @Test
    func renameKeepsALeadingAcronymReadable() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func test_URLFieldAcceptsInput() {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func test_URLFieldAcceptsInput() {
                     ┬────────────────────────
                     ╰─ 🛑 XCTest would also run 'test_URLFieldAcceptsInput()' directly, without launching the app; rename it so that it does not start with 'test'
                        ✏️ Rename to 'urlFieldAcceptsInput'
                }
            }
            """
        } fixes: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func urlFieldAcceptsInput() {
                }
            }
            """
        }
    }

    @Test
    func functionNamedTestHasNoRenameToOffer() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func test() {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func test() {
                     ┬───
                     ╰─ 🛑 XCTest would also run 'test()' directly, without launching the app; rename it so that it does not start with 'test'
                }
            }
            """
        }
    }

    @Test
    func functionWithParametersCanStartWithTest() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func testShowsSignInButton(app: XCUIApplication) {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                func testShowsSignInButton(app: XCUIApplication) {
                }

                @MainActor
                func test_testShowsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self) { context in
                        self.testShowsSignInButton(app: context.app)
                    }
                }
            }
            """
        }
    }

    @Test
    func worksTogetherWithUITestSuite() {
        assertMacro([
            MacroName.uiTest: MacroSpec(type: UITestMacro.self),
            MacroName.uiTestSuite: MacroSpec(type: UITestSuiteMacro.self, conformances: ["UITestSuite"])
        ]) {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests: XCTestCase {
                @UITest(traits: .launchArgument("--skip-onboarding"))
                func showsSignInButton(app: XCUIApplication) {
                    XCTAssertTrue(app.buttons["Sign in"].exists)
                }

                func helper() {
                }
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
                @MainActor
                func showsSignInButton(app: XCUIApplication) {
                    XCTAssertTrue(app.buttons["Sign in"].exists)
                }

                @MainActor
                func test_showsSignInButton() async throws {
                    try await UITesting.UITestRunner.run(self, traits: [.launchArgument("--skip-onboarding")]) { context in
                        self.showsSignInButton(app: context.app)
                    }
                }
                @MainActor

                func helper() {
                }
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    [.loggedOut]
                }
            }
            """
        }
    }

    @Test
    func functionWithArguments() {
        assertMacro {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                @UITest(arguments: Fruit.all)
                func selects(_ fruit: Fruit, app: XCUIApplication) throws {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                func selects(_ fruit: Fruit, app: XCUIApplication) throws {
                }

                @MainActor
                func test_selects() async throws {
                    try await UITesting.UITestRunner.run(self, arguments: Fruit.all, named: "fruit") { argument, context in
                        try self.selects(argument, app: context.app)
                    }
                }
            }
            """
        }
    }

    @Test
    func functionWithArgumentsAndTraitsThatDoesNotTakeTheApp() {
        assertMacro {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                @UITest(traits: .manualLaunch, .loggedOut, arguments: ["en", "fr"])
                func launches(in language: String) async {
                }
            }
            """
        } expansion: {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                func launches(in language: String) async {
                }

                @MainActor
                func test_launches() async throws {
                    try await UITesting.UITestRunner.run(self, traits: [.manualLaunch, .loggedOut], arguments: ["en", "fr"], named: "language") { argument, _ in
                        await self.launches(in: argument)
                    }
                }
            }
            """
        }
    }

    @Test
    func argumentsWithoutAParameterToReceiveThem() {
        assertMacro {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                @UITest(arguments: Fruit.all)
                func selects(app: XCUIApplication) {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                @UITest(arguments: Fruit.all)
                                   ┬────────
                                   ╰─ 🛑 '@UITest' has arguments, but the function has no parameter to receive them; add a parameter of the type of one argument
                func selects(app: XCUIApplication) {
                }
            }
            """
        }
    }

    @Test
    func argumentsWithTwoParametersToReceiveThem() {
        assertMacro {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                @UITest(arguments: Fruit.all)
                func selects(_ fruit: Fruit, count: Int) {
                }
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            final class FruitTests: XCTestCase {
                @UITest(arguments: Fruit.all)
                func selects(_ fruit: Fruit, count: Int) {
                                                    ┬──
                                                    ╰─ 🛑 '@UITest' cannot provide a value for parameter 'count'; a UI test with arguments takes one parameter for the argument, as well as 'XCUIApplication' and 'UITestContext' parameters
                }
            }
            """
        }
    }
}
