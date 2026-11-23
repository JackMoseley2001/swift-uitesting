import CoreGraphics

/// The part of moving the focus that does not need a running app.
///
/// tvOS has no touch screen. One element has the focus, the remote moves it from
/// element to element, and a press of the remote acts on whichever has it. To act
/// on an element, the focus is first moved to it.
enum FocusSearch {
    /// What has the focus: where it is, and a name that tells it from its neighbours.
    ///
    /// A list can scroll under the focus and leave it in the same place on the screen,
    /// so the frame alone does not tell whether the focus moved.
    struct Focus: Equatable {
        var frame: CGRect
        var name: String = ""
    }

    /// Whether the focus is on a target, from the frames of both.
    ///
    /// The element that has the focus is not always the one a test names. It can be
    /// the cell that a button is in, or a button around the one with the identifier.
    /// So the focus is on the target when either has the middle of the other inside it.
    static func isOn(focus: CGRect, target: CGRect) -> Bool {
        guard !focus.isEmpty, !target.isEmpty else { return false }
        return focus.contains(CGPoint(x: target.midX, y: target.midY))
            || target.contains(CGPoint(x: focus.midX, y: focus.midY))
    }

    /// The directions to try moving the focus in to get nearer a target, best first.
    ///
    /// A target that is not level with the focus is above or below it, so the focus
    /// goes up or down first, and sideways if that moves nothing. A target that is
    /// level with the focus is beside it.
    static func directions(from focus: CGRect, to target: CGRect) -> [ScrollDirection] {
        let vertical: ScrollDirection? =
            target.midY > focus.midY ? .down : (target.midY < focus.midY ? .up : nil)
        let horizontal: ScrollDirection? =
            target.midX > focus.midX ? .right : (target.midX < focus.midX ? .left : nil)
        let isLevel = focus.minY < target.maxY && target.minY < focus.maxY
        let ordered = isLevel ? [horizontal, vertical] : [vertical, horizontal]
        return ordered.compactMap { $0 }
    }

    /// Moves the focus to a target, a press of the remote at a time.
    ///
    /// Each round reads where the focus and the target are, because moving the focus
    /// can scroll both. It stops when the focus is on the target, when no press
    /// towards the target moves the focus, or when the target has no frame, which is
    /// what tvOS reports for an element that is off the screen.
    ///
    /// - Parameters:
    ///   - maximumPresses: The most rounds to make.
    ///   - focus: Reads the element that has the focus, or `nil` if none has.
    ///   - target: Reads the frame of the target.
    ///   - press: Presses the remote in a direction.
    /// - Returns: Whether the focus ended up on the target.
    static func move(
        maximumPresses: Int = 100,
        focus: () -> Focus?,
        target: () -> CGRect,
        press: (ScrollDirection) -> Void
    ) -> Bool {
        for _ in 0..<maximumPresses {
            // An element that is off the screen has no frame on tvOS, so there is no
            // telling which way it is. The target is read first, because this is the
            // usual answer while a list is searched, and reading the focus takes time.
            let goal = target()
            if goal.isEmpty { return false }
            guard let now = focus() else { return false }
            if isOn(focus: now.frame, target: goal) { return true }

            var hasMoved = false
            for direction in directions(from: now.frame, to: goal) {
                press(direction)
                if focus() != now {
                    hasMoved = true
                    break
                }
            }
            if !hasMoved { return false }
        }
        guard let end = focus() else { return false }
        return isOn(focus: end.frame, target: target())
    }
}
