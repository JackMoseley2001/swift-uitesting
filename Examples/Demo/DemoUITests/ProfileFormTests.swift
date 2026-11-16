import UITesting
import XCTest

@UITestSuite
final class ProfileFormTests: XCTestCase {
    @UITest
    func readsTheTextInAField(app: XCUIApplication) {
        #expect(app[ProfileID.nameField].text == "Ada Lovelace")
        #expect(app[ProfileID.passwordField].text == "")
        #expect(app[ProfileID.notesField].text == "First line\nSecond line")
    }

    @UITest
    func enteringAddsToTheEndOfTheText(app: XCUIApplication) throws {
        try app[ProfileID.nameField].enter(" King")

        #expect(app[ProfileID.nameField].text == "Ada Lovelace King")
    }

    @UITest
    func replacingSwapsTheWholeText(app: XCUIApplication) throws {
        try app[ProfileID.nameField].replaceText(with: "Grace Hopper")

        #expect(app[ProfileID.nameField].text == "Grace Hopper")
    }

    @UITest
    func replacesTextThatIsWiderThanTheField(app: XCUIApplication) throws {
        let longName = "Augusta Ada King, Countess of Lovelace, of Ockham Park in Surrey, England"
        try app[ProfileID.nameField].replaceText(with: longName)
        #expect(app[ProfileID.nameField].text == longName)

        try app[ProfileID.nameField].replaceText(with: "Ada")
        #expect(app[ProfileID.nameField].text == "Ada")
    }

    @UITest
    func clearingEmptiesTheField(app: XCUIApplication) throws {
        try app[ProfileID.nameField].clear()

        #expect(app[ProfileID.nameField].text == "")
    }

    @UITest
    func typesIntoASecureField(app: XCUIApplication) throws {
        try app[ProfileID.passwordField].enter("hunter2")
        #expect(app[ProfileID.summary].label.contains("|hunter2|"))

        try app[ProfileID.passwordField].replaceText(with: "swordfish")
        #expect(app[ProfileID.summary].label.contains("|swordfish|"))
    }

    @UITest
    func replacesTheTextInAMultiLineEditor(app: XCUIApplication) throws {
        try app[ProfileID.notesField].replaceText(with: "Only line")

        #expect(app[ProfileID.notesField].text == "Only line")
    }

    @UITest
    func submittingPressesReturnAndPutsTheKeyboardAway(app: XCUIApplication) throws {
        try app[ProfileID.nameField].enter(" King")
        #expect(app.isKeyboardShowing)

        try app[ProfileID.nameField].submit()

        #expect(!app.isKeyboardShowing, within: .seconds(2))
        #expect(app[ProfileID.nameField].text == "Ada Lovelace King")
    }

    @UITest
    func theKeyboardCanBeDismissedAfterTypingInAnEditor(app: XCUIApplication) throws {
        try app[ProfileID.notesField].enter("\nThird line")
        #expect(app.isKeyboardShowing)

        try app.dismissKeyboard()

        #expect(!app.isKeyboardShowing)
        #expect(app[ProfileID.notesField].text == "First line\nSecond line\nThird line")
    }

    @UITest
    func dismissingTheKeyboardDoesNothingWhenItIsNotShowing(app: XCUIApplication) throws {
        try app.dismissKeyboard()

        #expect(app[ProfileID.nameField].text == "Ada Lovelace")
    }

    @UITest
    func movesFromOneFieldToTheNext(app: XCUIApplication) throws {
        try app[ProfileID.nameField].replaceText(with: "Grace")
        try app[ProfileID.passwordField].enter("cobol")
        try app[ProfileID.notesField].enter("\nThird line")

        #expect(app[ProfileID.summary].label == "Grace|cobol|First line\nSecond line\nThird line")
    }
}
