import Testing
import XCTest

@testable import UITesting

@Suite
struct TextEntryTests {
    @Test
    func textIsTheValueOfTheField() {
        #Testing::expect(TextEntry.text(value: "Ada", placeholder: "Name") == "Ada")
        #Testing::expect(TextEntry.text(value: "Ada", placeholder: nil) == "Ada")
    }

    @Test
    func emptyFieldThatReportsItsPlaceholderHasNoText() {
        #Testing::expect(TextEntry.text(value: "Name", placeholder: "Name") == "")
    }

    @Test
    func fieldWithoutAStringValueHasNoText() {
        #Testing::expect(TextEntry.text(value: nil, placeholder: "Name") == "")
        #Testing::expect(TextEntry.text(value: 3, placeholder: nil) == "")
    }

    @Test
    func emptyValueWithAnEmptyPlaceholderHasNoText() {
        #Testing::expect(TextEntry.text(value: "", placeholder: "") == "")
    }

    /// A field that deletes before its cursor, and whose cursor moves on a line at a time.
    private final class Field {
        var lines: [String]
        var cursorLine: Int
        var canMove = true

        init(_ text: String, cursorLine: Int) {
            lines = text.components(separatedBy: "\n")
            self.cursorLine = cursorLine
        }

        var text: String { lines.joined(separator: "\n") }

        func moveDown() {
            if canMove { cursorLine = min(cursorLine + 1, lines.count) }
        }

        func delete(_ count: Int) {
            let kept = lines.dropFirst(min(cursorLine + 1, lines.count))
            let before = lines.prefix(min(cursorLine + 1, lines.count)).joined(separator: "\n")
            let rest = String(before.dropLast(count))
            lines = (rest.isEmpty ? [] : [rest]) + kept
            cursorLine = rest.isEmpty ? -1 : 0
        }

        func clear() -> Bool {
            TextEntry.clear(text: { self.text }, moveToEnd: { self.moveDown() }, type: { self.delete($0.count) })
        }
    }

    @Test
    func clearingEmptiesAFieldWhoseCursorIsAtTheEnd() {
        let field = Field("Ada", cursorLine: 0)

        #Testing::expect(field.clear())
        #Testing::expect(field.text == "")
    }

    @Test
    func clearingKeepsGoingWhileTextIsLeftAfterTheCursor() {
        let field = Field("One\nTwo\nThree\nFour", cursorLine: 0)

        #Testing::expect(field.clear())
        #Testing::expect(field.text == "")
    }

    @Test
    func clearingMovesTheCursorOnlyWhenTextIsLeft() {
        var moves = 0
        var text = "Ada"

        let isEmpty = TextEntry.clear(text: { text }, moveToEnd: { moves += 1 }, type: { _ in text = "" })

        #Testing::expect(isEmpty)
        #Testing::expect(moves == 0)
    }

    @Test
    func clearingGivesUpWhenNothingMoreIsDeleted() {
        let field = Field("One\nTwo\nThree", cursorLine: 0)
        field.canMove = false
        field.cursorLine = -1

        #Testing::expect(!field.clear())
        #Testing::expect(field.text == "One\nTwo\nThree")
    }

    @Test
    func clearingSelectsAllOfTheTextWhenMovingTheCursorDeletedNothing() {
        var text = "One\nTwo"
        var isSelected = false
        var moves = 0

        let isEmpty = TextEntry.clear(
            text: { text },
            moveToEnd: { moves += 1 },
            selectAll: { isSelected = true },
            // The cursor is at the start and does not move, so only a selection is deleted.
            type: { _ in if isSelected { text = "" } }
        )

        #Testing::expect(isEmpty)
        #Testing::expect(moves == 1)
    }

    @Test
    func clearingGivesUpWhenSelectingAllOfTheTextDeletedNothingEither() {
        var selections = 0

        let isEmpty = TextEntry.clear(
            text: { "One" }, moveToEnd: {}, selectAll: { selections += 1 }, type: { _ in }
        )

        #Testing::expect(!isEmpty)
        #Testing::expect(selections == 1)
    }

    @Test
    func clearingAnEmptyFieldTypesNothing() {
        var typed = 0

        #Testing::expect(TextEntry.clear(text: { "" }, moveToEnd: { typed += 1 }, type: { _ in typed += 1 }))
        #Testing::expect(typed == 0)
    }

    @Test
    func deletionHasOneKeyForEachCharacter() {
        #Testing::expect(TextEntry.deletion(of: "Ada") == String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        #Testing::expect(TextEntry.deletion(of: "") == "")
        #Testing::expect(TextEntry.deletion(of: "👩‍💻é") == TextEntry.deletion(of: "ab"))
    }

    /// Polling whose clock moves on by a second each time it is read.
    private var polling: ExpectationPolling {
        let clock = SteppingClock()
        return ExpectationPolling(
            interval: .seconds(1), now: { clock.advance() }, sleep: { _ in }, betweenEvaluations: {}
        )
    }

    @Test
    func fieldIsNotTappedAgainWhenTheScreenToTypeOnShows() {
        var taps = 0

        let showed = TextEntry.waitForInput(
            within: .seconds(20), polling: polling, isShowing: { true }, tapAgain: { taps += 1 }
        )

        #Testing::expect(showed)
        #Testing::expect(taps == 0)
    }

    @Test
    func fieldIsTappedAgainWhenTheScreenToTypeOnDoesNotShow() {
        var taps = 0

        let showed = TextEntry.waitForInput(
            within: .seconds(20), polling: polling, isShowing: { taps == 1 }, tapAgain: { taps += 1 }
        )

        #Testing::expect(showed)
        #Testing::expect(taps == 1)
    }

    @Test
    func waitEndsWhenTheScreenToTypeOnNeverShows() {
        var taps = 0

        let showed = TextEntry.waitForInput(
            within: .seconds(25), polling: polling, isShowing: { false }, tapAgain: { taps += 1 }
        )

        #Testing::expect(!showed)
        #Testing::expect(taps == 2)
    }

    @Test
    func fieldIsNotTappedAgainWhileTheScreenToTypeOnMayStillBeOpening() {
        var taps = 0

        let showed = TextEntry.waitForInput(
            within: TextEntry.inputPatience, polling: polling, isShowing: { false }, tapAgain: { taps += 1 }
        )

        #Testing::expect(!showed)
        #Testing::expect(taps == 0)
    }
}

/// A clock that moves on by a second each time it is read.
private final class SteppingClock {
    private var instant = ContinuousClock.now

    func advance() -> ContinuousClock.Instant {
        instant += .seconds(1)
        return instant
    }
}
