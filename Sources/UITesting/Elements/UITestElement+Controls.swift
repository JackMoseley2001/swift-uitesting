import XCTest

extension UITestElement where Kind: SwitchKind {
    /// Whether the switch is on, read without waiting.
    ///
    /// `XCUIElement` reports this as the string "1" or "0".
    public var isOn: Bool {
        ControlState.isOn(value: element.value)
    }

    // tvOS has no touch screen, so XCTest has no taps, drags or swipes there.
    #if !os(tvOS)
    /// Turns the switch on or off, once it exists and is enabled.
    ///
    /// Does nothing if the switch is already in that state. Otherwise it taps the
    /// switch and checks that the state changed. A tap in the middle of a labelled
    /// switch can miss the switch itself, so if nothing changed it taps the switch
    /// inside the element.
    ///
    /// ```swift
    /// try app[SettingsID.notificationsSwitch].setOn(true)
    /// ```
    ///
    /// - Parameters:
    ///   - isOn: Whether the switch should be on.
    ///   - timeout: How long to wait for the switch, and for its state to change. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the switch is not ready in time, or is
    ///   not in the state asked for afterwards. The failure is recorded at the line of
    ///   the call, and the test ends.
    public func setOn(
        _ isOn: Bool,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let name = isOn ? "on" : "off"
        try wait(toBe: .enabled, inOrderTo: "turn \(name)", within: timeout, filePath: filePath, line: line)

        let polling = ExpectationPolling()
        let settling = min(timeout ?? ActionTimeout.current, .seconds(2))
        let changed = ControlState.change(
            isDone: { self.isOn == isOn },
            attempts: [
                { element.tap() },
                {
                    let inner = element.switches.firstMatch
                    if inner.exists {
                        inner.tap()
                    } else {
                        element.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
                    }
                },
            ],
            wait: { polling.wait(timeout: settling, until: { self.isOn == isOn }) == .met }
        )
        guard changed else {
            try fail(
                "Could not turn \(name) \(reference.name): "
                    + "the switch was still \(isOn ? "off" : "on") after tapping it",
                filePath: filePath,
                line: line
            )
        }
    }

    /// Changes the switch to its other state, once it exists and is enabled.
    ///
    /// - Parameter timeout: How long to wait for the switch, and for its state to change.
    ///   The default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the switch is not ready in time, or did
    ///   not change. The failure is recorded at the line of the call, and the test ends.
    public func toggle(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .enabled, inOrderTo: "toggle", within: timeout, filePath: filePath, line: line)
        try setOn(!isOn, within: timeout, filePath: filePath, line: line)
    }
    #endif
}

extension UITestElement where Kind == ElementKinds.Slider {
    /// The position of the slider between 0 and 1, read without waiting, or `nil` if
    /// the slider does not report one.
    ///
    /// `XCUIElement` reports this as a percentage in a string, such as "50%".
    public var position: Double? {
        ControlState.sliderPosition(value: element.value)
    }

    #if !os(tvOS)
    /// Moves the slider to a position, once it exists and is enabled.
    ///
    /// XCTest's own `adjust(toNormalizedSliderPosition:)` can land several percent
    /// from where it is asked to. This drags the thumb by the distance to go, reads
    /// where the slider ended up, and drags again until it is within the tolerance.
    ///
    /// ```swift
    /// try app[PlayerID.volumeSlider].adjust(to: 0.8)
    /// ```
    ///
    /// - Parameters:
    ///   - position: The position wanted, from 0 at the start of the slider to 1 at its end.
    ///   - tolerance: How far from `position` the slider may end up. The default is 0.02.
    ///   - timeout: How long to wait for the slider. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the slider is not ready in time, or does
    ///   not end up within the tolerance. The failure is recorded at the line of the
    ///   call, and the test ends.
    public func adjust(
        to position: Double,
        tolerance: Double = 0.02,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .enabled, inOrderTo: "adjust", within: timeout, filePath: filePath, line: line)

        let miss = ControlState.adjustSlider(
            to: position,
            tolerance: tolerance,
            position: { self.position },
            drag: { from, to in dragThumb(from: from, to: to) },
            nudge: { element.adjust(toNormalizedSliderPosition: $0) }
        )
        guard let miss else { return }

        let wanted = "\(Int((position * 100).rounded()))%"
        let reason =
            if let miss {
                "it was at \(Int((miss * 100).rounded()))% after the last move"
            } else {
                "the slider does not report its position"
            }
        try fail("Could not move \(reference.name) to \(wanted): \(reason)", filePath: filePath, line: line)
    }
    #endif
}

#if !os(tvOS)
extension UITestElement where Kind == ElementKinds.Slider {
    /// Drags the slider's thumb by the distance between two positions.
    ///
    /// The thumb is as wide as a finger, so its middle never reaches the ends of the
    /// slider. The drag takes hold a little way in from an end, and moves by the
    /// distance wanted, which is what moves the value. A drag to either end goes past
    /// it, to be sure of reaching it.
    private func dragThumb(from: Double, to: Double) {
        let hold = min(max(from, 0.06), 0.94)
        let past = to <= 0 ? -0.1 : (to >= 1 ? 0.1 : 0)
        let release = hold + (to - from) + past
        element.coordinate(withNormalizedOffset: CGVector(dx: hold, dy: 0.5)).press(
            forDuration: 0.1,
            thenDragTo: element.coordinate(withNormalizedOffset: CGVector(dx: release, dy: 0.5)),
            withVelocity: .slow,
            thenHoldForDuration: 0.2
        )
    }
}

