import XCTest

// tvOS has no touch screen, so XCTest has no taps, drags or swipes there.
#if !os(tvOS)
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
        let scrollView = try (scope ?? owningApp(inOrderTo: "scroll to", filePath: filePath, line: line)).viewToScroll
        // What is looked at to tell whether the content moved. On macOS it is the view,
        // because the screen has other windows on it, which change on their own, and on
        // visionOS because XCTest cannot take a picture of the screen there.
        #if os(macOS) || os(visionOS)
        let picture = { scrollView.screenshot().pngRepresentation }
        #else
        let picture = { XCUIScreen.main.screenshot().pngRepresentation }
        #endif
        var screen = picture()

        let found = ScrollSearch.find(
            direction: direction,
            maximumSwipes: maximumSwipes,
            isInView: {
                guard element.exists else { return false }
                if element.isHittable { return true }
                #if os(macOS)
                // Some controls on macOS, such as a stepper, report that they cannot be
                // clicked when they can. They are in view when their middle is.
                let frame = element.frame
                return !frame.isEmpty && scrollView.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
                #else
                return false
                #endif
            },
            scroll: { direction in
                scrollView.drag(towards: direction)
                // The content has stopped moving when a swipe leaves the screen as it was.
                let before = screen
                screen = picture()
                return screen != before
            }
        )
        guard found else {
            let kind = Kind.elementType == .any ? "element" : Kind.elementType.rawValue
            var failure = "Could not scroll to \(reference.name): no \(kind) with this \(reference.attribute) "
                + "came into view after scrolling \(direction) and then \(direction.opposite)"
            if let other = elementOfAnyKind, other.exists, !element.exists {
                failure += "\n" + reference.hint(forElementOfType: nil)
            }
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
        return self
    }
}

extension XCUIElement {
    /// The element that is scrolled to move the content of this one.
    ///
    /// It is the element itself, except on macOS for an app, which has no place for
    /// the pointer to be: there it is the first scroll view of the app's window. On
    /// visionOS an app cannot be swiped either, and it is the app's first list or
    /// scroll view.
    fileprivate var viewToScroll: XCUIElement {
        #if os(macOS)
        guard self is XCUIApplication else { return self }
        let window = windows.firstMatch
        let scrollView = window.scrollViews.firstMatch
        return scrollView.exists ? scrollView : window
        #elseif os(visionOS)
        guard self is XCUIApplication else { return self }
        let views = [collectionViews.firstMatch, scrollViews.firstMatch, tables.firstMatch]
        return views.first(where: \.exists) ?? self
        #else
        self
        #endif
    }

    /// Drags across the middle of the element to show the content in the given direction.
    ///
    /// The drag is slow and holds at its end, so the content does not carry on moving
    /// and nothing is skipped. On macOS, where a drag does not scroll, this turns the
    /// scroll wheel by half the size of the element. On visionOS it is a slow swipe.
    fileprivate func drag(towards direction: ScrollDirection) {
        #if os(macOS)
        let size = frame.size
        switch direction {
        case .down: scroll(byDeltaX: 0, deltaY: -size.height / 2)
        case .up: scroll(byDeltaX: 0, deltaY: size.height / 2)
        case .right: scroll(byDeltaX: -size.width / 2, deltaY: 0)
        case .left: scroll(byDeltaX: size.width / 2, deltaY: 0)
        }
        #elseif os(visionOS)
        // A drag that holds at its end moves nothing on visionOS. A slow swipe does.
        switch direction {
        case .down: swipeUp(velocity: .slow)
        case .up: swipeDown(velocity: .slow)
        case .right: swipeLeft(velocity: .slow)
        case .left: swipeRight(velocity: .slow)
        }
        #else
        let (from, to): (CGVector, CGVector) =
            switch direction {
            case .down: (CGVector(dx: 0.5, dy: 0.7), CGVector(dx: 0.5, dy: 0.3))
            case .up: (CGVector(dx: 0.5, dy: 0.3), CGVector(dx: 0.5, dy: 0.7))
            case .right: (CGVector(dx: 0.7, dy: 0.5), CGVector(dx: 0.3, dy: 0.5))
            case .left: (CGVector(dx: 0.3, dy: 0.5), CGVector(dx: 0.7, dy: 0.5))
            }
        // On watchOS the content carries on for several times the length of a drag at
        // the usual speed, which takes rows past before they can be seen.
        #if os(watchOS)
        let velocity = XCUIGestureVelocity.slow
        #else
        let velocity = XCUIGestureVelocity.default
        #endif
        coordinate(withNormalizedOffset: from).drag(
            afterPressingFor: 0.05,
            to: coordinate(withNormalizedOffset: to),
            velocity: velocity,
            thenHoldingFor: 0.2
        )
        #endif
    }
}

