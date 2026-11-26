import Testing
import UITestingCore
import XCTest

@testable import UITesting

@Suite
struct AccessibilityAuditTests {
    private enum LoginID: ElementIDs {
        static var signInButton: Button { element() }
        static var terms: StaticText { element() }
        static var row: Cell.Family<Int> { family() }
        static var rowTitle: StaticText { element() }
    }

    @available(macOS 14, *)
    private func issue(
        _ type: XCUIAccessibilityAuditType = .contrast,
        identifier: String? = LoginID.signInButton.accessibilityIdentifier,
        element: String? = nil
    ) -> AccessibilityAudit.Issue {
        AccessibilityAudit.Issue(
            type: type,
            summary: "Contrast failed",
            detail: "Contrast failed for SwiftUI.AccessibilityNode",
            identifier: identifier,
            element: element
        )
    }

    @available(macOS 14, *)
    @Test
    func issueOfAnIgnoredTypeIsNotReported() {
        let reported = AccessibilityAudit.reported([issue()], ignoring: [LoginID.signInButton: [.contrast]])

        #Testing::expect(reported.isEmpty)
    }

    @available(macOS 14, *)
    @Test
    func issueOfAnotherTypeIsReported() {
        let issues = [issue(.contrast), issue(.hitRegion)]

        let reported = AccessibilityAudit.reported(issues, ignoring: [LoginID.signInButton: .contrast])

        #Testing::expect(reported == [issue(.hitRegion)])
    }

    @available(macOS 14, *)
    @Test
    func issueOfAnotherElementIsReported() {
        let other = issue(identifier: LoginID.terms.accessibilityIdentifier)

        let reported = AccessibilityAudit.reported([issue(), other], ignoring: [LoginID.signInButton: .all])

        #Testing::expect(reported == [other])
    }

    @available(macOS 14, *)
    @Test
    func keysCanBeIdentifiersOfDifferentKinds() {
        let issues = [issue(.contrast), issue(.hitRegion, identifier: LoginID.terms.accessibilityIdentifier)]

        let reported = AccessibilityAudit.reported(
            issues,
            ignoring: [LoginID.signInButton: .contrast, LoginID.terms: [.hitRegion, .contrast]]
        )

        #Testing::expect(reported.isEmpty)
    }

    @available(macOS 14, *)
    @Test
    func familyIgnoresEveryElementInItAndNoOther() {
        let inFamily = issue(identifier: LoginID.row(7).accessibilityIdentifier)
        let outside = issue(identifier: LoginID.rowTitle.accessibilityIdentifier)

        let reported = AccessibilityAudit.reported([inFamily, outside], ignoring: [LoginID.row: .contrast])

        #Testing::expect(reported == [outside])
    }

    @available(macOS 14, *)
    @Test
    func issueOfAnElementWithNoIdentifierIsAlwaysReported() {
        let issues = [issue(identifier: nil), issue(identifier: "")]

        let reported = AccessibilityAudit.reported(issues, ignoring: [ElementID<ElementKinds.Button>(""): .all])

        #Testing::expect(reported == issues)
    }

    @available(macOS 14, *)
    @Test
    func messageNamesTheElementAndTheTypeToIgnore() {
        #Testing::expect(
            AccessibilityAudit.message(for: issue()) == """
                Accessibility audit: Contrast failed on \(LoginID.signInButton.accessibilityIdentifier)
                Contrast failed for SwiftUI.AccessibilityNode
                The type of this issue is .contrast.
                """
        )
    }

    @available(macOS 14, *)
    @Test
    func messageDescribesAnElementThatHasNoIdentifier() {
        let message = AccessibilityAudit.message(for: issue(identifier: "", element: "\"Continue\" Button"))

        #Testing::expect(message.hasPrefix("Accessibility audit: Contrast failed on \"Continue\" Button\n"))
    }

    @available(macOS 14, *)
    @Test
    func messageOfAnIssueWithNoElementSaysOnlyWhatIsWrong() {
        let message = AccessibilityAudit.message(for: issue(identifier: nil))

        #Testing::expect(message.hasPrefix("Accessibility audit: Contrast failed\n"))
    }

    @available(macOS 14, *)
    @Test
    func typesThatOnlySomePlatformsHaveAreNamed() {
        #Testing::expect(AccessibilityAudit.name(of: XCUIAccessibilityAuditType(rawValue: 1 << 16)) == "dynamicType")
        #Testing::expect(AccessibilityAudit.name(of: XCUIAccessibilityAuditType(rawValue: 1 << 33)) == "parentChild")
        #Testing::expect(AccessibilityAudit.name(of: XCUIAccessibilityAuditType(rawValue: 1 << 40)) == nil)
    }
}