extension UITestElement where Kind == ElementKinds.Stepper {
    /// Steps the stepper up, once it exists and is enabled.
    ///
    /// ```swift
    /// try app[BasketID.quantityStepper].increment()
    /// try app[BasketID.quantityStepper].increment(times: 3)
    /// ```
    ///
    /// If the stepper reports a value, each step is checked: a step that leaves the
    /// value as it was, such as one past the end of the stepper's range, fails. Read
    /// the value with `value`, as for any element.
    ///
    /// Pass `requiringChange: false` when a step is allowed to change nothing, such as
    /// in a test that the stepper stops at the end of its range:
    ///
    /// ```swift
    /// try app[BasketID.quantityStepper].increment(times: 10, requiringChange: false)
    /// #expect(app[BasketID.quantityStepper].value as? String == "5")
    /// ```
    ///
    /// - Parameters:
    ///   - times: How many steps to take. The default is 1.
    ///   - requiringChange: Whether a step that leaves the value as it was fails. The
    ///     default is `true`.
    ///   - timeout: How long to wait for the stepper, and for its value to change. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the stepper is not ready in time, or its
    ///   value does not change. The failure is recorded at the line of the call, and
    ///   the test ends.
    public func increment(
        times: Int = 1,
        requiringChange: Bool = true,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try step(
            .increment,
            times: times,
            requiringChange: requiringChange,
            within: timeout,
            filePath: filePath,
            line: line
        )
    }

    /// Steps the stepper down, once it exists and is enabled.
    ///
    /// ```swift
    /// try app[BasketID.quantityStepper].decrement()
    /// ```
    ///
    /// If the stepper reports a value, each step is checked: a step that leaves the
    /// value as it was, such as one past the end of the stepper's range, fails. Pass
    /// `requiringChange: false` when a step is allowed to change nothing.
    ///
    /// - Parameters:
    ///   - times: How many steps to take. The default is 1.
    ///   - requiringChange: Whether a step that leaves the value as it was fails. The
    ///     default is `true`.
    ///   - timeout: How long to wait for the stepper, and for its value to change. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the stepper is not ready in time, or its
    ///   value does not change. The failure is recorded at the line of the call, and
    ///   the test ends.
    public func decrement(
        times: Int = 1,
        requiringChange: Bool = true,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try step(
            .decrement,
            times: times,
            requiringChange: requiringChange,
            within: timeout,
            filePath: filePath,
            line: line
        )
    }

    private enum Step: String {
        case increment
        case decrement
    }

    private func step(
        _ step: Step,
        times: Int,
        requiringChange: Bool,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws {
        try wait(toBe: .enabled, inOrderTo: step.rawValue, within: timeout, filePath: filePath, line: line)

        let polling = ExpectationPolling()
        let settling = min(timeout ?? ActionTimeout.current, .seconds(2))
        let reported = { "\(element.value ?? "")" }
        let stuckAt = ControlState.step(
            times: times,
            requiringChange: requiringChange,
            value: reported,
            tap: { tapButton(for: step) },
            waitForChange: { before in polling.wait(timeout: settling, until: { reported() != before }) == .met }
        )
        if let stuckAt {
            try fail(
                "Could not \(step.rawValue) \(reference.name): "
                    + "its value was still \(stuckAt) after tapping it",
                filePath: filePath,
                line: line
            )
        }
    }

    /// Taps the half of the stepper that steps up or down.
    ///
    /// SwiftUI gives the two halves identifiers made from the stepper's own. Without
    /// those, the halves are the stepper's two buttons in order. The buttons can take
    /// a moment to appear after the stepper does, so this waits for them briefly. A
    /// stepper that never has buttons is tapped a quarter of the way in from the end
    /// of the control inside it.
    private func tapButton(for step: Step) {
        let named = element.buttons["\(accessibilityIdentifier)-\(step == .increment ? "Increment" : "Decrement")"]
        let buttons = element.buttons
        _ = ExpectationPolling().wait(timeout: .seconds(1), until: { named.exists || buttons.count == 2 })
        if named.exists {
            named.tap()
            return
        }
        if buttons.count == 2 {
            buttons.element(boundBy: step == .increment ? 1 : 0).tap()
            return
        }

        // The offset is worked out from frames read now, and applied to the stepper,
        // so that the tap does not depend on the inner element still being there.
        let whole = element.frame
        let inner = element.children(matching: .other).firstMatch
        let control = inner.exists ? inner.frame : whole
        let x = control.minX + control.width * (step == .increment ? 0.75 : 0.25) - whole.minX
        let y = control.midY - whole.minY
        element.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }
}
#endif

// Picker wheels are only on iOS, and so is the XCTest call that turns one.
#if os(iOS)
extension UITestElement where Kind: PickerWheelKind {
    /// The value showing on the picker's wheel, read without waiting.
    ///
    /// - Parameter index: The position of the wheel, for a picker with several. The
    ///   default is the first.
    public func selection(inWheel index: Int = 0) -> String? {
        wheelElement(at: index).value as? String
    }

