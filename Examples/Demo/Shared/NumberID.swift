import UITestingCore

/// Identifiers for the list of numbers, which is long enough to need scrolling.
enum NumberID: ElementIDs {
    static var selection: StaticText { element() }
    static func row(_ number: Int) -> Button { element(number) }
}
