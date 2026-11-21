import UITesting
import XCTest

@UITestSuite(traits: .example(.controls), .animationsDisabled)
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

        // A slider on watchOS moves by a sixth at a time.
        #if os(watchOS)
        let targets = [0.83, 0.33, 1, 0]
        #else
        let targets = [0.8, 0.25, 1, 0]
        #endif
        for target in targets {
            try volume.adjust(to: target)
            let position = try #require(volume.position)
            #expect(abs(position - target) <= 0.02)
        }
    }

    // watchOS has no picker with segments.
    #if !os(watchOS)
    @UITest
    func selectsASegment(app: XCUIApplication) throws {
        let size = app[ControlsID.sizePicker]
        #expect(size.selection == "Medium")

        try size.select("Large")

        #expect(size.selection == "Large")
        #expect(app[ControlsID.summary].label.contains("|Large|"))
    }
    #endif

    @UITest
    func stepsAStepperUpAndDown(app: XCUIApplication) throws {
        let quantity = try app[ControlsID.quantityStepper].scrollIntoView()
        #expect(quantity.value == "2")

        try quantity.increment()
        #expect(quantity.value == "3")
        // On macOS and visionOS the label of a stepper is not reported as part of the stepper.
        #if !os(macOS) && !os(visionOS)
        #expect(quantity.label == "Quantity 3")
        #endif

        try quantity.increment(times: 2)
        #expect(quantity.value == "5")

        try quantity.decrement(times: 5)
        #expect(quantity.value == "0")
    }

    // watchOS has no picker with a menu.
    #if !os(watchOS)
    @UITest
    func selectsAnOptionInAMenu(app: XCUIApplication) throws {
        let shape = try app[ControlsID.shapeMenu].scrollIntoView()
        #expect(shape.selection == "Circle")

        try shape.select("Triangle")
        #expect(shape.selection == "Triangle")

        try shape.select("Square")
        #expect(shape.selection == "Square")
    }
    #endif

    @UITest
    func aStepperCanBeSteppedPastTheEndOfItsRange(app: XCUIApplication) throws {
        let quantity = try app[ControlsID.quantityStepper].scrollIntoView()

        try quantity.increment(times: 5, requiringChange: false)
        #expect(quantity.value == "5")

        try quantity.decrement(times: 7, requiringChange: false)
        #expect(quantity.value == "0")
    }

    // Only iOS has pickers with a wheel.
    #if os(iOS)
    @UITest
    func picksAValueOnAWheel(app: XCUIApplication) throws {
        let colour = app[ControlsID.colourPicker]
        #expect(colour.selection() == "Green")

        try colour.select("Yellow")

        #expect(app[ControlsID.summary].label.hasSuffix("|Yellow"), within: .seconds(2))
        #expect(colour.selection() == "Yellow", within: .seconds(2))
    }
    #endif
}
