import UITesting
import XCTest

@UITestSuite(traits: .animationsDisabled)
final class NavigationTests: XCTestCase {
    @UITest
    func theAppOpensOnTheListOfExamples(app: XCUIApplication) throws {
        #expect(app.navigationTitle == "Examples")
        for example in Example.allCases {
            // The list is longer than a small screen, and a row below it does not exist yet.
            try app[ExampleID.row(example)].scrollIntoView()
        }
    }

    @UITest
    func tappingAnExampleOpensItsScreen(app: XCUIApplication) throws {
        try app[ExampleID.row(.fruitList)].tap()

        try app[FruitID.selection].waitToAppear()
        // On watchOS the bar with the title comes a moment after the screen.
        #expect(app.navigationTitle == Example.fruitList.title, within: .seconds(2))
    }

    @UITest
    func goingBackReturnsToTheList(app: XCUIApplication) throws {
        try app[ExampleID.row(.message)].tap()
        try app[MessageID.loadButton].waitToAppear()

        try app.goBack()

        try app[ExampleID.row(.message)].waitToAppear()
    }

    @UITest(traits: .example(.message))
    func aTestCanOpenTheAppOnAnExample(app: XCUIApplication) {
        #expect(app[MessageID.loadButton].exists)
        #expect(!app[ExampleID.row(.message)].exists)
    }
}
