import UITestingCore

/// Identifiers for the list of examples that the app opens on.
enum ExampleID: ElementIDs {
    static func row(_ example: Example) -> Button { element(example.rawValue) }
}
