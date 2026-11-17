import XCTest

extension UITestContext {
    #if os(iOS)
    /// Sends the app to the background, as if the user had gone to the Home Screen.
    ///
    /// The app keeps running. Bring it back with ``foreground()``:
    ///
    /// ```swift
    /// @UITest
    /// func hidesTheBalanceAfterLeavingTheApp(context: UITestContext) throws {
    ///     try context.background()
    ///     context.foreground()
    ///
    ///     #expect(context.app[AccountID.balance].label == "Hidden")
    /// }
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the app to reach the background. The
    ///   default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the app is not running, or has not
    ///   reached the background in time. The failure is recorded at the line of the
    ///   call, and the test ends.
    public func background(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let failure = AppStateWait.failureToReachBackground(
            timeout: timeout ?? ActionTimeout.current,
            state: { app.runState },
            leave: { XCUIDevice.shared.press(.home) },
            reachesBackground: { app.wait(for: .runningBackground, timeout: $0.timeInterval) }
        )
        if let failure {
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }
    #endif

    /// Brings the app to the foreground.
    ///
    /// An app that is running keeps running, with everything it holds in memory. An
    /// app that is not running, such as after ``terminate()``, is launched with the
    /// configuration of its last launch.
    ///
    /// XCTest fails the test if the app cannot be brought to the foreground.
    public func foreground() {
        app.activate()
    }

    /// Ends the app.
    ///
    /// Use this to check what the app does when it starts from nothing, such as
    /// opening a link with ``open(_:)``. To end the app and launch it again in one
    /// step, call ``relaunch(with:)``.
    public func terminate() {
        app.terminate()
    }

    /// Opens a link, in the way the system does when the user taps one.
    ///
    /// If the app is running, in the foreground or the background, it keeps running
    /// and receives the link. If it is not running, it is launched with the link and
    /// with the configuration of its last launch.
    ///
    /// ```swift
    /// @UITest
    /// func opensAnOrderFromALink(context: UITestContext) {
    ///     context.open(URL(string: "shop://orders/42")!)
    ///
    ///     #expect(context.app[OrderID.title].label == "Order 42")
    /// }
    /// ```
    ///
    /// While the app is running the link goes to whichever app the system chooses for
    /// it. That is your app for a URL scheme only it declares, and for a universal
    /// link whose domain is associated with it on the device that runs the test.
    ///
    /// - Parameter url: The link to open.
    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    public func open(_ url: URL) {
        switch LinkOpening(appState: app.runState) {
        case .throughTheSystem: XCUIDevice.shared.system.open(url)
        case .byLaunchingTheApp: app.open(url)
        }
    }

    /// Launches the app again with a link, ending it first if it is running.
    ///
    /// Use this to check what the app does when a link starts it, whatever it was
    /// doing before:
    ///
    /// ```swift
    /// try context.relaunch(opening: URL(string: "shop://orders/42")!)
    /// ```
    ///
    /// The traits are used in the same way as in ``relaunch(with:)``.
    ///
    /// - Parameters:
    ///   - url: The link the app is launched with.
    ///   - traits: Traits to apply on top of the test's traits for this launch.
    /// - Throws: An error thrown by a trait while it configures the launch.
    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    public func relaunch(opening url: URL, with traits: any UITestTrait...) throws {
        app.configure(with: try launch.applying(traits))
        app.open(url)
    }
}

extension XCUIApplication {
    /// Whether the app is running, and where.
    var runState: AppRunState {
        switch state {
        case .notRunning: .notRunning
        case .runningBackground: .background
        #if !os(macOS)
        case .runningBackgroundSuspended: .background
        #endif
        case .runningForeground: .foreground
        case .unknown: .unknown
        @unknown default: .unknown
        }
    }
}
