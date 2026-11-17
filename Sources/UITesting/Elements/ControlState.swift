/// The parts of working with controls that do not need a running app.
enum ControlState {
    /// Returns whether a switch is on, from the value XCTest reports for it.
    ///
    /// A switch reports "1" when it is on and "0" when it is off.
    static func isOn(value: Any?) -> Bool {
        guard let value else { return false }
        return ["1", "true", "on"].contains("\(value)".lowercased())
    }

    /// Returns the position of a slider between 0 and 1, from the value XCTest reports for it.
    ///
    /// A slider reports its position as a percentage, such as "50%".
    static func sliderPosition(value: Any?) -> Double? {
        guard let value else { return nil }
        let digits = "\(value)".filter { $0.isNumber || $0 == "." || $0 == "-" }
        guard let percentage = Double(digits) else { return nil }
        return percentage / 100
    }

    /// Makes attempts at changing a control until it is in the state that is wanted.
    ///
    /// - Parameters:
    ///   - isDone: Whether the control is in the state that is wanted.
    ///   - attempts: The ways of changing it, in order.
    ///   - wait: Waits for the control to be in the state that is wanted, and returns whether it is.
    /// - Returns: Whether the control ended up in the state that is wanted.
    static func change(isDone: () -> Bool, attempts: [() -> Void], wait: () -> Bool) -> Bool {
        if isDone() { return true }
        for attempt in attempts {
            attempt()
            if wait() { return true }
        }
        return false
    }

    /// Steps a stepper a number of times, checking that its value changes each time.
    ///
    /// A stepper that reports no value cannot be checked, so each step is taken on trust.
    ///
    /// - Parameters:
    ///   - times: How many steps to take.
    ///   - value: Reads the value the stepper reports, which is empty if it reports none.
    ///   - tap: Takes one step.
    ///   - waitForChange: Waits for the value to differ from the one given, and returns whether it does.
    /// - Returns: `nil` if every step was taken. Otherwise the value the stepper stayed at.
    static func step(
        times: Int,
        value: () -> String,
        tap: () -> Void,
        waitForChange: (_ from: String) -> Bool
    ) -> String? {
        for _ in 0..<max(times, 0) {
            let before = value()
            tap()
            if !before.isEmpty, !waitForChange(before) {
                return before
            }
        }
        return nil
    }

    /// Moves a slider to a position by dragging its thumb, checking where it lands.
    ///
    /// Each round reads where the slider is and drags the thumb by the distance that
    /// is left, so an error in one drag is made up by the next. If a drag leaves the
    /// slider where it was, it did not take hold of the thumb, and the slider is
    /// nudged another way before the next round.
    ///
    /// - Parameters:
    ///   - target: The position wanted, between 0 and 1.
    ///   - tolerance: How far from the target counts as there.
    ///   - maximumMoves: The most drags to make.
    ///   - position: Reads the position of the slider.
    ///   - drag: Drags the thumb from one position to another.
    ///   - nudge: Moves the slider towards a position in a way that does not need the thumb.
    /// - Returns: `nil` if the slider ended within the tolerance. Otherwise where it
    ///   ended, which is itself `nil` if the slider does not report a position.
    static func adjustSlider(
        to target: Double,
        tolerance: Double,
        maximumMoves: Int = 5,
        position: () -> Double?,
        drag: (_ from: Double, _ to: Double) -> Void,
        nudge: (Double) -> Void
    ) -> Double?? {
        for _ in 0..<maximumMoves {
            guard let now = position() else { return .some(nil) }
            if abs(now - target) <= tolerance { return nil }

            drag(now, target)
            if position() == now { nudge(target) }
        }
        guard let end = position() else { return .some(nil) }
        return abs(end - target) <= tolerance ? nil : .some(end)
    }
}
