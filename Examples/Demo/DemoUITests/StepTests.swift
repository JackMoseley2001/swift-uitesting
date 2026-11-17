import UITesting
import XCTest

@UITestSuite(traits: .example(.fruitList), .animationsDisabled)
final class StepTests: XCTestCase {
    @UITest
    func aTestCanBeWrittenAsNamedSteps(app: XCUIApplication) throws {
        try step("Pick a fruit") {
            try app[FruitID.row(Fruit.pear.id)].tap()
            #expect(app[FruitID.selection].label == "Selected Pear")
        }

        try step("Clear the selection") {
            try step("Wait for the button and tap it") {
                try app[FruitID.clearButton].tap()
            }
            #expect(app[FruitID.selection].label == "Nothing selected")
        }
    }

    @UITest
    func aStepReturnsAValue(app: XCUIApplication) throws {
        let selection = try step("Pick a fruit and read the selection") {
            try app[FruitID.row(Fruit.apple.id)].tap()
            return app[FruitID.selection].label
        }

        #expect(selection == "Selected Apple")
    }

    @UITest
    func stepsWorkInAnAsyncTest(app: XCUIApplication) async throws {
        try await step("Pick a fruit") {
            try app[FruitID.row(Fruit.cherry.id)].tap()
            try await #require(app[FruitID.selection].label == "Selected Cherry", within: .seconds(2))
        }
    }
}
