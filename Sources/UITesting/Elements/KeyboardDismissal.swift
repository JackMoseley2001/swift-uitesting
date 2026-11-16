import XCTest

extension XCUIApplication {
    /// Whether the software keyboard is showing.
    public var isKeyboardShowing: Bool {
        keyboards.firstMatch.exists
    }

    /// Puts the software keyboard away, if it is showing.
    ///
    /// There is no single gesture that dismisses the keyboard in every app, so this
    /// tries the ways an app can offer, in order, and stops at the first that works:
    ///
    /// 1. A key on the keyboard that hides it, which iPad keyboards have.
    /// 2. A "Done" button in a toolbar, the usual place for one above the keyboard.
    /// 3. A short drag on the content above the keyboard, which dismisses the keyboard
    ///    in a scroll view that allows it, such as one with SwiftUI's
    ///    `scrollDismissesKeyboard(_:)`. This can scroll the content a little.
    ///
    /// For a single-line field, pressing Return with
    /// ``UITestElement/submit(within:filePath:line:)`` is more direct.
    ///
    /// - Parameter timeout: How long to wait for the keyboard to go after each
    ///   attempt. The default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the keyboard is still showing after
    ///   every attempt, which means the app offers none of these ways. The failure is
    ///   recorded at the line of the call, and the test ends.
    public func dismissKeyboard(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let timeout = timeout ?? ActionTimeout.current
        let attempts: [() -> Bool] = [
            { self.tapIfPresent(self.keyboards.buttons["Hide keyboard"]) },
            { self.tapIfPresent(self.keyboards.buttons["Dismiss"]) },
            { self.tapIfPresent(self.toolbars.buttons["Done"]) },
            {
                self.dragAboveKeyboard()
                return true
            },
        ]

        let failure = KeyboardDismissal.failure(
            isShowing: { self.isKeyboardShowing },
            attempts: attempts,
            timeout: timeout
        )
        if let failure {
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }

    /// Drags a short way down the content above the keyboard.
    ///
    /// A swipe on the whole app starts too close to the keyboard to count as a drag
    /// of the content, so this starts well above it.
    private func dragAboveKeyboard() {
        let keyboardTop = keyboards.firstMatch.frame.minY / max(frame.height, 1)
        let start = keyboardTop * 0.3
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: start))
            .press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: start + 0.06)))
    }

    private func tapIfPresent(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable else { return false }
        element.tap()
        return true
    }
}

/// The order in which ways of dismissing the keyboard are tried.
enum KeyboardDismissal {
    /// How long to give the keyboard to go after one attempt, before trying the next.
    static let settlingTime: Duration = .seconds(1)

    /// Tries each way of dismissing the keyboard until it is no longer showing.
    ///
    /// - Parameters:
    ///   - isShowing: Whether the keyboard is showing.
    ///   - attempts: The ways to try, in order. Each returns whether it did anything.
    ///   - timeout: How long to wait for the keyboard to go after the last attempt.
    /// - Returns: `nil` if the keyboard went, or was not showing, and a description of
    ///   the failure if it is still there.
    static func failure(
        isShowing: () -> Bool,
        attempts: [() -> Bool],
        timeout: Duration,
        polling: ExpectationPolling = ExpectationPolling()
    ) -> String? {
        guard isShowing() else { return nil }

        for (index, attempt) in attempts.enumerated() where attempt() {
            let isLast = index == attempts.count - 1
            let wait = isLast ? timeout : min(settlingTime, timeout)
            if polling.wait(timeout: wait, until: { !isShowing() }) == .met {
                return nil
            }
        }
        return "Could not dismiss the keyboard: it was still showing after every way of dismissing it was tried\n"
            + "The app has to offer one: a key that hides the keyboard, a Done button in a toolbar, "
            + "or a scroll view that dismisses the keyboard when dragged."
    }
}
