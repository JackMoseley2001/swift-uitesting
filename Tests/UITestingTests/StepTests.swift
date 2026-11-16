import Testing

@testable import UITesting

@Suite
struct StepTests {
    @Test
    func messageOutsideAStepIsUnchanged() {
        #Testing::expect(StepPath.describing("Could not tap", in: []) == "Could not tap")
    }

    @Test
    func messageInAStepStartsWithItsName() {
        #Testing::expect(StepPath.describing("Could not tap", in: ["Sign in"]) == "[Sign in] Could not tap")
    }

    @Test
    func nestedStepsAreListedOutermostFirst() {
        #Testing::expect(
            StepPath.describing("Could not tap", in: ["Sign in", "Enter the password"])
                == "[Sign in › Enter the password] Could not tap"
        )
    }

    @Test
    @MainActor
    func stepReturnsWhatItsBodyReturns() {
        StepPath.$opensActivities.withValue(false) {
            #Testing::expect(step("Add") { 1 + 2 } == 3)
        }
    }

    @Test
    @MainActor
    func stepsAreKnownInsideTheirBody() {
        StepPath.$opensActivities.withValue(false) {
            #Testing::expect(StepPath.current.isEmpty)

            step("Outer") {
                #Testing::expect(StepPath.current == ["Outer"])
                step("Inner") {
                    #Testing::expect(StepPath.current == ["Outer", "Inner"])
                }
                #Testing::expect(StepPath.current == ["Outer"])
            }

            #Testing::expect(StepPath.current.isEmpty)
        }
    }

    @Test
    @MainActor
    func asyncStepsAreKnownInsideTheirBody() async {
        await StepPath.$opensActivities.withValue(false) {
            let value = await step("Outer") {
                await Task.yield()
                return await step("Inner") {
                    await Task.yield()
                    return StepPath.current
                }
            }

            #Testing::expect(value == ["Outer", "Inner"])
            #Testing::expect(StepPath.current.isEmpty)
        }
    }

    @Test
    @MainActor
    func stepRethrowsTheErrorOfItsBody() {
        StepPath.$opensActivities.withValue(false) {
            struct Failure: Error {}

            #Testing::expect(throws: Failure.self) {
                try step("Fail") { throw Failure() }
            }
            #Testing::expect(StepPath.current.isEmpty)
        }
    }

    @Test
    @MainActor
    func reportedFailureSaysWhichStepItWasIn() {
        StepPath.$opensActivities.withValue(false) {
            let failures = Collected()

            ExpectationReporter.$handler.withValue({ failures.add($0.message) }) {
                step("Sign in") {
                    ExpectationReporter.report(message: "Could not tap", filePath: #filePath, line: #line)
                }
                ExpectationReporter.report(message: "Could not tap", filePath: #filePath, line: #line)
            }

            #Testing::expect(failures.messages == ["[Sign in] Could not tap", "Could not tap"])
        }
    }

    @Test
    @MainActor
    func failureIsCapturedOnce() {
        var captures = 0
        let capture = FailureCapture { captures += 1 }

        capture.captureOnce()
        capture.captureOnce()

        #Testing::expect(captures == 1)
    }

    @Test
    @MainActor
    func reportingAFailureCapturesTheRunningTest() {
        var captures = 0
        let capture = FailureCapture { captures += 1 }

        ExpectationReporter.$handler.withValue({ _ in }) {
            RunningTest.$failureCapture.withValue(capture) {
                ExpectationReporter.report(message: "First", filePath: #filePath, line: #line)
                ExpectationReporter.report(message: "Second", filePath: #filePath, line: #line)
            }
            ExpectationReporter.report(message: "Outside a test", filePath: #filePath, line: #line)
        }

        #Testing::expect(captures == 1)
    }

    @Test
    func failureAttachmentsAreOnUnlessATraitTurnsThemOff() {
        #Testing::expect(FailureAttachmentsTrait.isEnabled(in: []))
        #Testing::expect(!FailureAttachmentsTrait.isEnabled(in: [.failureAttachments(false)]))
        #Testing::expect(
            FailureAttachmentsTrait.isEnabled(in: [.failureAttachments(false), .failureAttachments(true)])
        )
    }
}

private final class Collected: @unchecked Sendable {
    private(set) var messages: [String] = []

    func add(_ message: String) {
        messages.append(message)
    }
}
