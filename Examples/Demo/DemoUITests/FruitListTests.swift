import UITesting
import XCTest

@UITestSuite
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
    func tappingARowSelectsItsItem(app: XCUIApplication) {
        app[FruitID.row(Fruit.pear.id)].tap()

        #expect(app[FruitID.selection].label == "Selected Pear")
    }

    @UITest
    func aQueryCanStillBeChosenByHand(app: XCUIApplication) {
        app.buttons[FruitID.row(Fruit.cherry.id)].tap()

        #expect(app.staticTexts[FruitID.selection].label == "Selected Cherry")
    }
}
