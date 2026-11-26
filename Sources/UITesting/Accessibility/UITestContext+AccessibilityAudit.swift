import XCTest

extension UITestContext {
    /// Checks what the app is showing for accessibility issues, and records a failure
    /// for each one it finds.
    ///
    /// The audit is the one that XCTest runs, which looks at the screen as it is, so
    /// call it once the screen you mean to check is showing:
    ///
    /// ```swift
    /// @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    /// @UITest
    /// func theSignInScreenIsAccessible(context: UITestContext) throws {
    ///     try context.app[LoginID.signInButton].waitToAppear()
    ///
    ///     try context.runAccessibilityAudit()
    /// }
    /// ```
    ///
    /// To accept an issue you know about, name the element and the types of issue to
    /// ignore for it. The rest of the screen is still checked, and so is the element
    /// for the other types:
    ///
    /// ```swift
    /// try context.runAccessibilityAudit(
    ///     ignoring: [
    ///         LoginID.signInButton: .contrast,
    ///         LoginID.terms: [.dynamicType, .textClipped]
    ///     ]
    /// )
    /// ```
    ///
    /// Each issue is a failure at the line of the call, which names the element and
    /// the type of the issue. The test carries on after them.
    ///
    /// - Parameters:
    ///   - types: The types of issue to look for. The default is all of them.
    ///   - exclusions: The issues not to report, as a dictionary from an identifier,
    ///     or a family of identifiers, to the types of issue to ignore for it.
    /// - Throws: The error that XCTest gives if the audit could not be run.
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
    public func runAccessibilityAudit(
        for types: XCUIAccessibilityAuditType = .all,
        ignoring exclusions: AccessibilityAuditExclusions = [:],
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var issues: [AccessibilityAudit.Issue] = []
        try app.performAccessibilityAudit(for: types) { issue in
            issues.append(AccessibilityAudit.Issue(issue))
            // Every issue is handled here, so that XCTest does not record it as well.
            return true
        }
        for issue in AccessibilityAudit.reported(issues, ignoring: exclusions) {
            ExpectationReporter.report(
                message: AccessibilityAudit.message(for: issue),
                filePath: filePath,
                line: line
            )
        }
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
extension AccessibilityAudit.Issue {
    /// Reads what an audit found from XCTest's issue.
    @MainActor
    init(_ issue: XCUIAccessibilityAuditIssue) {
        // Reading the identifier of an element that has gone would be a failure of its own.
        let element = issue.element.flatMap { $0.exists ? $0 : nil }
        self.init(
            type: issue.auditType,
            summary: issue.compactDescription,
            detail: issue.detailedDescription,
            identifier: element?.identifier,
            element: element?.description
        )
    }
}
