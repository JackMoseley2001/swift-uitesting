import XCTest

extension UITestElement {
    /// Scrolls until the element is on screen and can be tapped.
    ///
    /// A list only creates the rows near the ones on screen, so a row further down does
    /// not exist until the list is scrolled to it, and waiting for it does not help.
    /// This scrolls to it:
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].scrollIntoView().tap()
    /// ```
    ///
    /// Scrolling happens in whatever the element was looked up in. `app[id]` drags the
    /// middle of the app, which scrolls the view under it. To scroll one particular
    /// view, look the element up in it:
    ///
    /// ```swift
    /// try app[InboxID.list][InboxID.row(1234)].scrollIntoView()
    /// ```
    ///
    /// The search goes in `direction` until the content stops moving, then back the
    /// other way, so it finds the element whichever side it is on. Does nothing if the
    /// element is already in view.
    ///
    /// - Parameters:
    ///   - direction: The direction to look in first. The default is ``ScrollDirection/down``.
    ///   - maximumSwipes: The most swipes to make before going back the other way. Each
    ///     swipe moves the content by about half the height of the view. The default is 20.
    /// - Returns: This element, so that an action can follow.
    /// - Throws: ``RequirementFailedError`` if the element did not come into view. The
    ///   failure is recorded at the line of the call, and the test ends.
    @discardableResult
    public func scrollIntoView(
        _ direction: ScrollDirection = .down,
        maximumSwipes: Int = 20,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws -> UITestElement {
        let scrollView = scope ?? XCUIApplication()
        var screen = XCUIScreen.main.screenshot().pngRepresentation

        let found = ScrollSearch.find(
            direction: direction,
            maximumSwipes: maximumSwipes,
            isInView: { element.exists && element.isHittable },
            scroll: { direction in
                scrollView.drag(towards: direction)
                // The content has stopped moving when a swipe leaves the screen as it was.
                let before = screen
                screen = XCUIScreen.main.screenshot().pngRepresentation
                return screen != before
            }
        )
        guard found else {
            let kind = Kind.elementType == .any ? "element" : Kind.elementType.rawValue
            var failure = "Could not scroll to \(accessibilityIdentifier): no \(kind) with this identifier "
                + "came into view after scrolling \(direction) and then \(direction.opposite)"
            if let other = elementOfAnyKind, other.exists, !element.exists {
                failure += "\nAn element of another kind has this identifier. "
                    + "Is the identifier declared as the wrong kind?"
            }
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
        return self
    }
}

extension XCUIElement {
    /// Drags across the middle of the element to show the content in the given direction.
    ///
    /// The drag is slow and holds at its end, so the content does not carry on moving
    /// and nothing is skipped.
    fileprivate func drag(towards direction: ScrollDirection) {
        let (from, to): (CGVector, CGVector) =
            switch direction {
            case .down: (CGVector(dx: 0.5, dy: 0.7), CGVector(dx: 0.5, dy: 0.3))
            case .up: (CGVector(dx: 0.5, dy: 0.3), CGVector(dx: 0.5, dy: 0.7))
            case .right: (CGVector(dx: 0.7, dy: 0.5), CGVector(dx: 0.3, dy: 0.5))
            case .left: (CGVector(dx: 0.3, dy: 0.5), CGVector(dx: 0.7, dy: 0.5))
            }
        coordinate(withNormalizedOffset: from).press(
            forDuration: 0.05,
            thenDragTo: coordinate(withNormalizedOffset: to),
            withVelocity: .default,
            thenHoldForDuration: 0.2
        )
    }
}