    /// Turns the picker's wheel to a value, once the picker exists and is enabled.
    ///
    /// ```swift
    /// try app[ProfileID.countryPicker].select("France")
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to pick, as the wheel shows it.
    ///   - index: The position of the wheel, for a picker with several, such as a date
    ///     picker. The default is the first.
    ///   - timeout: How long to wait for the picker. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the picker is not ready in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func select(
        _ value: String,
        inWheel index: Int = 0,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .enabled, inOrderTo: "pick \"\(value)\" in", within: timeout, filePath: filePath, line: line)
        wheelElement(at: index).adjust(toPickerWheelValue: value)
    }

    /// The wheel at a position: the element itself if it is a wheel, or a wheel inside it.
    private func wheelElement(at index: Int) -> XCUIElement {
        if Kind.elementType == .pickerWheel { return element }
        return element.pickerWheels.element(boundBy: index)
    }
}
#endif

extension UITestElement where Kind == ElementKinds.MenuPicker {
    /// The option that the control shows as selected, read without waiting, or `nil`
    /// if it shows none, as a menu of actions does not.
    public var selection: String? {
        let text = element.staticTexts.firstMatch
        if text.exists {
            return text.label
        }
        guard let value = element.value as? String, !value.isEmpty else { return nil }
        return value
    }

    #if !os(tvOS)
    /// Opens the menu and selects the option with a label, once the control exists
    /// and is enabled.
    ///
    /// ```swift
    /// try app[SettingsID.themePicker].select("Dark")
    /// ```
    ///
    /// The options are not inside the control: the menu is shown over the app. So the
    /// option is the element with this label, in the app the control was looked up
    /// in, that can be tapped once the menu is open.
    ///
    /// - Parameters:
    ///   - label: The label of the option to select.
    ///   - timeout: How long to wait for the control, and for the option to show. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the control is not ready in time, or no
    ///   option with this label shows. The failure is recorded at the line of the call,
    ///   and the test ends, with the menu still open.
    public func select(
        _ label: String,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let intent = "select \"\(label)\" in"
        let app = try owningApp(inOrderTo: intent, filePath: filePath, line: line)
        try wait(toBe: .enabled, inOrderTo: intent, within: timeout, filePath: filePath, line: line)
        let own = element.frame
        element.tap()

        let hasLabel = NSPredicate(format: "label == %@", label)
        let queries = [app.menuItems.matching(hasLabel), app.buttons.matching(hasLabel)]
        // The menu is in front of the app, so its option is the last element with the
        // label. The control itself can have the same label, and is not an option.
        func option() -> XCUIElement? {
            queries.lazy
                .flatMap { $0.allElementsBoundByIndex.reversed() }
                .first { $0.frame != own && $0.isHittable }
        }

        let polling = ExpectationPolling()
        let timeout = timeout ?? ActionTimeout.current
        var found: XCUIElement?
        _ = polling.wait(timeout: timeout) {
            found = option()
            return found != nil
        }
        guard let found else {
            try fail(
                "Could not select \"\(label)\" in \(reference.name): "
                    + "no option with this label showed within \(ExpectationFailure.describe(timeout))",
                filePath: filePath,
                line: line
            )
        }
        found.tap()
        // The menu takes a moment to close, and the control is covered until it has.
        _ = polling.wait(timeout: .seconds(2), until: { element.isHittable })
    }
    #endif
}

extension UITestElement where Kind == ElementKinds.SegmentedControl {
    /// The label of the segment that is selected, read without waiting.
    public var selection: String? {
        element.buttons.allElementsBoundByIndex.first { $0.isSelected }?.label
    }

    #if !os(tvOS)
    /// Selects the segment with a label, once the control exists and is enabled.
    ///
    /// ```swift
    /// try app[SettingsID.sizePicker].select("Large")
    /// ```
    ///
    /// - Parameters:
    ///   - label: The label of the segment to select.
    ///   - timeout: How long to wait for the control. The default is the test's
    ///     ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the control is not ready in time, or has
    ///   no segment with that label. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func select(
        _ label: String,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .enabled, inOrderTo: "select \"\(label)\" in", within: timeout, filePath: filePath, line: line)

        let segment = element.buttons[label]
        guard segment.exists else {
            let labels = element.buttons.allElementsBoundByIndex.map(\.label).joined(separator: ", ")
            try fail(
                "Could not select \"\(label)\" in \(reference.name): "
                    + "no segment has this label. Its segments are: \(labels)",
                filePath: filePath,
                line: line
            )
        }
        segment.tap()
    }
    #endif
}

extension UITestElement {
    /// Records a failure at the line of the call and ends the test.
    func fail(_ message: String, filePath: StaticString, line: UInt) throws -> Never {
        ExpectationReporter.report(message: message, filePath: filePath, line: line)
        throw RequirementFailedError(message: message)
    }
}
