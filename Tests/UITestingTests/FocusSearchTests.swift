import CoreGraphics
import Testing

@testable import UITesting

@Suite
struct FocusSearchTests {
    private func row(_ index: Int, column: Int = 0) -> CGRect {
        CGRect(x: column * 300, y: index * 80, width: 250, height: 66)
    }

    @Test
    func focusIsOnATargetThatItHolds() {
        // The focus is on a cell, and the target is the button inside it.
        let cell = CGRect(x: 80, y: 145, width: 1760, height: 66)
        let button = CGRect(x: 100, y: 150, width: 300, height: 56)

        #Testing::expect(FocusSearch.isOn(focus: cell, target: button))
        #Testing::expect(FocusSearch.isOn(focus: button, target: cell))
        #Testing::expect(!FocusSearch.isOn(focus: cell, target: button.offsetBy(dx: 0, dy: 80)))
        #Testing::expect(!FocusSearch.isOn(focus: cell, target: .zero))
    }

    @Test
    func targetThatIsNotLevelIsLookedForUpOrDownFirst() {
        #Testing::expect(FocusSearch.directions(from: row(0), to: row(3)) == [.down])
        #Testing::expect(FocusSearch.directions(from: row(3), to: row(0)) == [.up])
        #Testing::expect(FocusSearch.directions(from: row(0), to: row(2, column: 1)) == [.down, .right])
    }

    @Test
    func targetThatIsLevelIsLookedForSidewaysFirst() {
        #Testing::expect(FocusSearch.directions(from: row(1), to: row(1, column: 2)) == [.right])
        #Testing::expect(FocusSearch.directions(from: row(1, column: 2), to: row(1)) == [.left])
    }

    /// A grid of elements that the focus moves through, as the remote moves it.
    private final class Grid {
        var focus: (row: Int, column: Int)
        let rows: Int
        let columns: Int
        var presses: [ScrollDirection] = []

        init(focus: (Int, Int), rows: Int, columns: Int) {
            self.focus = focus
            self.rows = rows
            self.columns = columns
        }

        func press(_ direction: ScrollDirection) {
            presses.append(direction)
            switch direction {
            case .up: focus.row = max(focus.row - 1, 0)
            case .down: focus.row = min(focus.row + 1, rows - 1)
            case .left: focus.column = max(focus.column - 1, 0)
            case .right: focus.column = min(focus.column + 1, columns - 1)
            }
        }
    }

    @Test
    func focusIsMovedToTheTargetAPressAtATime() {
        let grid = Grid(focus: (0, 0), rows: 5, columns: 3)

        let reached = FocusSearch.move(
            focus: { FocusSearch.Focus(frame: self.row(grid.focus.row, column: grid.focus.column)) },
            target: { self.row(3, column: 2) },
            press: grid.press
        )

        #Testing::expect(reached)
        #Testing::expect(grid.presses == [.down, .down, .down, .right, .right])
    }

    @Test
    func focusAlreadyOnTheTargetIsNotMoved() {
        let grid = Grid(focus: (2, 1), rows: 5, columns: 3)

        let reached = FocusSearch.move(
            focus: { FocusSearch.Focus(frame: self.row(grid.focus.row, column: grid.focus.column)) },
            target: { self.row(2, column: 1) },
            press: grid.press
        )

        #Testing::expect(reached)
        #Testing::expect(grid.presses.isEmpty)
    }

    @Test
    func otherDirectionIsTriedWhenTheFirstMovesNothing() {
        // The focus is in the last row, and the target is lower down and to the right.
        let grid = Grid(focus: (1, 0), rows: 2, columns: 3)

        let reached = FocusSearch.move(
            focus: { FocusSearch.Focus(frame: self.row(grid.focus.row, column: grid.focus.column)) },
            target: { self.row(1, column: 2).offsetBy(dx: 0, dy: 200) },
            press: grid.press
        )

        // It goes right when down moves nothing, and stops when neither does.
        #Testing::expect(!reached)
        #Testing::expect(grid.presses.contains(.right))
        #Testing::expect(grid.focus.column == 2)
    }

    @Test
    func focusThatStaysInPlaceWhileTheListScrollsHasMoved() {
        // The focus stays in the middle of the screen, and the rows move under it.
        var index = 0

        let reached = FocusSearch.move(
            focus: { FocusSearch.Focus(frame: self.row(2), name: "row \(index)") },
            target: { self.row(2 + 5 - index) },
            press: { _ in index += 1 }
        )

        #Testing::expect(reached)
        #Testing::expect(index == 5)
    }

    @Test
    func alertMessageIsFoundAfterATitleWithAFullStop() {
        // tvOS reports the title of an alert with a full stop after it.
        let texts = ["Delete the draft?.", "This cannot be undone."]

        #Testing::expect(AppAlertText.message(title: "Delete the draft?", texts: texts) == "This cannot be undone.")
    }

    @Test
    func targetWithoutAFrameIsNotSearchedFor() {
        // tvOS reports no frame for an element that is off the screen.
        var presses = 0

        let reached = FocusSearch.move(
            focus: { FocusSearch.Focus(frame: self.row(1)) },
            target: { .zero },
            press: { _ in presses += 1 }
        )

        #Testing::expect(!reached)
        #Testing::expect(presses == 0)
    }

    @Test
    func searchFailsWhenNothingHasTheFocus() {
        #Testing::expect(!FocusSearch.move(focus: { nil }, target: { self.row(1) }, press: { _ in }))
    }

    @Test
    func searchStopsAfterTheMostPresses() {
        var y = 0.0

        let reached = FocusSearch.move(
            maximumPresses: 5,
            focus: { FocusSearch.Focus(frame: CGRect(x: 0, y: y, width: 100, height: 50)) },
            target: { CGRect(x: 0, y: 10_000, width: 100, height: 50) },
            press: { _ in y += 60 }
        )

        #Testing::expect(!reached)
        #Testing::expect(y == 300)
    }
}
