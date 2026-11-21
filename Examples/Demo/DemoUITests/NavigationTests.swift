import UITesting
import XCTest

@UITestSuite(traits: .animationsDisabled)
final class NavigationTests: XCTestCase {
    @UITest
    func theAppOpensOnTheListOfExamples(app: XCUIApplication) throws {
        #expect(isShowing(title: "Examples", in: app))
        for example in Example.allCases {
            // The list is longer than a small screen, and a row below it does not exist yet.
            try app[ExampleID.row(example)].scrollIntoView()
        }
    }

    @UITest
    func tappingAnExampleOpensItsScreen(app: XCUIApplication) throws {
        try app[ExampleID.row(.fruitList)].tap()

        try app[FruitID.selection].waitToAppear()
        #expect(isShowing(title: Example.fruitList.title, in: app))
    }

    @UITest
    func goingBackReturnsToTheList(app: XCUIApplication) throws {
        try app[ExampleID.row(.message)].tap()
        try app[MessageID.loadButton].waitToAppear()

        // The button to go back is in the navigation bar on iOS and in the toolbar of the window on macOS.
        #if os(macOS)
        app.toolbars.buttons["Back"].click()
        #else
        app.navigationBars.buttons.firstMatch.tap()
        #endif

        try app[ExampleID.row(.message)].waitToAppear()
    }

    @UITest(traits: .example(.message))
    func aTestCanOpenTheAppOnAnExample(app: XCUIApplication) {
        #expect(app[MessageID.loadButton].exists)
        #expect(!app[ExampleID.row(.message)].exists)
    }

    /// Whether the screen that is showing has a title.
    ///
    /// The title is in the navigation bar on iOS and in the title bar of the window on macOS.
    private func isShowing(title: String, in app: XCUIApplication) -> Bool {
        #if os(macOS)
        app.windows.firstMatch.staticTexts[title].exists
        #else
        app.navigationBars[title].exists
        #endif
    }
}
