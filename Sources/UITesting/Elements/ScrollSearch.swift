import Foundation

/// A direction to scroll in, named for where the content being looked for is.
///
/// Scrolling ``down`` shows what is further down the screen, which is what a person
/// does by dragging a finger up it.
public enum ScrollDirection: Hashable, Sendable {
    case up
    case down
    case left
    case right

    /// The direction that undoes this one.
    public var opposite: Self {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }
}

/// The steps of scrolling to an element that do not need a running app.
enum ScrollSearch {
    /// Scrolls until an element is in view.
    ///
    /// The search goes in the given direction until the element is in view, the content
    /// stops moving, or the limit is reached. If the element has not come into view by
    /// then, it goes back the other way, which covers an element that was behind the
    /// starting point. The way back has twice the limit, because it has to pass the
    /// starting point before it reaches anything new.
    ///
    /// - Parameters:
    ///   - direction: The direction to try first.
    ///   - maximumSwipes: The most swipes to make in the first direction.
    ///   - isInView: Whether the element is in view.
    ///   - scroll: Scrolls one step in a direction, and returns whether the content moved.
    /// - Returns: Whether the element came into view.
    static func find(
        direction: ScrollDirection,
        maximumSwipes: Int,
        isInView: () -> Bool,
        scroll: (ScrollDirection) -> Bool
    ) -> Bool {
        if isInView() { return true }

        for (direction, limit) in [(direction, maximumSwipes), (direction.opposite, maximumSwipes * 2)] {
            for _ in 0..<limit {
                let moved = scroll(direction)
                if isInView() { return true }
                if !moved { break }
            }
        }
        return false
    }

    /// The speed of a swipe that scrolls on visionOS, in points a second.
    ///
    /// At this speed and below, a swipe moves a list by about a third of its height,
    /// and the content does not carry on once the swipe ends.
    static let visionSwipeVelocity = 300.0

    /// Returns what a description of a hierarchy of elements says about where they
    /// are, without what changes from one reading to the next.
    ///
    /// A description has the address of each element in memory, which is a new one
    /// each time the hierarchy is read. Without the addresses, two descriptions are the
    /// same when the content has not moved.
    ///
    /// - Parameter description: The `debugDescription` of an element.
    static func signature(ofHierarchy description: String) -> String {
        description.replacingOccurrences(of: "0x[0-9a-fA-F]+", with: "", options: .regularExpression)
    }
}
