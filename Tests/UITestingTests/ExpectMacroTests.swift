import Testing

@testable import UITesting

@Suite
struct ExpectMacroTests {
    private struct Account: Equatable {
        var name: String
        var isAdmin: Bool
    }

    @Test
    func trueConditionReportsNothing() {
        let label = "Signed in"

        let failures = reportedFailures {
            #UITestingExpect(label == "Signed in")
            #UITestingExpect(!label.isEmpty)
            #UITestingExpect(label.count > 3, "has a label", within: .seconds(1))
        }

        #Testing::expect(failures.isEmpty)
    }

    @Test
    func macroCanBeNamedByItsModule() {
        let label = "Signed out"

        let failures = reportedFailures {
            #UITesting::expect(label == "Signed out")
            #UITesting::expect(label == "Signed in")
        }

        #Testing::expect(failures.count == 1)
    }

    @Test
    func falseConditionIsReportedWhereItWasWritten() {
        let isVisible = false

        let line: UInt = #line + 2
        let failures = reportedFailures {
            #UITestingExpect(isVisible)
        }

        #Testing::expect(
            failures == [
                ExpectationFailure(message: "Expectation failed: isVisible", filePath: #filePath, line: line)
            ]
        )
    }

    @Test
    func testContinuesAfterAFailedExpectation() {
        let failures = reportedFailures {
            #UITestingExpect(1 > 2)
            #UITestingExpect(2 > 3)
        }

        #Testing::expect(failures.map(\.message) == ["Expectation failed: 1 > 2", "Expectation failed: 2 > 3"])
    }

    @Test
    func commentIsIncludedInTheMessage() {
        let isVisible = false

        let failures = reportedFailures {
            #UITestingExpect(isVisible, "after signing out")
        }

        #Testing::expect(failures.map(\.message) == ["Expectation failed: isVisible\nafter signing out"])
    }

    @Test
    func failedComparisonShowsHowTheValuesDiffer() {
        let label = "Signed out"

        let failures = reportedFailures {
            #UITestingExpect(label == "Signed in")
        }

        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed: label == "Signed in"
                (- expected, + actual)
                - "Signed in"
                + "Signed out"
                """
            ]
        )
    }

    @Test
    func failedComparisonOfStructuredValuesShowsTheChangedProperty() {
        let account = Account(name: "Ada", isAdmin: false)

        let failures = reportedFailures {
            #UITestingExpect(account == Account(name: "Ada", isAdmin: true), "after promotion")
        }

        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed: account == Account(name: "Ada", isAdmin: true)
                after promotion
                (- expected, + actual)
                  ExpectMacroTests.Account(
                    name: "Ada",
                -   isAdmin: true
                +   isAdmin: false
                  )
                """
            ]
        )
    }

    @Test
    func comparisonCanUseATypeInferredFromTheOtherSide() {
        let alignment: NSTextAlignmentStandIn = .leading
        let optionalName: String? = "Ada"

        let failures = reportedFailures {
            #UITestingExpect(alignment == .leading)
            #UITestingExpect(optionalName == "Ada")
            #UITestingExpect(optionalName != nil)
        }

        #Testing::expect(failures.isEmpty)
    }

    @Test
    func comparisonOfDifferentTypesIsSupported() {
        let text = "Signed in"
        let prefix = text.prefix(6)

        let failures = reportedFailures {
            #UITestingExpect(prefix == "Signed")
            #UITestingExpect(prefix == "Logged")
        }

        #Testing::expect(failures.count == 1)
        #Testing::expect(failures.first?.message.hasPrefix(#"Expectation failed: prefix == "Logged""#) == true)
    }

    @Test
    func conditionIsCheckedAgainUntilItIsTrue() {
        var evaluations = 0
        func becomesTrue() -> Bool {
            evaluations += 1
            return evaluations >= 3
        }

        let failures = reportedFailures {
            #UITestingExpect(becomesTrue(), within: .seconds(5))
        }

        #Testing::expect(failures.isEmpty)
        #Testing::expect(evaluations == 3)
    }

    @Test
    func comparisonIsCheckedAgainUntilItIsTrue() {
        var evaluations = 0
        func count() -> Int {
            evaluations += 1
            return evaluations
        }

        let failures = reportedFailures {
            #UITestingExpect(count() == 3, within: .seconds(5))
        }

        #Testing::expect(failures.isEmpty)
        #Testing::expect(evaluations == 3)
    }

    @Test
    func timeoutIsMentionedWhenTheConditionNeverBecomesTrue() {
        let label = "Loading"

        let failures = reportedFailures {
            #UITestingExpect(label == "Loaded", "after loading", within: .milliseconds(250))
        }

        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed after 0.25 seconds: label == "Loaded"
                after loading
                (- expected, + actual)
                - "Loaded"
                + "Loading"
                """
            ]
        )
    }

    @Test
    func throwingConditionPassesTheErrorOn() {
        func load() throws -> Int {
            throw TestError(message: "load")
        }

        #Testing::expect(throws: TestError(message: "load")) {
            try #UITestingExpect(try load() == 3)
        }
    }

    @MainActor
    @Test
    func conditionCanUseMainActorState() {
        let app = XCUIApplicationStandIn()

        let failures = reportedFailures {
            #UITestingExpect(app.isReady)
            #UITestingExpect(app.title == "Demo")
        }

        #Testing::expect(failures.isEmpty)
    }
}

private enum NSTextAlignmentStandIn: Equatable {
    case leading
    case trailing
}

@MainActor
private final class XCUIApplicationStandIn {
    var isReady = true
    var title = "Demo"
}
