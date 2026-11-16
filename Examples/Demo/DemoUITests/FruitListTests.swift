import UITesting
import XCTest

@UITestSuite(traits: .example(.fruitList))
final class FruitListTests: XCTestCase {
    @UITest
    func nothingIsSelectedAtFirst(app: XCUIApplication) {
        #expect(app[FruitID.selection].label == "Nothing selected")
    }

    @UITest
    func eachRowIsFoundByTheItemItShows(app: XCUIApplication) {
        #expect(app[FruitID.row(Fruit.apple.id)].label == "Apple")
        #expect(app[FruitID.row(Fruit.cherry.id)].label == "Cherry")
        #expect(!app[FruitID.row(999)].exists)
    }

    @UITest
    func tappingARowSelectsItsItem(app: XCUIApplication) throws {
        try app[FruitID.row(Fruit.pear.id)].tap()

        #expect(app[FruitID.selection].label == "Selected Pear")
    }

    @UITest
    func aQueryCanStillBeChosenByHand(app: XCUIApplication) throws {
        try app.buttons[FruitID.row(Fruit.cherry.id)].tap()

        #expect(app.staticTexts[FruitID.selection].label == "Selected Cherry")
    }

    @UITest
    func tappingWaitsForTheButtonToBeEnabled(app: XCUIApplication) throws {
        #expect(!app[FruitID.clearButton].isEnabled)

        try app[FruitID.row(Fruit.apple.id)].tap()
        // The button is enabled a second after the selection. The tap waits for it.
        try app[FruitID.clearButton].tap()

        #expect(app[FruitID.selection].label == "Nothing selected")
    }

    @UITest(traits: .actionTimeout(.seconds(10)))
    func aTestCanChooseHowLongActionsWait(app: XCUIApplication) throws {
        try app[FruitID.row(Fruit.pear.id)].tap()
        try app[FruitID.clearButton].tap()

        #expect(app[FruitID.selection].label == "Nothing selected")
    }
}
