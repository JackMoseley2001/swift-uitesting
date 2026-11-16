import MacroTesting
import Testing

@testable import UITestingMacros

@Suite(.macros([MacroName.require: RequireMacro.self, MacroName.uiTestingRequire: RequireMacro.self]))
struct RequireMacroTests {
    @Test
    func condition() {
        assertMacro {
            """
            try #require(app.buttons["sign-in-button"].exists)
            """
        } expansion: {
            """
            try UITesting.__require(
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
    func conditionWithACommentAndATimeout() {
        assertMacro {
            """
            try #require(app.staticTexts["message"].exists, "after loading", within: .seconds(5))
            """
        } expansion: {
            """
            try UITesting.__require(
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
            try #require(app.staticTexts["auth-status"].label == "Signed in")
            """
        } expansion: {
            """
            try UITesting.__requireEqual(
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
    func comparisonWithNilIsLeftWhole() {
        assertMacro {
            """
            try #require(app.textFields["email"].value != nil)
            """
        } expansion: {
            """
            try UITesting.__require(
                {
                    app.textFields["email"].value != nil
                },
                expression: #"app.textFields["email"].value != nil"#,
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
            try #UITestingRequire(app.buttons["sign-in-button"].exists, within: .seconds(5))
            """
        } expansion: {
            """
            try UITesting.__require(
                {
                    app.buttons["sign-in-button"].exists
                },
                expression: #"app.buttons["sign-in-button"].exists"#,
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func awaitInTheConditionIsRejected() {
        assertMacro {
            """
            try #require(await model.isLoaded)
            """
        } diagnostics: {
            """
            try #require(await model.isLoaded)
                         ┬────
                         ╰─ 🛑 '#require' cannot await inside its condition; await the value first and pass the result
            """
        }
    }

    @Test
    func constantConditionGetsAWarning() {
        assertMacro {
            """
            try #require(false)
            """
        } diagnostics: {
            """
            try #require(false)
                         ┬────
                         ╰─ ⚠️ '#require' is given a constant, so it will always have the same result
            """
        } expansion: {
            """
            try UITesting.__require(
                {
                    false
                },
                expression: "false",
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }
}

@Suite(.macros([MacroName.require: RequireValueMacro.self, MacroName.uiTestingRequire: RequireValueMacro.self]))
struct RequireValueMacroTests {
    @Test
    func value() {
        assertMacro {
            """
            let title = try #require(app.staticTexts["title"].value as? String)
            """
        } expansion: {
            """
            let title = try UITesting.__requireValue(
                {
                    app.staticTexts["title"].value as? String
                },
                expression: #"app.staticTexts["title"].value as? String"#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func valueWithACommentAndATimeout() {
        assertMacro {
            """
            let title = try #require(app.staticTexts["title"].value as? String, "after loading", within: .seconds(5))
            """
        } expansion: {
            """
            let title = try UITesting.__requireValue(
                {
                    app.staticTexts["title"].value as? String
                },
                expression: #"app.staticTexts["title"].value as? String"#,
                comment: "after loading",
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func tryAndAwaitBeforeTheMacroAreKept() {
        assertMacro {
            """
            let title = try await #require(app.staticTexts["title"].value as? String, within: .seconds(5))
            """
        } expansion: {
            """
            let title = try await UITesting.__requireValue(
                {
                    app.staticTexts["title"].value as? String
                },
                expression: #"app.staticTexts["title"].value as? String"#,
                timeout: .seconds(5),
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func comparisonIsNotSplitWhenUnwrapping() {
        assertMacro {
            """
            let match = try #require(names.first { $0 == "Ada" })
            """
        } expansion: {
            """
            let match = try UITesting.__requireValue(
                {
                    names.first {
                        $0 == "Ada"
                    }
                },
                expression: #"names.first { $0 == "Ada" }"#,
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
            let title = try #UITestingRequire(app.staticTexts["title"].value as? String)
            """
        } expansion: {
            """
            let title = try UITesting.__requireValue(
                {
                    app.staticTexts["title"].value as? String
                },
                expression: #"app.staticTexts["title"].value as? String"#,
                filePath: "Test.swift",
                line: 1
            )
            """
        }
    }

    @Test
    func awaitInTheValueIsRejected() {
        assertMacro {
            """
            let title = try #require(await model.title)
            """
        } diagnostics: {
            """
            let title = try #require(await model.title)
                                     ┬────
                                     ╰─ 🛑 '#require' cannot await inside its value; await the value first and pass the result
            """
        }
    }

    @Test
    func callThatCouldNotBeParsedIsRejected() {
        assertMacro {
            """
            let title = try #require()
            """
        } diagnostics: {
            """
            let title = try #require()
                            ┬─────────
                            ╰─ 🛑 '#require' could not read its value; writing a module name before the macro requires swift-syntax 603 or later
            """
        }
    }
}
