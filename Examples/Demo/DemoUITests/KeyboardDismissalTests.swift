import UITesting
import XCTest

/// Checks `dismissKeyboard()` against each way a scroll view can be set up to dismiss
/// the keyboard.
@UITestSuite(traits: .example(.profileForm))
final class KeyboardDismissalTests: XCTestCase {
    private func typeANote(in app: XCUIApplication) throws {
        try app[ProfileID.notesField].replaceText(with: "A note")
        #expect(app.isKeyboardShowing)
    }

    @UITest(traits: .keyboardDismissal(.immediately))
    func dismissesTheKeyboardWhereADragDismissesItImmediately(app: XCUIApplication) throws {
        try typeANote(in: app)

        try app.dismissKeyboard()

        #expect(!app.isKeyboardShowing)
        #expect(app[ProfileID.notesField].text == "A note")
    }

    @UITest(traits: .keyboardDismissal(.interactively))
    func dismissesTheKeyboardWhereADragDismissesItInteractively(app: XCUIApplication) throws {
        try typeANote(in: app)

        try app.dismissKeyboard()

        #expect(!app.isKeyboardShowing)
        #expect(app[ProfileID.notesField].text == "A note")
    }

    @UITest(traits: .keyboardDismissal(.never))
    func failsWhereADragNeverDismissesTheKeyboard(app: XCUIApplication) throws {
        try typeANote(in: app)

        XCTExpectFailure("The app does not let a drag dismiss the keyboard") {
            try? app.dismissKeyboard(within: .seconds(1))
        }

        #expect(app.isKeyboardShowing)
    }

    @UITest(traits: .keyboardDismissal(.automatic))
    func failsWhereTheScrollViewDoesNotSetAMode(app: XCUIApplication) throws {
        try typeANote(in: app)

        XCTExpectFailure("A scroll view that sets no mode does not dismiss the keyboard") {
            try? app.dismissKeyboard(within: .seconds(1))
        }

        #expect(app.isKeyboardShowing)
    }
}
