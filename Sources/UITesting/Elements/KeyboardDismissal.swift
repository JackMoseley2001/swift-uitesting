import XCTest

extension XCUIApplication {
    /// Whether the software keyboard is on screen.
    ///
    /// This is `false` when the keyboard is off screen as well as when there is none,
    /// which is where iOS keeps it while a hardware keyboard is in use.
    public var isKeyboardShowing: Bool {
        let keyboard = keyboards.firstMatch
        return keyboard.exists && keyboard.frame.intersects(frame)
    }

    /// Puts the software keyboard away, if it is showing.
    ///
    /// There is no gesture that dismisses the keyboard in every app. This drags from
    /// the content above the keyboard down over the keyboard, which dismisses it in a
    /// scroll view that is set up for that: one with SwiftUI's
    /// `scrollDismissesKeyboard(_:)` set to `.immediately` or `.interactively`, or
    /// UIKit's `keyboardDismissMode` set to `.onDrag` or `.interactive`. The drag can
    /// scroll the content.
    ///
    /// It does not work where the scroll view never dismisses the keyboard, which
    /// includes a SwiftUI `ScrollView` that does not set a mode.
    ///
    /// It does not look for a button to tap, such as "Done". A button's label changes
    /// with the language, and a button with the same label may do something else,
    /// such as close a sheet. If the app has a button that dismisses the keyboard,
    /// give it an identifier and tap it:
    ///
    /// ```swift
    /// try app[NotesID.keyboardDoneButton].tap()
    /// ```
    ///
    /// For a single-line field, pressing Return with
    /// ``UITestElement/submit(within:filePath:line:)`` is more direct.
    ///
    /// - Parameter timeout: How long to wait for the keyboard to go. The default is
    ///   the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the keyboard is still showing
    ///   afterwards. The failure is recorded at the line of the call, and the test ends.
    public func dismissKeyboard(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let failure = KeyboardDismissal.failure(
            isShowing: { self.isKeyboardShowing },
            dismiss: { self.dragAboveKeyboard() },
            timeout: timeout ?? ActionTimeout.current
        )
        if let failure {
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }

    /// Drags slowly from the content above the keyboard to the bottom of the screen.
    ///
    /// A scroll view that dismisses the keyboard immediately does so as the drag
    /// starts. One that dismisses it interactively needs the finger to carry on down
    /// over the keyboard and stay there for a moment. The drag starts well above the
    /// keyboard, because one that starts next to it is not taken as a drag of the content.
    private func dragAboveKeyboard() {
        let keyboardTop = keyboards.firstMatch.frame.minY / max(frame.height, 1)
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: keyboardTop * 0.3)).press(
            forDuration: 0.05,
            thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97)),
            withVelocity: .slow,
            thenHoldForDuration: 0.5
        )
    }
}

/// The steps of dismissing the keyboard that do not need a running app.
enum KeyboardDismissal {
    /// Dismisses the keyboard if it is showing, and waits for it to go.
    ///
    /// - Parameters:
    ///   - isShowing: Whether the keyboard is showing.
    ///   - dismiss: Makes the gesture that dismisses the keyboard.
    ///   - timeout: How long to wait for the keyboard to go.
    /// - Returns: `nil` if the keyboard went, or was not showing, and a description of
    ///   the failure if it is still there.
    static func failure(
        isShowing: () -> Bool,
        dismiss: () -> Void,
        timeout: Duration,
        polling: ExpectationPolling = ExpectationPolling()
    ) -> String? {
        guard isShowing() else { return nil }

        dismiss()
        if polling.wait(timeout: timeout, until: { !isShowing() }) == .met {
            return nil
        }
        return "Could not dismiss the keyboard: it was still showing after a drag from the content down over it\n"
            + "The drag only works in a scroll view that dismisses the keyboard when dragged, "
            + "immediately or interactively. Otherwise, tap the app's own button for dismissing the keyboard."
    }
}
