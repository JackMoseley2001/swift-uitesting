import XCTest

extension UITestElement where Kind: SwitchKind {
    /// Whether the switch is on, read without waiting.
    ///
    /// `XCUIElement` reports this as the string "1" or "0".
    public var isOn: Bool {
        ControlState.isOn(value: element.value)
    }

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
                { element.tapOrClick() },
                {
                    let inner = element.switches.firstMatch
                    if inner.exists {
                        inner.tapOrClick()
                        return
                    }
                    // tvOS has no touch screen, so there is no point of the switch to tap.
                    #if !os(tvOS)
                    element.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tapOrClick()
                    #endif
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
}

extension UITestElement where Kind == ElementKinds.Slider {
    /// The position of the slider between 0 and 1, read without waiting, or `nil` if
    /// the slider does not report one.
    ///
    /// `XCUIElement` reports this as a percentage in a string, such as "50%".
    public var position: Double? {
        #if os(macOS)
        // On macOS the value is a number in the slider's own range, and not a percentage.
        element.exists ? Double(element.normalizedSliderPosition) : nil
        #else
        ControlState.sliderPosition(value: element.value)
        #endif
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
    /// A slider on watchOS moves by a step at a time, with a tap on either end of it.
    /// There, this taps until the slider is within the tolerance, and fails if the
    /// position wanted is between two steps.
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

        #if os(watchOS)
        // A slider on watchOS has no thumb to drag. A tap on either end of it moves it by one step.
        let miss = ControlState.stepSlider(
            to: position,
            tolerance: tolerance,
            position: { self.position },
            step: { up in element.coordinate(withNormalizedOffset: CGVector(dx: up ? 0.9 : 0.1, dy: 0.5)).tap() }
        )
        #else
        let miss = ControlState.adjustSlider(
            to: position,
            tolerance: tolerance,
            position: { self.position },
            drag: { from, to in dragThumb(from: from, to: to) },
            nudge: { nudge(to: $0) }
        )
        #endif
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

#if !os(tvOS) && !os(watchOS)
extension UITestElement where Kind == ElementKinds.Slider {
    /// Drags the slider's thumb by the distance between two positions.
    ///
    /// The thumb is as wide as a finger, so its middle never reaches the ends of the
    /// slider. The drag takes hold a little way in from an end, and moves by the
    /// distance wanted, which is what moves the value. A drag to either end goes past
    /// it, to be sure of reaching it.
    ///
    /// Where the slider reports its thumb as an element inside it, as on visionOS, the
    /// drag takes hold of that.
    private func dragThumb(from: Double, to: Double) {
        let past = to <= 0 ? -0.1 : (to >= 1 ? 0.1 : 0)
        let thumb = element.otherElements[ControlState.sliderThumbIdentifier].firstMatch
        if thumb.exists {
            // The drag starts from the thumb itself. On visionOS one that starts from
            // the same point of the slider does not always take hold of it.
            let middle = thumb.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let distance = (to - from + past) * element.frame.width
            middle.drag(
                afterPressingFor: 0.1,
                to: middle.withOffset(CGVector(dx: distance, dy: 0)),
                velocity: .slow,
                thenHoldingFor: 0.2
            )
            return
        }
        let hold = min(max(from, 0.06), 0.94)
        let release = hold + (to - from) + past
        element.coordinate(withNormalizedOffset: CGVector(dx: hold, dy: 0.5)).drag(
            afterPressingFor: 0.1,
            to: element.coordinate(withNormalizedOffset: CGVector(dx: release, dy: 0.5)),
            velocity: .slow,
            thenHoldingFor: 0.2
        )
    }

    /// Moves the slider towards a position without its thumb, with XCTest's own action.
    private func nudge(to position: Double) {
        // On visionOS that action cannot read the slider, and ends the test.
        #if !os(visionOS)
        element.adjust(toNormalizedSliderPosition: position)
        #endif
    }
}
#endif

#if !os(tvOS)
extension UITestElement where Kind == ElementKinds.Stepper {
    /// The value of the stepper as text, read without waiting, or `nil` if the stepper
    /// reports none.
    ///
    /// `XCUIElement` reports this as a string on iOS and as a number on macOS. This is
    /// the same text on both.
    ///
    /// ```swift
    /// #expect(app[BasketID.quantityStepper].value == "3")
    /// ```
    public var value: String? {
        ControlState.stepperValue(value: element.value)
    }

    /// Steps the stepper up, once it exists and is enabled.
    ///
    /// ```swift
    /// try app[BasketID.quantityStepper].increment()
    /// try app[BasketID.quantityStepper].increment(times: 3)
    /// ```
    ///
    /// If the stepper reports a value, each step is checked: a step that leaves the
    /// value as it was, such as one past the end of the stepper's range, fails. Read
    /// the value with ``value``.
    ///
    /// Pass `requiringChange: false` when a step is allowed to change nothing, such as
    /// in a test that the stepper stops at the end of its range:
    ///
    /// ```swift
    /// try app[BasketID.quantityStepper].increment(times: 10, requiringChange: false)
    /// #expect(app[BasketID.quantityStepper].value == "5")
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
        let reported = { value ?? "" }
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
        #if os(macOS)
        // On macOS the halves are arrows, and not buttons.
        let arrows = step == .increment ? element.incrementArrows : element.decrementArrows
        if arrows.firstMatch.exists {
            arrows.firstMatch.click()
            return
        }
        #endif
        let named = element.buttons["\(accessibilityIdentifier)-\(step == .increment ? "Increment" : "Decrement")"]
        let buttons = element.buttons
        _ = ExpectationPolling().wait(timeout: .seconds(1), until: { named.exists || buttons.count == 2 })
        if named.exists {
            named.tapOrClick()
            return
        }
        if buttons.count == 2 {
            buttons.element(boundBy: step == .increment ? 1 : 0).tapOrClick()
            return
        }

        // The offset is worked out from frames read now, and applied to the stepper,
        // so that the tap does not depend on the inner element still being there.
        let whole = element.frame
        let inner = element.children(matching: .other).firstMatch
        let control = inner.exists ? inner.frame : whole
        let x = control.minX + control.width * (step == .increment ? 0.75 : 0.25) - whole.minX
        let y = control.midY - whole.minY
        element.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tapOrClick()
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
            return text.labelOrText
        }
        guard let value = element.value as? String, !value.isEmpty else { return nil }
        return value
    }

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
        element.tapOrClick()