// A Mac app has no pull to refresh, and neither has a watch app.
#if !os(macOS) && !os(watchOS)
extension UITestElement {
    /// Pulls a list or scroll view down to refresh it, once it exists.
    ///
    /// ```swift
    /// try app[InboxID.list].pullToRefresh()
    /// #expect(app[InboxID.row(1234)].exists, within: .seconds(5))
    /// ```
    ///
    /// The pull is a drag from near the top of the element to near its bottom. It
    /// refreshes only if the content is at its top, because otherwise the drag
    /// scrolls the content back up, as it does for a person.
    ///
    /// The call returns when the drag is done, not when the refresh is. Wait for what
    /// the refresh brings with an expectation that has a timeout.
    ///
    /// - Parameter timeout: How long to wait for the element. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element is not there in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func pullToRefresh(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .exists, inOrderTo: "pull to refresh", within: timeout, filePath: filePath, line: line)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).press(
            forDuration: 0.05,
            thenDragTo: element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        )
    }
}
#endif
#endif

#if os(tvOS)
extension UITestElement {
    /// Moves the focus until the element is on screen and has it.
    ///
    /// tvOS has no touch screen, and content scrolls as the focus moves through it. A
    /// list only creates the rows near the ones on screen, so a row further down does
    /// not exist until the focus is moved towards it. This presses the remote in
    /// `direction` until the element is on the screen, and then moves the focus to it:
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].scrollIntoView().tap()
    /// ```
    ///
    /// The search goes in `direction` until a press no longer moves the focus, then
    /// back the other way, so it finds the element whichever side it is on.
    ///
    /// - Parameters:
    ///   - direction: The direction to look in first. The default is ``ScrollDirection/down``.
    ///   - maximumSwipes: The most steps to make before going back the other way. Each
    ///     step is three presses of the remote. The default is 20.
    /// - Returns: This element, so that an action can follow.
    /// - Throws: ``RequirementFailedError`` if the focus did not reach the element. The
    ///   failure is recorded at the line of the call, and the test ends.
    @discardableResult
    public func scrollIntoView(
        _ direction: ScrollDirection = .down,
        maximumSwipes: Int = 20,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws -> UITestElement {
        var focus = XCUIApplication.focus
        let found = ScrollSearch.find(
            direction: direction,
            maximumSwipes: maximumSwipes,
            isInView: { element.moveFocus() },
            scroll: { direction in
                // The elements beside the one with the focus are on the screen, so
                // nothing goes past unseen in three presses, and looking after each
                // press would take most of the time.
                let before = focus
                focus = XCUIRemote.shared.pressAndWaitForFocus(direction, times: 3, from: before)
                return focus != before
            }
        )
        guard found else {
            let kind = Kind.elementType == .any ? "element" : Kind.elementType.rawValue
            var failure = "Could not scroll to \(reference.name): the focus did not reach a \(kind) with this "
                + "\(reference.attribute) after moving \(direction) and then \(direction.opposite)"
            if let other = elementOfAnyKind, other.exists, !element.exists {
                failure += "\n" + reference.hint(forElementOfType: nil)
            }
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
        return self
    }
}
#endif
