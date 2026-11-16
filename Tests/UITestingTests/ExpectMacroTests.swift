import Foundation
import Testing

@testable import UITesting

@Suite
struct ExpectMacroTests {
    private struct Account: Equatable {
        var name: String
        var isAdmin: Bool
    }

    /// Runs an operation and returns the expectation failures it reported.
    private func failures(in operation: () throws -> Void) rethrows -> [ExpectationFailure] {
        let recorded = Recorded()
        try ExpectationReporter.$handler.withValue({ recorded.append($0) }) {
            try operation()
        }
        return recorded.failures
    }

    private final class Recorded: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [ExpectationFailure] = []

        var failures: [ExpectationFailure] {
            lock.withLock { storage }
        }

        func append(_ failure: ExpectationFailure) {
            lock.withLock { storage.append(failure) }
        }
    }

    @Test
    func trueConditionReportsNothing() {
        let label = "Signed in"

        let failures = failures {
            #UITestingExpect(label == "Signed in")
            #UITestingExpect(!label.isEmpty)
            #UITestingExpect(label.count > 3, "has a label", within: .seconds(1))
        }

        #Testing::expect(failures.isEmpty)
    }

    @Test
    func macroCanBeNamedByItsModule() {
        let label = "Signed out"

        let failures = failures {
            #UITesting::expect(label == "Signed out")
            #UITesting::expect(label == "Signed in")
        }

        #Testing::expect(failures.count == 1)
    }

    @Test
    func falseConditionIsReportedWhereItWasWritten() {
        let isVisible = false

        let line: UInt = #line + 2
        let failures = failures {
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
        let failures = failures {
            #UITestingExpect(1 > 2)
            #UITestingExpect(2 > 3)
        }

        #Testing::expect(failures.map(\.message) == ["Expectation failed: 1 > 2", "Expectation failed: 2 > 3"])
    }

    @Test
    func commentIsIncludedInTheMessage() {
        let isVisible = false

        let failures = failures {
            #UITestingExpect(isVisible, "after signing out")
        }

        #Testing::expect(failures.map(\.message) == ["Expectation failed: isVisible\nafter signing out"])
    }

    @Test
    func failedComparisonShowsHowTheValuesDiffer() {
        let label = "Signed out"

        let failures = failures {
            #UITestingExpect(label == "Signed in")
        }

        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed: label == "Signed in"
                - "Signed out"
                + "Signed in"
                """
            ]
        )
    }

    @Test
    func failedComparisonOfStructuredValuesShowsTheChangedProperty() {
        let account = Account(name: "Ada", isAdmin: false)

        let failures = failures {
            #UITestingExpect(account == Account(name: "Ada", isAdmin: true), "after promotion")
        }

        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed: account == Account(name: "Ada", isAdmin: true)
                after promotion
                  ExpectMacroTests.Account(
                    name: "Ada",
                -   isAdmin: false
                +   isAdmin: true
                  )
                """
            ]
        )
    }

    @Test
    func comparisonCanUseATypeInferredFromTheOtherSide() {
        let alignment: NSTextAlignmentStandIn = .leading
        let optionalName: String? = "Ada"

        let failures = failures {
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

        let failures = failures {
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

        let failures = failures {
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

        let failures = failures {
            #UITestingExpect(count() == 3, within: .seconds(5))
        }

        #Testing::expect(failures.isEmpty)
        #Testing::expect(evaluations == 3)
    }

    @Test
    func timeoutIsMentionedWhenTheConditionNeverBecomesTrue() {
        let label = "Loading"

        let failures = failures {
            #UITestingExpect(label == "Loaded", "after loading", within: .milliseconds(250))
        }

        #Testing::expect(
            failures.map(\.message) == [
                """
                Expectation failed after 0.25 seconds: label == "Loaded"
                after loading
                - "Loading"
                + "Loaded"
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

        let failures = failures {
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
