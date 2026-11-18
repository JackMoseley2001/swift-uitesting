import UITestingCore

/// Identifiers for the list of numbers, which is long enough to need scrolling.
enum NumberID: ElementIDs {
    static var selection: StaticText { element() }
    static var row: Button.Family<Int> { family() }
}
