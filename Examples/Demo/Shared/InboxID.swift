import UITestingCore

/// Identifiers for the inbox example, where each row is identified by its message.
///
/// The rows are a family, because the UI tests count them. The delete buttons are
/// only ever found one at a time, so a function is enough for them.
enum InboxID: ElementIDs {
    static var lastAction: StaticText { element() }
    static var list: CollectionView { element() }
    static var row: StaticText.Family<Int> { family() }
    static func deleteButton(_ id: Int) -> Button { element(id) }
}
