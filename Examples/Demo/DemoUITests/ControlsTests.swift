import UITesting
import XCTest

@UITestSuite(traits: .example(.controls))
final class ControlsTests: XCTestCase {
    @UITest
    func turnsASwitchOnAndOff(app: XCUIApplication) throws {
        let notifications = app[ControlsID.notificationsSwitch]
        #expect(!notifications.isOn)

        try notifications.setOn(true)
        #expect(notifications.isOn)
        #expect(app[ControlsID.summary].label.hasPrefix("on|"))

        try notifications.setOn(false)
        #expect(!notifications.isOn)
    }

    @UITest
    func settingASwitchToTheStateItIsInDoesNothing(app: XCUIApplication) throws {
        try app[ControlsID.notificationsSwitch].setOn(false)

        #expect(app[ControlsID.summary].label.hasPrefix("off|"))
    }

    @UITest
    func togglesASwitch(app: XCUIApplication) throws {
        try app[ControlsID.notificationsSwitch].toggle()
        #expect(app[ControlsID.notificationsSwitch].isOn)

        try app[ControlsID.notificationsSwitch].toggle()
        #expect(!app[ControlsID.notificationsSwitch].isOn)
    }

    @UITest
    func movesASlider(app: XCUIApplication) throws {
        let volume = app[ControlsID.volumeSlider]
        #expect(volume.position == 0.5)

        for target in [0.8, 0.25, 1, 0] {
            try volume.adjust(to: target)
            let position = try #require(volume.position)
            #expect(abs(position - target) <= 0.02)
        }
    }

    @UITest
    func selectsASegment(app: XCUIApplication) throws {
        let size = app[ControlsID.sizePicker]
        #expect(size.selection == "Medium")

        try size.select("Large")

        #expect(size.selection == "Large")
        #expect(app[ControlsID.summary].label.contains("|Large|"))
    }

    @UITest
    func stepsAStepperUpAndDown(app: XCUIApplication) throws {
        let quantity = try app[ControlsID.quantityStepper].scrollIntoView()
        #expect(quantity.value as? String == "2")

        try quantity.increment()
        #expect(quantity.value as? String == "3")
        #expect(quantity.label == "Quantity 3")

        try quantity.increment(times: 2)
        #expect(quantity.value as? String == "5")

        try quantity.decrement(times: 5)
        #expect(quantity.value as? String == "0")
    }

    @UITest
    func picksAValueOnAWheel(app: XCUIApplication) throws {
        let colour = app[ControlsID.colourPicker]
        #expect(colour.selection() == "Green")

        try colour.select("Yellow")

        #expect(app[ControlsID.summary].label.hasSuffix("|Yellow"), within: .seconds(2))
        #expect(colour.selection() == "Yellow", within: .seconds(2))
    }
}
