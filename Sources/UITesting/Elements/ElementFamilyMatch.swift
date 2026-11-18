import Foundation

/// The parts of finding the elements of a family of identifiers that do not need a
/// running app.
struct ElementFamilyMatch: Equatable {
    /// What the identifier of every element in the family starts with, such as
    /// `"InboxID.row("`.
    var identifierPrefix: String

    /// Creates the match for a family of identifiers.
    init<Kind: ElementKind, Value>(_ family: ElementIDFamily<Kind, Value>) {
        identifierPrefix = family.accessibilityIdentifierPrefix
    }

    /// The predicate that picks the elements of the family out of a query, which are
    /// the ones whose identifier starts with the ``identifierPrefix``.
    var predicate: NSPredicate {
        NSPredicate(format: "identifier BEGINSWITH %@", identifierPrefix)
    }

    /// Returns what stands for the identifier of the element at a position in the
    /// family while no element is there, such as `InboxID.row(…)[2]`.
    ///
    /// An element has to exist for its own identifier to be read. Until then, this is
    /// how a failure says which element it was waiting for.
    func description(ofElementAt index: Int) -> String {
        "\(identifierPrefix)…)[\(index)]"
    }
}
