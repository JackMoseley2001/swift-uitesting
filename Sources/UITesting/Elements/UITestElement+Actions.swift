import XCTest

extension UITestElement {
    /// Taps the element, once it exists and is enabled.
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
        element.tap()
    }

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
