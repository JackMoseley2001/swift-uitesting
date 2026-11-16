import UITesting
import XCTest

@UITestSuite(traits: .example(.profileForm))
final class ProfileFormTests: XCTestCase {
    /// A helper needs no `@MainActor` of its own. The suite adds it.
    private func summary(in app: XCUIApplication) -> String {
        app[ProfileID.summary].label
    }

    private func nameField(in app: XCUIApplication) -> UITestElement<ElementKinds.TextField> {
        app[ProfileID.nameField]
    }

    @UITest
    func helpersCanReadElements(app: XCUIApplication) {
        #expect(summary(in: app) == "Ada Lovelace||First line\nSecond line")
        #expect(nameField(in: app).text == "Ada Lovelace")
    }

    @UITest
    func readsTheTextInAField(app: XCUIApplication) {
        #expect(app[ProfileID.nameField].text == "Ada Lovelace")
        #expect(app[ProfileID.passwordField].text == "")
        #expect(app[ProfileID.notesField].text == "First line\nSecond line")
    }

    @UITest
    func typesIntoAnEmptyField(app: XCUIApplication) throws {
        try app[ProfileID.nameField].clear()
        try app[ProfileID.nameField].enter("Grace")

        #expect(app[ProfileID.nameField].text == "Grace")
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
    func submittingPressesReturn(app: XCUIApplication) throws {
        try app[ProfileID.nameField].replaceText(with: "Ada King")
        #expect(!app[ProfileID.submittedName].exists)

        try app[ProfileID.nameField].submit()

        try app[ProfileID.submittedName].waitToAppear()
        #expect(app[ProfileID.submittedName].label == "Submitted Ada King")
    }

    @UITest
    func theAppsOwnButtonHidesTheKeyboard(app: XCUIApplication) throws {
        try app[ProfileID.notesField].replaceText(with: "A note")
        #expect(app.keyboards.firstMatch.exists)

        try app[ProfileID.hideKeyboardButton].tap()

        #expect(!app.keyboards.firstMatch.exists, within: .seconds(2))
        #expect(app[ProfileID.notesField].text == "A note")
    }

    @UITest
    func movesFromOneFieldToTheNext(app: XCUIApplication) throws {
        try app[ProfileID.nameField].replaceText(with: "Grace")
        try app[ProfileID.passwordField].enter("cobol")
        try app[ProfileID.notesField].replaceText(with: "A note")

        #expect(app[ProfileID.summary].label == "Grace|cobol|A note")
    }
}
