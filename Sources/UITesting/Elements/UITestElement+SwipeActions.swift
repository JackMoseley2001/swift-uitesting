import XCTest

// tvOS has no touch screen, so XCTest has no taps, drags or swipes there.
#if !os(tvOS)
extension UITestElement {
    /// Swipes a row of a list and taps the action with a label, once the row exists.
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].swipeAction("Archive")
    /// try app[InboxID.row(1234)].swipeAction("Unread", edge: .leading)
    /// ```
    ///
    /// The swipe is slow, so that it shows the actions and does not carry one out as
    /// a full swipe would. The action is looked for beside the row, so the action of
    /// another row, or a button with the same label elsewhere, is not taken for it.
    ///
    /// - Parameters:
    ///   - label: The label of the action.
    ///   - edge: The side of the row the action is on. The default is the trailing side.
    ///   - timeout: How long to wait for the row, and for the action to show. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the row is not there in time, or the
    ///   swipe shows no action with this label. The failure is recorded at the line of
    ///   the call, and the test ends.
    public func swipeAction(
        _ label: String,
        edge: SwipeActionEdge = .trailing,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try swipeAction(
            named: "\"\(label)\"",
            edge: edge,
            within: timeout,
            filePath: filePath,
            line: line,
            find: { $0.buttons.matching(NSPredicate(format: "label == %@", label)) }
        )
    }

    /// Swipes a row of a list and taps the action with an identifier, once the row exists.
    ///
    /// This does not depend on the language of the app.
    ///
    /// ```swift
    /// try app[InboxID.row(1234)].swipeAction(InboxID.archiveButton(1234))
    /// ```
    ///
    /// - Parameters:
    ///   - id: The identifier that the app gave the action.
    ///   - edge: The side of the row the action is on. The default is the trailing side.
    ///   - timeout: How long to wait for the row, and for the action to show. The
    ///     default is the test's ``UITestTrait/actionTimeout(_:)``.
    /// - Throws: ``RequirementFailedError`` if the row is not there in time, or the
    ///   swipe shows no action with this identifier. The failure is recorded at the
    ///   line of the call, and the test ends.
    public func swipeAction<Action: ElementKind>(
        _ id: ElementID<Action>,
        edge: SwipeActionEdge = .trailing,
        within timeout: Duration? = nil,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let identifier = id.accessibilityIdentifier
        try swipeAction(
            named: identifier,
            edge: edge,
            within: timeout,
            filePath: filePath,
            line: line,
            find: { $0.descendants(matching: .any).matching(identifier: identifier) }
        )
    }

    private func swipeAction(
        named name: String,
        edge: SwipeActionEdge,
        within timeout: Duration?,
        filePath: StaticString,
        line: UInt,
        find: (XCUIElement) -> XCUIElementQuery
    ) throws {
        let intent = "use the swipe action \(name) on"
        try wait(toBe: .exists, inOrderTo: intent, within: timeout, filePath: filePath, line: line)

        // The row is swiped by its cell, which is as wide as the list. An identifier on
        // a row's content is on something inside the cell, which can be narrower.
        let container = try scope ?? owningApp(inOrderTo: intent, filePath: filePath, line: line)
        let cell: XCUIElement
        if Kind.elementType == .cell {
            cell = element
        } else {
            let holding: XCUIElement
            if let labelMatch {
                let hasLabel = NSPredicate(format: "label == %@", labelMatch.label)
                holding = container.cells.containing(hasLabel).firstMatch
            } else {
                let type = XCUIElement.ElementType(Kind.elementType)
                holding = container.cells.containing(type, identifier: accessibilityIdentifier).firstMatch
            }
            cell = holding.exists ? holding : element
        }

        // A slow swipe shows the actions. A fast one can carry the first of them out,
        // as a full swipe by a person does.
        if edge == .trailing {
            cell.swipeLeft(velocity: .slow)
        } else {
            cell.swipeRight(velocity: .slow)
        }

        // XCTest does not report the actions as part of the cell. They are the
        // elements at the height of the row.
        let row = cell.frame
        func isBesideRow(_ candidate: XCUIElement) -> Bool {
            (row.minY...row.maxY).contains(candidate.frame.midY)
        }
        let candidates = find(container)
        var action: XCUIElement?
        let timeout = timeout ?? ActionTimeout.current
        _ = ExpectationPolling().wait(timeout: min(timeout, .seconds(3))) {
            action = candidates.allElementsBoundByIndex.first(where: isBesideRow)
            return action != nil
        }
        guard let action else {
            let buttons = container.buttons.allElementsBoundByIndex
                .filter(isBesideRow)
                .map { (label: $0.label, identifier: $0.identifier) }
            let shown =
                if let labelMatch {
                    SwipeActions.labels(ofButtons: buttons, rowLabel: labelMatch.label)
                } else {
                    SwipeActions.labels(ofButtons: buttons, rowIdentifier: accessibilityIdentifier)
                }
            try fail(
                SwipeActions.missing(action: name, row: reference.name, edge: edge, shown: shown),
                filePath: filePath,
                line: line
            )
        }
        action.tapOrClick()
    }
}
#endif
