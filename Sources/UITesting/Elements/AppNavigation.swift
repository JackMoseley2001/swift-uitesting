import XCTest

extension XCUIApplication {
    /// The title of the screen that the app is showing, read without waiting. Empty if
    /// it shows none.
    ///
    /// This is the title that a SwiftUI `navigationTitle` or a `UINavigationItem` gives
    /// a screen. It is in the navigation bar on iOS and in the title bar of the window
    /// on macOS, and this reads whichever it is:
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].tap()
    ///
    /// #expect(app.navigationTitle == "Message", within: .seconds(2))
    /// ```
    ///
    /// In an app that shows several navigation bars or windows at once, this is the
    /// title of the first.
    @MainActor
    public var navigationTitle: String {
        #if os(macOS)
        let window = windows.firstMatch
        guard window.exists else { return "" }
        let title = window.title
        if !title.isEmpty { return title }
        // A window that does not report its title still shows it, as text of its own.
        let text = window.children(matching: .staticText).firstMatch
        return text.exists ? text.labelOrText : ""
        #else
        // A navigation bar has its title as its identifier.
        let bar = navigationBars.firstMatch
        return bar.exists ? bar.identifier : ""
        #endif
    }

    /// Goes back to the screen before, with the button that a navigation stack shows
    /// for it, once the button is there.
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].tap()
    /// try app.goBack()
    /// ```
    ///
    /// The label of the button is in the language of the app, and on iOS it is the
    /// title of the screen before. This finds the button by what the system calls it,
    /// which is the same in every language. It is in the navigation bar on iOS and in
    /// the toolbar of the window on macOS. Before iOS 26 and visionOS 26 the system calls it nothing,
    /// and this taps the first button of the navigation bar, which is the button to
    /// go back on a screen that has one. tvOS shows no such button, and this presses
    /// the menu button of the remote, which goes back there.
    ///
    /// - Parameter timeout: How long to wait for the button. The default is the test's
    ///   ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if no button to go back shows in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    @MainActor
    public func goBack(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        #if os(tvOS)
        // tvOS shows no button to go back. The remote's menu button goes back.
        XCUIRemote.shared.press(.menu)
        #else
        let timeout = timeout ?? ActionTimeout.current
        let button = backButton
        guard ExpectationPolling().wait(timeout: timeout, until: { button.exists }) == .met else {
            let message = AppNavigation.noBackButton(after: timeout)
            ExpectationReporter.report(message: message, filePath: filePath, line: line)
            throw RequirementFailedError(message: message)
        }
        button.tapOrClick()
        #endif
    }

    #if !os(tvOS)
    /// The button that goes back, found by the identifier the system gives it.
    @MainActor
    private var backButton: XCUIElement {
        #if os(macOS)
        windows.firstMatch.toolbars.buttons[AppNavigation.macBackButtonIdentifier].firstMatch
        #else
        // Before iOS 26 and visionOS 26 the button has no identifier. It is the first
        // button of the bar.
        if #available(iOS 26, visionOS 26, *) {
            navigationBars.buttons[AppNavigation.backButtonIdentifier].firstMatch
        } else {
            navigationBars.firstMatch.buttons.firstMatch
        }
        #endif
    }
    #endif
}

/// The parts of moving between screens that do not need a running app.
enum AppNavigation {
    /// The identifier that UIKit gives the button that goes back, in every language.
    static let backButtonIdentifier = "BackButton"

    /// The identifier that the button that goes back has on macOS, which is the name
    /// of the symbol it shows.
    static let macBackButtonIdentifier = "chevron.backward"

    /// Describes a button to go back that did not show.
    static func noBackButton(after timeout: Duration) -> String {
        "Could not go back: no button to go back appeared within \(ExpectationFailure.describe(timeout)). "
            + "The app shows one on a screen that was pushed onto a navigation stack"
    }
}
