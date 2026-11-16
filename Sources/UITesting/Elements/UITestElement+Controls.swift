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
                "Could not turn \(name) \(accessibilityIdentifier): "
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
        ControlState.sliderPosition(value: element.value)
    }

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
        try fail("Could not move \(accessibilityIdentifier) to \(wanted): \(reason)", filePath: filePath, line: line)
    }
}

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

extension UITestElement where Kind == ElementKinds.SegmentedControl {
    /// The label of the segment that is selected, read without waiting.
    public var selection: String? {
        element.buttons.allElementsBoundByIndex.first { $0.isSelected }?.label
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

        let segment = element.buttons[label]
        guard segment.exists else {
            let labels = element.buttons.allElementsBoundByIndex.map(\.label).joined(separator: ", ")
            try fail(
                "Could not select \"\(label)\" in \(accessibilityIdentifier): "
                    + "no segment has this label. Its segments are: \(labels)",
                filePath: filePath,
                line: line
            )
        }
        segment.tap()
    }
}

extension UITestElement {
    /// Records a failure at the line of the call and ends the test.
    func fail(_ message: String, filePath: StaticString, line: UInt) throws -> Never {
        ExpectationReporter.report(message: message, filePath: filePath, line: line)
        throw RequirementFailedError(message: message)
    }
}
