import UITestingCore

/// Identifiers for the accessibility audit example.
enum AuditID: ElementIDs {
    static var title: StaticText { element() }
    static var faintNote: StaticText { element() }
    static var saveButton: Button { element() }
    static var tag: StaticText.Family<Int> { family() }
}
