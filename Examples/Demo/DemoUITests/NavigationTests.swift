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
        #expect(app.navigationTitle == Example.fruitList.title)
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
