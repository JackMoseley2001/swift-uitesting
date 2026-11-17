import UITestingCore

/// Identifiers for the inbox example, where each row is identified by its message.
enum InboxID: ElementIDs {
    static var lastAction: StaticText { element() }
    static var list: CollectionView { element() }
    static func row(_ id: Int) -> StaticText { element(id) }
    static func deleteButton(_ id: Int) -> Button { element(id) }
}
