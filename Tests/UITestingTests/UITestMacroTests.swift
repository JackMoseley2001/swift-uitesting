import Testing
import XCTest

@testable import UITesting

@UITestSuite(traits: .launchArgument("--suite"))
final class SuiteWithGeneratedTests: XCTestCase {
    /// Keeps XCTest from running the generated tests, which would try to launch an app.
    override static var defaultTestSuite: XCTestSuite {
        XCTestSuite(name: "SuiteWithGeneratedTests")
    }

    @UITest
    func withoutParameters() {}

    @UITest(traits: .environment("SCOPE", "test"))
    func takingTheApp(app: XCUIApplication) async throws {}

    @UITest
    func takingTheContext(_ context: UITestContext) throws {}

    @UITest
    func takingBoth(in application: XCUIApplication, context: UITestContext) async {}

    func notATest() {}
}

@Suite
struct UITestMacroTests {
    @Test
    func xcTestDiscoversTheGeneratedTestMethods() {
        let tests = XCTestSuite(forTestCaseClass: SuiteWithGeneratedTests.self).tests

        // A test is named "-[Module.Class method]".
        let methods = tests.compactMap { $0.name.split(separator: " ").last?.dropLast() }.map(String.init)

        #Testing::expect(
            methods.sorted() == [
                "test_takingBoth",
                "test_takingTheApp",
                "test_takingTheContext",
                "test_withoutParameters"
            ]
        )
    }
}
