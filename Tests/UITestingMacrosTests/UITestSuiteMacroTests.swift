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
            @UITestSuite(.loggedOut, .launchArgument("--skip-onboarding"))
            final class LoginTests: XCTestCase {
                func testShowsSignInButton() {}
            }
            """
        } expansion: {
            """
            final class LoginTests: XCTestCase {
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
                .launch(AuthState(isLoggedIn: true, name: "Ada")),
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
            @UITestSuite(.loggedOut)
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
            @UITestSuite(.loggedOut)
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
            @UITestSuite(.loggedOut)
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
            @UITestSuite(.loggedOut)
            final class LoginTests {
            }
            """
        } diagnostics: {
            """
            @UITestSuite(.loggedOut)
            final class LoginTests {
                        ┬─────────
                        ╰─ 🛑 '@UITestSuite' can only be applied to a class that inherits from 'XCTestCase'
                           ✏️ Inherit from 'XCTestCase'
            }
            """
        } fixes: {
            """
            @UITestSuite(.loggedOut)
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
