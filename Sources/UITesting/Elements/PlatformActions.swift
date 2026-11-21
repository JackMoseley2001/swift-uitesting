import XCTest

// What an action is on each platform. A Mac has a pointer and no touch screen, so
// XCTest's `tap()` does nothing to a Mac app, and the action there is a click. tvOS
// has no touch screen either: the remote moves the focus to an element and selects it.

#if os(tvOS)
extension XCUIElement {
    /// Moves the focus to the element with the remote, and selects it.
    ///
    /// Nothing is selected if the focus cannot be moved to the element, and the
    /// failure is reported, because a press would act on some other element.
    func tapOrClick() {
        guard moveFocus() else {
            ExpectationReporter.report(
                message: "Could not select \(self): the remote could not move the focus to it",
                filePath: #filePath,
                line: #line
            )
            return
        }
        XCUIRemote.shared.press(.select)
    }

    /// Moves the focus to the element with the remote.
    ///
    /// - Returns: Whether the focus ended up on the element.
    @discardableResult
    func moveFocus() -> Bool {
        FocusSearch.move(
            focus: { XCUIApplication.focus },
            // One snapshot reads the frame, and fails for an element that is not there.
            target: { (try? self.snapshot())?.frame ?? .zero },
            press: { XCUIRemote.shared.pressAndWaitForFocus($0) }
        )
    }
}

extension XCUIApplication {
    /// The element of the app under test that has the focus.
    static var focusedElement: XCUIElement {
        XCUIApplication().descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }
}

extension XCUIApplication {
    /// What has the focus in the app under test, or `nil` if nothing has.
    static var focus: FocusSearch.Focus? {
        // One snapshot reads everything, where each property of the element would be a
        // query of its own. It fails if nothing has the focus.
        guard let focused = try? focusedElement.snapshot() else { return nil }
        return FocusSearch.Focus(frame: focused.frame, name: "\(focused.identifier)|\(focused.label)")
    }
}

extension XCUIRemote {
    /// Presses the remote in a direction, and gives the focus a moment to move.
    ///
    /// The focus moves with an animation, and is still where it was just after the press.
    ///
    /// - Parameters:
    ///   - direction: The direction to press in.
    ///   - times: How many presses to make before looking at the focus.
    ///   - before: What had the focus before, if it has just been read.
    /// - Returns: What has the focus afterwards, which is the same as before if the
    ///   focus did not move.
    @discardableResult
    func pressAndWaitForFocus(
        _ direction: ScrollDirection,
        times: Int = 1,
        from before: FocusSearch.Focus? = XCUIApplication.focus
    ) -> FocusSearch.Focus? {
        for _ in 0..<times {
            press(Button(direction))
        }
        var after = before
        _ = ExpectationPolling().wait(timeout: .seconds(1)) {
            after = XCUIApplication.focus
            return after != before
        }
        return after
    }
}

extension XCUIRemote.Button {
    /// The button of the remote that moves the focus in a direction.
    init(_ direction: ScrollDirection) {
        switch direction {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        }
    }
}
#endif

// tvOS has no touch screen, so XCTest has no taps, drags or swipes there.
#if !os(tvOS)
extension XCUIElement {
    /// Taps the element, or clicks it on macOS.
    func tapOrClick() {
        #if os(macOS)
        click()
        #else
        tap()
        #endif
    }
}

extension XCUICoordinate {
    /// Taps the point, or clicks it on macOS.
    func tapOrClick() {
        #if os(macOS)
        click()
        #else
        tap()
        #endif
    }

    /// Presses the point and drags to another, with the pointer on macOS.
    ///
    /// - Parameters:
    ///   - duration: How long to press before the drag starts.
    ///   - end: The point to drag to.
    ///   - velocity: How fast to drag.
    ///   - hold: How long to hold at the end, so that the content does not carry on moving.
    func drag(
        afterPressingFor duration: TimeInterval,
        to end: XCUICoordinate,
        velocity: XCUIGestureVelocity = .default,
        thenHoldingFor hold: TimeInterval = 0
    ) {
        #if os(macOS)
        click(forDuration: duration, thenDragTo: end, withVelocity: velocity, thenHoldForDuration: hold)
        #else
        press(forDuration: duration, thenDragTo: end, withVelocity: velocity, thenHoldForDuration: hold)
        #endif
    }
}
#endif

extension XCUIElement {
    /// The label of the element, or on macOS the text it shows if it has no label.
    ///
    /// On macOS, text such as a SwiftUI `Text` reports what it says as its value and
    /// has no label. Everywhere else it is the label.
    var labelOrText: String {
        #if os(macOS)
        let label = label
        guard label.isEmpty, elementType == .staticText else { return label }
        return ElementLabel.text(label: label, value: value)
        #else
        label
        #endif
    }
}

extension NSPredicate {
    /// Matches the elements that ``XCUIElement/labelOrText`` gives this label.
    static func hasLabel(_ label: String) -> NSPredicate {
        #if os(macOS)
        NSPredicate(
            format: "label == %@ OR (label == '' AND elementType == %d AND value == %@)",
            label,
            XCUIElement.ElementType.staticText.rawValue,
            label
        )
        #else
        NSPredicate(format: "label == %@", label)
        #endif
    }
}

/// The part of reading a label that does not need a running app.
enum ElementLabel {
    /// Returns the label of an element, or the text it reports as its value if the label is empty.
    static func text(label: String, value: Any?) -> String {
        guard label.isEmpty, let text = value as? String else { return label }
        return text
    }
}

extension XCUIElement {
    /// Whether the element can be acted on: tapped or clicked, or on tvOS given the focus.
    var isReachable: Bool {
        #if os(tvOS)
        // tvOS has no touch screen, so nothing there can be hit. An element that is
        // there can be given the focus.
        exists
        #else
        isHittable
        #endif
    }
}
