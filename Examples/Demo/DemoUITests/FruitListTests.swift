import UITesting
import XCTest

@UITestSuite(traits: .example(.fruitList), .animationsDisabled)
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
    func theRowsCanBeCounted(app: XCUIApplication) {
        #expect(app[all: FruitID.row].count == Fruit.all.count)
        #expect(!app[all: FruitID.row].isEmpty)
    }

    @UITest
    func theRowsAreInTheOrderTheyAreShownIn(app: XCUIApplication) {
        #expect(app[all: FruitID.row].map(\.label) == ["Apple", "Pear", "Cherry"])
    }

    @UITest
    func aRowIsFoundByItsPosition(app: XCUIApplication) throws {
        try app[all: FruitID.row][1].tap()

        #expect(app[FruitID.selection].label == "Selected Pear")
    }

    @UITest
    func everyRowCanBeUsedInTurn(app: XCUIApplication) throws {
        for (row, fruit) in zip(app[all: FruitID.row].elements, Fruit.all) {
            try row.tap()

            #expect(app[FruitID.selection].label == "Selected \(fruit.name)")
        }
    }

    @UITest
    func tappingARowSelectsItsItem(app: XCUIApplication) throws {
        try app[FruitID.row(Fruit.pear.id)].tap()

        #expect(app[FruitID.selection].label == "Selected Pear")
    }

    @UITest(arguments: Fruit.all)
    func everyRowSelectsItsItem(_ fruit: Fruit, app: XCUIApplication) throws {
        // Each fruit gets a launch of its own, so nothing is selected when it starts.
        #expect(app[FruitID.selection].label == "Nothing selected")

        try app[FruitID.row(fruit.id)].tap()

        #expect(app[FruitID.selection].label == "Selected \(fruit.name)")
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
