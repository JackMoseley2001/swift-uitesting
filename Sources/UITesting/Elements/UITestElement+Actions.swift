import XCTest

extension UITestElement {
    /// Taps the element, once it exists and is enabled. On macOS this is a click. On
    /// tvOS the remote moves the focus to the element and selects it.
    ///
    /// ```swift
    /// try app[LoginID.signInButton].tap()
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the element. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element is not ready in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func tap(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .enabled, inOrderTo: "tap", within: timeout, filePath: filePath, line: line)
        #if os(tvOS)
        try moveFocus(inOrderTo: "tap", filePath: filePath, line: line)
        XCUIRemote.shared.press(.select)
        #else
        element.tapOrClick()
        #endif
    }

    #if os(tvOS)
    /// Selects the element with the remote, once it exists and is enabled.
    ///
    /// This is ``tap(within:filePath:line:)`` under the name the action has on tvOS:
    /// the focus is moved to the element, and the remote's select button is pressed.
    ///
    /// ```swift
    /// try app[LoginID.submitButton].select()
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the element. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element is not ready in time, or the
    ///   focus cannot be moved to it. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func select(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try tap(within: timeout, filePath: filePath, line: line)
    }

    /// Moves the focus to the element with the remote, once it exists.
    ///
    /// The remote is pressed towards the element until the focus is on it. The focus
    /// is on an element when it is on something that holds it, such as the row of a
    /// list that a button is in.
    ///
    /// ```swift
    /// try app[LibraryID.poster(12)].focus()
    /// #expect(app[LibraryID.title].label == "Solaris")
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the element. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element is not there in time, or the
    ///   focus cannot be moved to it. The failure is recorded at the line of the call,
    ///   and the test ends.
    public func focus(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .exists, inOrderTo: "focus", within: timeout, filePath: filePath, line: line)
        try moveFocus(inOrderTo: "focus", filePath: filePath, line: line)
    }

    /// Moves the focus to the element, or ends the test if the remote cannot.
    func moveFocus(inOrderTo intent: String, filePath: StaticString, line: UInt) throws {
        guard element.moveFocus() else {
            if element.exists, element.frame.isEmpty {
                try fail(
                    "Could not \(intent) \(reference.name): it is off the screen, so there is no telling "
                        + "which way to move the focus. Scroll to it first with scrollIntoView()",
                    filePath: filePath,
                    line: line
                )
            }
            let focused = XCUIApplication.focusedElement
            let stopped = focused.exists ? "it stopped on \(focused)" : "nothing has the focus"
            try fail(
                "Could not \(intent) \(reference.name): the remote could not move the focus to it, and \(stopped)",
                filePath: filePath,
                line: line
            )
        }
    }
    #endif

    #if os(macOS)
    /// Clicks the element, once it exists and is enabled.
    ///
    /// This is ``tap(within:filePath:line:)`` under the name the action has on a Mac.
    /// Use `tap` in a test that runs on other platforms as well.
    ///
    /// ```swift
    /// try app[LoginID.signInButton].click()
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the element. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element is not ready in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func click(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .enabled, inOrderTo: "click", within: timeout, filePath: filePath, line: line)
        element.click()
    }
    #endif

    /// Waits for the element to exist.
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].waitToAppear()
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the element. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element does not appear in time. The
    ///   failure is recorded at the line of the call, and the test ends.
    public func waitToAppear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .exists, inOrderTo: "find", within: timeout, filePath: filePath, line: line)
    }

    /// Waits for the element to stop existing.
    ///
    /// ```swift
    /// try app[InboxID.loadingIndicator].waitToDisappear(within: .seconds(10))
    /// ```
    ///
    /// - Parameter timeout: How long to wait for the element to go. The default is the
    ///   test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the element is still there when the time
    ///   is up. The failure is recorded at the line of the call, and the test ends.
    public func waitToDisappear(
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try wait(toBe: .absent, inOrderTo: "see the end of", within: timeout, filePath: filePath, line: line)
    }

    func wait(
        toBe requirement: ElementRequirement,
        inOrderTo intent: String,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt
    ) throws {
        let failure = ElementWait.failure(
            intent: intent,
            element: reference,
            kind: Kind.elementType == .any ? "element" : Kind.elementType.rawValue,
            requirement: requirement,
            timeout: timeout ?? ActionTimeout.current,
            probe: ElementProbe(
                exists: { element.exists },
                isEnabled: { element.isEnabled },
                typeOfElementWithSameIdentifier: {
                    guard let other = elementOfAnyKind, other.exists else { return nil }
                    let type = other.elementType
                    let name = UITestingCore.ElementType.allCases.first { XCUIElement.ElementType($0) == type }
                    return name?.rawValue ?? "\(type.rawValue)"
                },
                matchCount: labelMatch.map { match in { match.matches.count } }
            )
        )
        if let failure {
            ExpectationReporter.report(message: failure, filePath: filePath, line: line)
            throw RequirementFailedError(message: failure)
        }
    }
}
