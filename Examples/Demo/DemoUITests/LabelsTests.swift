import UITesting
import XCTest

/// The labels example has no accessibility identifiers, so every element is found by
/// its kind and its label.
@UITestSuite(traits: .example(.labels), .animationsDisabled)
final class LabelsTests: XCTestCase {
    @UITest
    func findsTextByWhatItSays(app: XCUIApplication) throws {
        try app.staticText("Welcome back").waitToAppear()

        // The label has to match as a whole.
        #expect(!app.staticText("Welcome").exists)
    }

    @UITest
    func typesIntoAFieldAndTapsAButtonOnceItIsEnabled(app: XCUIApplication) throws {
        try app.button("Continue").waitToAppear()
        #expect(!app.button("Continue").isEnabled)

        try app.textField("Email").enter("ada@example.com")
        try app.button("Continue").tap()

        try app.staticText("Signed in as ada@example.com").waitToAppear()
        #expect(!app.staticText("Welcome back").exists)
    }

    @UITest
    func looksInsideAnElementForOneOfTwoButtonsWithTheSameLabel(app: XCUIApplication) throws {
        let home = app.element(ElementKinds.Other.self, labeled: "Home address")
        let work = app.element(ElementKinds.Other.self, labeled: "Work address")

        try work.button("Remove").tap()

        try work.waitToDisappear()
        #expect(home.exists)
        #expect(home.staticText("1 Orchard Lane").exists)
    }

    @UITest
    func aLabelThatOneButtonHasNeedsNoElementToLookIn(app: XCUIApplication) throws {
        try app.element(ElementKinds.Other.self, labeled: "Home address").button("Remove").tap()
        try app.staticText("1 Orchard Lane").waitToDisappear()

        try app.button("Remove").tap()

        try app.staticText("2 Station Road").waitToDisappear()
    }

    @UITest
    func aLabelThatTwoButtonsHaveIsAFailureThatSaysSo(app: XCUIApplication) throws {
        try app.staticText("2 Station Road").waitToAppear()

        // The failure is the point of this test, so it is expected, and has to be the
        // library's own and not the one XCTest gives for a query that matches twice.
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { $0.compactDescription.contains("2 elements match") }
        XCTExpectFailure("Two buttons are labelled Remove, and nothing says which is meant", options: options) {
            try? app.button("Remove").tap()
        }

        #expect(app.staticText("1 Orchard Lane").exists)
        #expect(app.staticText("2 Station Road").exists)
    }
}
