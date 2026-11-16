import UITestingCore

/// Identifiers for the fruit list, where each row is identified by the fruit it shows.
enum FruitID: ElementIDs {
    static var selection: StaticText { element() }
    static var clearButton: Button { element() }
    static func row(_ id: Int) -> Button { element(id) }
}
