import Testing
import XCTest

@testable import UITesting

@MainActor
@Suite
final class ArgumentRunTests {
    private var events: [String] = []
    private var recorded: [String] = []

    private func run(
        _ arguments: [String],
        named name: String? = "fruit",
        body: @MainActor (String) async throws -> Void = { _ in }
    ) async throws {
        try await StepPath.$opensActivities.withValue(false) {
            try await UITestRunner.forEachArgument(
                arguments,
                named: name,
                run: { argument in
                    events.append("run \(argument) in \(StepPath.current)")
                    try await body(argument)
                },
                recordError: { description, _ in recorded.append(description) }
            )
        }
    }

    @Test
    func eachArgumentIsRunInOrderAsAStepOfItsOwn() async throws {
        try await run(["Apple", "Pear"])

        #Testing::expect(events == [#"run Apple in ["fruit: Apple"]"#, #"run Pear in ["fruit: Pear"]"#])
        #Testing::expect(recorded.isEmpty)
    }

    @Test
    func nothingIsRunWithoutArguments() async throws {
        try await run([])

        #Testing::expect(events.isEmpty)
    }

    @Test
    func errorWithOneArgumentIsRecordedAndTheRestAreStillRun() async throws {
        try await run(["Apple", "Pear", "Cherry"]) { argument in
            if argument == "Pear" { throw TestError(message: "no pears") }
        }

        #Testing::expect(events.count == 3)
        #Testing::expect(recorded == [#"[fruit: Pear] TestError(message: "no pears")"#])
    }

    @Test
    func skipEndsTheTestWithoutRunningTheOtherArguments() async {
        await #Testing::expect(throws: XCTSkip.self) {
            try await self.run(["Apple", "Pear"]) { _ in throw XCTSkip("Not today") }
        }

        #Testing::expect(events.count == 1)
        #Testing::expect(recorded.isEmpty)
    }

    @Test
    func argumentIsNamedAfterItsParameter() {
        #Testing::expect(UITestRunner.argumentLabel(for: 3, named: "count") == "count: 3")
        #Testing::expect(UITestRunner.argumentLabel(for: "fr", named: nil) == "fr")
        #Testing::expect(UITestRunner.argumentLabel(for: "fr", named: "_") == "fr")
    }
}