        // On macOS an item of a menu has a title, and no label.
        #if os(macOS)
        let hasLabel = NSPredicate(format: "label == %@ OR title == %@", label, label)
        #else
        let hasLabel = NSPredicate(format: "label == %@", label)
        #endif
        #if os(tvOS)
        // On tvOS the options are the cells of a list, and it is what is inside a cell that has the label.
        let queries = [app.cells.otherElements.matching(hasLabel), app.buttons.matching(hasLabel)]
        #else
        let queries = [app.menuItems.matching(hasLabel), app.buttons.matching(hasLabel)]
        #endif
        // The menu is in front of the app, so its option is the last element with the
        // label. The control itself can have the same label, and is not an option.
        func option() -> XCUIElement? {
            queries.lazy
                .flatMap { $0.allElementsBoundByIndex.reversed() }
                .first { $0.frame != own && $0.isReachable }
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
        found.tapOrClick()
        // The menu takes a moment to close, and the control is covered until it has.
        #if os(tvOS)
        _ = polling.wait(timeout: .seconds(2), until: { !found.exists })
        #else
        _ = polling.wait(timeout: .seconds(2), until: { element.isHittable })
        #endif
    }
}

extension UITestElement where Kind: SegmentedKind {
    /// The label of the segment that is selected, read without waiting.
    public var selection: String? {
        if Kind.elementType == .radioGroup {
            // A radio button reports whether it is selected as its value.
            segments.allElementsBoundByIndex.first { ControlState.isOn(value: $0.value) }?.label
        } else {
            segments.allElementsBoundByIndex.first { $0.isSelected }?.label
        }
    }

    /// The segments of the control, which are radio buttons in a group of them.
    private var segments: XCUIElementQuery {
        Kind.elementType == .radioGroup ? element.radioButtons : element.buttons
    }

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

        let segment = segments[label]
        guard segment.exists else {
            let labels = segments.allElementsBoundByIndex.map(\.label).joined(separator: ", ")
            try fail(
                "Could not select \"\(label)\" in \(reference.name): "
                    + "no segment has this label. Its segments are: \(labels)",
                filePath: filePath,
                line: line
            )
        }
        segment.tapOrClick()
    }
}

extension UITestElement {
    /// Records a failure at the line of the call and ends the test.
    func fail(_ message: String, filePath: StaticString, line: UInt) throws -> Never {
        ExpectationReporter.report(message: message, filePath: filePath, line: line)
        throw RequirementFailedError(message: message)
    }
}
