import Testing

@testable import UITesting

@Suite
struct RequireMacroTests {
    @Test
    func metRequirementReportsNothing() throws {
        let label = "Signed in"

        let failures = try reportedFailures {
            try #UITestingRequire(label == "Signed in")
            try #UITestingRequire(!label.isEmpty, "has a label", within: .seconds(1))
        }

        #Testing::expect(failures.isEmpty)
    }

    @Test
    func unmetRequirementIsThrown() {
        let isVisible = false

        #Testing::expect(throws: RequirementFailedError.self) {
            _ = try reportedFailures {
                try #UITestingRequire(isVisible)
            }
        }
    }

    @Test
    func reportedLineIsTheLineOfTheRequirement() {
        let isVisible = false

        let line: UInt = #line + 3
        let failures = reportedFailures {
            do {
                try #UITestingRequire(isVisible)
            } catch {}
        }

        #Testing::expect(
            failures == [
                ExpectationFailure(message: "Requirement failed: isVisible", filePath: #filePath, line: line)
            ]
        )
    }

    @Test
    func codeAfterAnUnmetRequirementDoesNotRun() {
        var reachedTheEnd = false

        let failures = reportedFailures {
            do {
                try #UITestingRequire(1 > 2)
                reachedTheEnd = true
            } catch {}
        }

        #Testing::expect(!reachedTheEnd)
        #Testing::expect(failures.count == 1)
    }

    @Test
    func thrownErrorDescribesTheRequirement() {
        let label = "Signed out"
        var thrown: (any Error)?

        _ = reportedFailures {
            do {
                try #UITestingRequire(label == "Signed in", "after signing in")
            } catch {
                thrown = error
            }
        }

        #Testing::expect(
            (thrown as? RequirementFailedError)?.message == """
                Requirement failed: label == "Signed in"
                after signing in
                - "Signed in"
                + "Signed out"
                """
        )
    }

    @Test
    func requirementIsCheckedAgainUntilItIsMet() throws {
        var evaluations = 0
        func becomesTrue() -> Bool {
            evaluations += 1
            return evaluations >= 3
        }

        let failures = try reportedFailures {
            try #UITestingRequire(becomesTrue(), within: .seconds(5))
        }

        #Testing::expect(failures.isEmpty)
        #Testing::expect(evaluations == 3)
    }

    @Test
    func timeoutIsMentionedWhenTheRequirementIsNeverMet() {
        let isLoaded = false

        let failures = reportedFailures {
            _ = try? #UITestingRequire(isLoaded, within: .milliseconds(250))
        }

        #Testing::expect(failures.map(\.message) == ["Requirement failed after 0.25 seconds: isLoaded"])
    }

    @Test
    func valueIsUnwrapped() throws {
        let optionalName: String? = "Ada"

        let name = try #UITestingRequire(optionalName)

        #Testing::expect(name == "Ada")
    }

    @Test
    func missingValueIsReportedAndThrown() {
        let optionalName: String? = nil
        var thrown: (any Error)?

        let failures = reportedFailures {
            do {
                _ = try #UITestingRequire(optionalName, "after signing in")
            } catch {
                thrown = error
            }
        }

        #Testing::expect(failures.map(\.message) == ["Required value was nil: optionalName\nafter signing in"])
        #Testing::expect(thrown is RequirementFailedError)
    }

    @Test
    func valueIsReadAgainUntilThereIsOne() throws {
        var evaluations = 0
        func loadedName() -> String? {
            evaluations += 1
            return evaluations >= 3 ? "Ada" : nil
        }

        let name = try #UITestingRequire(loadedName(), within: .seconds(5))

        #Testing::expect(name == "Ada")
        #Testing::expect(evaluations == 3)
    }

    @Test
    func timeoutIsMentionedWhenThereIsNeverAValue() {
        let optionalName: String? = nil

        let failures = reportedFailures {
            _ = try? #UITestingRequire(optionalName, within: .milliseconds(250))
        }

        #Testing::expect(failures.map(\.message) == ["Required value was nil after 0.25 seconds: optionalName"])
    }

    @Test
    func macroCanBeNamedByItsModule() throws {
        let optionalName: String? = "Ada"

        let failures = try reportedFailures {
            try #UITesting::require(optionalName != nil)
            let name = try #UITesting::require(optionalName)
            #Testing::expect(name == "Ada")
        }

        #Testing::expect(failures.isEmpty)
    }

    @MainActor
    @Test
    func runnerEndsATestQuietlyWhenARequirementIsNotMet() async throws {
        try await UITestRunner.endingOnFailedRequirement {
            throw RequirementFailedError(message: "Requirement failed: isVisible")
        }
    }

    @MainActor
    @Test
    func runnerPassesOtherErrorsOn() async {
        await #Testing::expect(throws: TestError(message: "other")) {
            try await UITestRunner.endingOnFailedRequirement {
                throw TestError(message: "other")
            }
        }
    }
}
