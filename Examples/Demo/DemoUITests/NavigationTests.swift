import UITesting
import XCTest

@UITestSuite(traits: .animationsDisabled)
final class NavigationTests: XCTestCase {
    @UITest
    func theAppOpensOnTheListOfExamples(app: XCUIApplication) {
        #expect(app.navigationBars["Examples"].exists)
        for example in Example.allCases {
            #expect(app[ExampleID.row(example)].exists)
        }
    }

    @UITest
    func tappingAnExampleOpensItsScreen(app: XCUIApplication) throws {
        try app[ExampleID.row(.fruitList)].tap()

        try app[FruitID.selection].waitToAppear()
        #expect(app.navigationBars[Example.fruitList.title].exists)
    }

    @UITest
    func goingBackReturnsToTheList(app: XCUIApplication) throws {
        try app[ExampleID.row(.message)].tap()
        try app[MessageID.loadButton].waitToAppear()

        app.navigationBars.buttons.firstMatch.tap()

        try app[ExampleID.row(.message)].waitToAppear()
    }

    @UITest(traits: .example(.message))
    func aTestCanOpenTheAppOnAnExample(app: XCUIApplication) {
        #expect(app[MessageID.loadButton].exists)
        #expect(!app[ExampleID.row(.message)].exists)
    }
}
