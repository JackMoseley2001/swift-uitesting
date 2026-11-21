import XCTest

// What an action is on each platform. A Mac has a pointer and no touch screen, so
// XCTest's `tap()` does nothing to a Mac app, and the action there is a click.

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
