import UITestingCore

/// Identifiers for the fruit list, where each row is identified by the fruit it shows.
///
/// The rows are a family, so that a UI test can find one row with `FruitID.row(id)`
/// and all of them with `app[all: FruitID.row]`.
enum FruitID: ElementIDs {
    static var selection: StaticText { element() }
    static var clearButton: Button { element() }
    static var row: Button.Family<Int> { family() }
}
