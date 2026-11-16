import MacroTesting
import SwiftSyntaxMacroExpansion
import Testing

@testable import UITestingMacros

@Suite(.macros([MacroName.uiTestSuite: MacroSpec(type: UITestSuiteMacro.self, conformances: ["UITestSuite"])]))
struct UITestSuiteMacroTests {
    @Test
    func addsConformanceAndTraits() {
        assertMacro {
            """
            @UITestSuite(traits: .loggedOut, .launchArgument("--skip-onboarding"))
            final class LoginTests: XCTestCase {
                func testShowsSignInButton() {}
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
                @MainActor
                func testShowsSignInButton() {}
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    [.loggedOut, .launchArgument("--skip-onboarding")]
                }
            }
            """
        }
    }

    @Test
    func withoutArgumentsHasNoTraits() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    []
                }
            }
            """
        }
    }

    @Test
    func withEmptyArgumentListHasNoTraits() {
        assertMacro {
            """
            @UITestSuite()
            final class LoginTests: XCTestCase {
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    []
                }
            }
            """
        }
    }

    @Test
    func keepsArgumentsThatSpanSeveralLines() {
        assertMacro {
            """
            @UITestSuite(
                traits: .launch(AuthState(isLoggedIn: true, name: "Ada")),
                .environment("API_BASE_URL", "http://localhost:8080")
            )
            final class LoginTests: XCTestCase {
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    [.launch(AuthState(isLoggedIn: true, name: "Ada")), .environment("API_BASE_URL", "http://localhost:8080")]
                }
            }
            """
        }
    }

    @Test
    func publicClassGetsAPublicProperty() {
        assertMacro {
            """
            @UITestSuite(traits: .loggedOut)
            public final class LoginTests: XCTestCase {
            }
            """
        } expansion: {
            """
            public final class LoginTests: XCTestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                public nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    [.loggedOut]
                }
            }
            """
        }
    }

    @Test
    func openClassGetsAPublicProperty() {
        assertMacro {
            """
            @UITestSuite(traits: .loggedOut)
            open class LoginTests: XCTestCase {
            }
            """
        } expansion: {
            """
            open class LoginTests: XCTestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                public nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    [.loggedOut]
                }
            }
            """
        }
    }

    @Test
    func classThatAlreadyConformsOnlyGetsTheTraits() {
        assertMacro([MacroName.uiTestSuite: MacroSpec(type: UITestSuiteMacro.self)]) {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests: XCTestCase, UITestSuite {
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase, UITestSuite {
            }

            extension LoginTests {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    [.loggedOut]
                }
            }
            """
        }
    }

    @Test
    func classWithACustomSuperclassIsAccepted() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: BaseUITestCase {
            }
            """
        } expansion: {
            """
            final class LoginTests: BaseUITestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    []
                }
            }
            """
        }
    }

    // The expansion shows an added attribute above the blank line that came before the
    // member. That is how the test support prints it, and it makes no difference to the compiler.
    @Test
    func isolatesFunctionsAndComputedPropertiesToTheMainActor() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @UITest
                func showsSignInButton(app: XCUIApplication) {
                }

                @UITest(traits: .loggedOut)
                func showsHome() async throws {
                }

                func helper() {
                }

                static func sharedHelper() {
                }

                var signInButton: XCUIElement {
                    XCUIApplication().buttons["signIn"]
                }

                var isReady = false

                var launches = 0 {
                    didSet {
                    }
                }
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
                @UITest
                @MainActor
                func showsSignInButton(app: XCUIApplication) {
                }

                @UITest(traits: .loggedOut)
                @MainActor
                func showsHome() async throws {
                }
                @MainActor

                func helper() {
                }
                @MainActor

                static func sharedHelper() {
                }
                @MainActor

                var signInButton: XCUIElement {
                    XCUIApplication().buttons["signIn"]
                }

                var isReady = false

                var launches = 0 {
                    didSet {
                    }
                }
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    []
                }
            }
            """
        }
    }

    @Test
    func leavesFunctionsThatAlreadyStateTheirIsolation() {
        assertMacro {
            """
            @UITestSuite
            final class LoginTests: XCTestCase {
                @MainActor
                @UITest
                func showsSignInButton() {
                }

                @UITest
                nonisolated func showsHome() {
                }

                nonisolated func helper() {
                }

                @DatabaseActor
                func otherHelper() {
                }

                @Swift.MainActor
                var title: String {
                    "Login"
                }

                override func setUp() {
                }

                override var description: String {
                    "LoginTests"
                }
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
                @MainActor
                @UITest
                func showsSignInButton() {
                }

                @UITest
                nonisolated func showsHome() {
                }

                nonisolated func helper() {
                }

                @DatabaseActor
                func otherHelper() {
                }

                @Swift.MainActor
                var title: String {
                    "Login"
                }

                override func setUp() {
                }

                override var description: String {
                    "LoginTests"
                }
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    []
                }
            }
            """
        }
    }

    @Test
    func structIsRejected() {
        assertMacro {
            """
            @UITestSuite
            struct LoginTests {
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            ┬───────────
            ╰─ 🛑 '@UITestSuite' can only be applied to a class that inherits from 'XCTestCase'
            struct LoginTests {
            }
            """
        }
    }

    @Test
    func classWithoutASuperclassOffersToInheritFromXCTestCase() {
        assertMacro {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests {
            }
            """
        } diagnostics: {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests {
                        ┬─────────
                        ╰─ 🛑 '@UITestSuite' can only be applied to a class that inherits from 'XCTestCase'
                           ✏️ Inherit from 'XCTestCase'
            }
            """
        } fixes: {
            """
            @UITestSuite(traits: .loggedOut)
            final class LoginTests: XCTestCase {
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
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
    func genericClassWithoutASuperclassOffersToInheritFromXCTestCase() {
        assertMacro {
            """
            @UITestSuite
            class LoginTests<Screen> {
            }
            """
        } diagnostics: {
            """
            @UITestSuite
            class LoginTests<Screen> {
                  ┬─────────
                  ╰─ 🛑 '@UITestSuite' can only be applied to a class that inherits from 'XCTestCase'
                     ✏️ Inherit from 'XCTestCase'
            }
            """
        } fixes: {
            """
            @UITestSuite
            class LoginTests<Screen>: XCTestCase {
            }
            """
        } expansion: {
            """
            class LoginTests<Screen>: XCTestCase {
            }

            extension LoginTests: UITesting.UITestSuite {
                nonisolated static var suiteTraits: [any UITesting.UITestTrait] {
                    []
                }
            }
            """
        }
    }
}
