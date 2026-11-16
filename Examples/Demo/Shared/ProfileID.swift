import UITestingCore

/// Identifiers for the profile form, whose fields UI tests type into.
enum ProfileID: ElementIDs {
    static var nameField: TextField { element() }
    static var passwordField: SecureTextField { element() }
    static var notesField: TextView { element() }
    static var summary: StaticText { element() }
    static var submittedName: StaticText { element() }
    static var hideKeyboardButton: Button { element() }
}
