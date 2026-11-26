import UITesting
import XCTest

/// The audit example has a note and two tags that are too faint to read easily, which
/// is what the audit finds. The audit needs iOS 17, so the suite says that it does.
@available(iOS 17, *)
@UITestSuite(traits: .example(.audit), .animationsDisabled)
final class AccessibilityAuditTests: XCTestCase {
    @UITest
    func passesWhenTheKnownIssuesAreIgnored(context: UITestContext) throws {
        try context.app[AuditID.title].waitToAppear()

        // The keys are an identifier and a family of them, of the same or different kinds.
        try context.runAccessibilityAudit(
            ignoring: [
                AuditID.faintNote: [.contrast],
                AuditID.tag: .contrast
            ]
        )
    }

    // The audit of a watch, a visionOS device and a television finds no issue with
    // faint text, so only the other platforms have an issue to report here.
    #if os(iOS) || os(macOS)
    @UITest
    func reportsAnIssueThatIsNotIgnored(context: UITestContext) throws {
        try context.app[AuditID.title].waitToAppear()

        // The failure is the point of this test, so it is expected, and has to be the
        // one about the note: the tags are ignored, and nothing else is wrong.
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { $0.compactDescription.contains("on AuditID.faintNote") }
        try XCTExpectFailure("The note is too faint, and the audit is not told to ignore it", options: options) {
            try context.runAccessibilityAudit(ignoring: [AuditID.tag: .contrast])
        }
    }

    @UITest
    func ignoringOneTypeOfIssueLeavesTheOthers(context: UITestContext) throws {
        try context.app[AuditID.title].waitToAppear()

        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { $0.compactDescription.contains("on AuditID.faintNote") }
        try XCTExpectFailure("Other types of issue are ignored for the note, but not its contrast", options: options) {
            try context.runAccessibilityAudit(
                ignoring: [
                    AuditID.faintNote: [.sufficientElementDescription, .hitRegion],
                    AuditID.tag: .all
                ]
            )
        }
    }
    #endif

    @UITest
    func looksOnlyForTheTypesItIsGiven(context: UITestContext) throws {
        try context.app[AuditID.title].waitToAppear()

        try context.runAccessibilityAudit(for: [.sufficientElementDescription, .elementDetection])
    }
}
