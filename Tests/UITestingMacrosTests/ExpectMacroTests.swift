import MacroTesting
import Testing

@testable import UITestingMacros

@Suite(.macros([MacroName.expect: ExpectMacro.self, MacroName.uiTestingExpect: ExpectMacro.self]))
struct ExpectMacroTests {
    @Test
    func condition() {
        assertMacro {
            """
            #expect(app.buttons["sign-in-button"].exists)
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    app.buttons["sign-in-button"].exists
                },
                expression: #"app.buttons["sign-in-button"].exists"#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func negatedCondition() {
        assertMacro {
            """
            #expect(!app.buttons["sign-in-button"].exists)
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    !app.buttons["sign-in-button"].exists
                },
                expression: #"!app.buttons["sign-in-button"].exists"#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func conditionWithAComment() {
        assertMacro {
            """
            #expect(app.buttons["sign-in-button"].exists, "after signing out")
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    app.buttons["sign-in-button"].exists
                },
                expression: #"app.buttons["sign-in-button"].exists"#,
                comment: "after signing out",
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func conditionWithATimeout() {
        assertMacro {
            """
            #expect(app.staticTexts["message"].exists, within: .seconds(5))
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    app.staticTexts["message"].exists
                },
                expression: #"app.staticTexts["message"].exists"#,
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func conditionWithACommentAndATimeout() {
        assertMacro {
            """
            #expect(app.staticTexts["message"].exists, "after loading", within: .seconds(5))
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    app.staticTexts["message"].exists
                },
                expression: #"app.staticTexts["message"].exists"#,
                comment: "after loading",
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func equalityPassesEachSideSeparately() {
        assertMacro {
            """
            #expect(app.staticTexts["auth-status"].label == "Signed in")
            """
        } expansion: {
            """
            UITesting.__expectEqual(
                {
                    app.staticTexts["auth-status"].label
                },
                {
                    "Signed in"
                },
                {
                    $0 == $1
                },
                expression: #"app.staticTexts["auth-status"].label == "Signed in""#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func equalityWithACommentAndATimeout() {
        assertMacro {
            """
            #expect(app.staticTexts.count == 3, "after loading", within: .seconds(2))
            """
        } expansion: {
            """
            UITesting.__expectEqual(
                {
                    app.staticTexts.count
                },
                {
                    3
                },
                {
                    $0 == $1
                },
                expression: "app.staticTexts.count == 3",
                comment: "after loading",
                timeout: .seconds(2),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func equalityInsideALargerConditionIsLeftWhole() {
        assertMacro {
            """
            #expect(label == "Signed in" && isEnabled)
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    label == "Signed in" && isEnabled
                },
                expression: #"label == "Signed in" && isEnabled"#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func otherComparisonsAreLeftWhole() {
        assertMacro {
            """
            #expect(app.cells.count > 3)
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    app.cells.count > 3
                },
                expression: "app.cells.count > 3",
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func comparisonWithNilIsLeftWhole() {
        assertMacro {
            """
            #expect(app.textFields["email"].value == nil)
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    app.textFields["email"].value == nil
                },
                expression: #"app.textFields["email"].value == nil"#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func conditionThatSpansSeveralLinesIsDescribedOnOne() {
        assertMacro {
            """
            #expect(
                app.staticTexts["auth-status"].label
                    == "Signed in"
            )
            """
        } expansion: {
            """
            UITesting.__expectEqual(
                {
                    app.staticTexts["auth-status"].label
                },
                {
                    "Signed in"
                },
                {
                    $0 == $1
                },
                expression: #"app.staticTexts["auth-status"].label == "Signed in""#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func conditionContainingQuotesAndBackslashes() {
        assertMacro {
            #"""
            #expect(app.staticTexts["path"].label == "C:\\Users")
            """#
        } expansion: {
            #"""
            UITesting.__expectEqual(
                {
                    app.staticTexts["path"].label
                },
                {
                    "C:\\Users"
                },
                {
                    $0 == $1
                },
                expression: #"app.staticTexts["path"].label == "C:\\Users""#,
                filePath: "Test.swift",
                line: 1
            )
            """#
        }
    }

    @Test
    func throwingCondition() {
        assertMacro {
            """
            try #expect(try loadCount() == 3)
            """
        } expansion: {
            """
            try UITesting.__expect(
                {
                    try loadCount() == 3
                },
                expression: "try loadCount() == 3",
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func callThatCouldNotBeParsedIsRejected() {
        assertMacro {
            """
            #expect()
            """
        } diagnostics: {
            """
            #expect()
            ┬────────
            ╰─ 🛑 '#expect' could not read its condition; writing a module name before the macro requires swift-syntax 603 or later
            """
        }
    }

    @Test
    func awaitInTheConditionIsRejected() {
        assertMacro {
            """
            #expect(await model.isLoaded)
            """
        } diagnostics: {
            """
            #expect(await model.isLoaded)
                    ┬────
                    ╰─ 🛑 '#expect' cannot await inside its condition; await the value first and pass the result
            """
        }
    }

    @Test
    func constantConditionGetsAWarning() {
        assertMacro {
            """
            #expect(true)
            """
        } diagnostics: {
            """
            #expect(true)
                    ┬───
                    ╰─ ⚠️ '#expect' is given a constant, so it will always have the same result
            """
        } expansion: {
            """
            UITesting.__expect(
                {
                    true
                },
                expression: "true",
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func awaitBeforeTheMacroIsKept() {
        assertMacro {
            """
            await #expect(app.staticTexts["message"].exists, within: .seconds(5))
            """
        } expansion: {
            """
            await UITesting.__expect(
                {
                    app.staticTexts["message"].exists
                },
                expression: #"app.staticTexts["message"].exists"#,
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func secondNameExpandsInTheSameWay() {
        assertMacro {
            """
            #UITestingExpect(app.staticTexts["auth-status"].label == "Signed in", within: .seconds(5))
            """
        } expansion: {
            """
            UITesting.__expectEqual(
                {
                    app.staticTexts["auth-status"].label
                },
                {
                    "Signed in"
                },
                {
                    $0 == $1
                },
                expression: #"app.staticTexts["auth-status"].label == "Signed in""#,
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func diagnosticsUseTheNameTheMacroWasWrittenWith() {
        assertMacro {
            """
            #UITestingExpect(await model.isLoaded)
            """
        } diagnostics: {
            """
            #UITestingExpect(await model.isLoaded)
                             ┬────
                             ╰─ 🛑 '#UITestingExpect' cannot await inside its condition; await the value first and pass the result
            """
        }
    }
}
