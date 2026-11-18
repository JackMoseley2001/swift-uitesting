/// The side of a row that its swipe actions are on.
public enum SwipeActionEdge: Hashable, Sendable {
    /// The side the row starts on, which is the left in a left-to-right language.
    /// These actions are shown by swiping the row towards its end.
    case leading

    /// The side the row ends on, which is the right in a left-to-right language.
    /// These actions are shown by swiping the row towards its start.
    case trailing
}

/// The parts of using a row's swipe actions that do not need a running app.
enum SwipeActions {
    /// Returns the labels of a row's actions, from the labels and identifiers of the
    /// buttons beside the row.
    ///
    /// A row that is itself a button is among them, and is not an action. XCTest
    /// can report a button twice, and each action is listed once.
    static func labels(
        ofButtons buttons: [(label: String, identifier: String)],
        rowIdentifier: String
    ) -> [String] {
        var labels: [String] = []
        for button in buttons where button.identifier != rowIdentifier && !labels.contains(button.label) {
            labels.append(button.label)
        }
        return labels
    }

    /// Returns the labels of the actions of a row that was found by its label, from
    /// the labels and identifiers of the buttons beside the row.
    ///
    /// A row that is itself a button is the one with the row's label, and is not an action.
    static func labels(
        ofButtons buttons: [(label: String, identifier: String)],
        rowLabel: String
    ) -> [String] {
        var labels: [String] = []
        for button in buttons where button.label != rowLabel && !labels.contains(button.label) {
            labels.append(button.label)
        }
        return labels
    }

    /// Describes a swipe that did not show the action a test asked for.
    ///
    /// - Parameters:
    ///   - action: How the action was asked for, such as `"Delete"` or an identifier.
    ///   - row: What to call the row, which is its identifier if it was found by one.
    ///   - edge: The side that was swiped to.
    ///   - shown: The labels of the actions that the swipe did show.
    static func missing(action: String, row: String, edge: SwipeActionEdge, shown: [String]) -> String {
        let side = edge == .leading ? "leading" : "trailing"
        let summary = "Could not use the swipe action \(action) on \(row)"
        guard !shown.isEmpty else {
            return "\(summary): swiping showed no actions on its \(side) side"
        }
        let listed = shown.map { "\"\($0)\"" }.joined(separator: ", ")
        return "\(summary): its \(side) side has no such action. Its actions are: \(listed)"
    }
}
