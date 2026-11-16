import Testing

@testable import UITesting

@Suite
struct KeyboardDismissalTests {
    private let polling = ExpectationPolling(interval: .seconds(1), now: { ContinuousClock.now }, sleep: { _ in })

    /// A keyboard that goes away when the attempt with the given name is made.
    private final class Keyboard {
        var isShowing = true
        var tried: [String] = []
        let dismissedBy: String?

        init(dismissedBy: String?) {
            self.dismissedBy = dismissedBy
        }

        func attempt(_ name: String, isAvailable: Bool = true) -> () -> Bool {
            {
                guard isAvailable else { return false }
                self.tried.append(name)
                if name == self.dismissedBy { self.isShowing = false }
                return true
            }
        }
    }

    private func failure(_ keyboard: Keyboard, attempts: [() -> Bool]) -> String? {
        KeyboardDismissal.failure(
            isShowing: { keyboard.isShowing },
            attempts: attempts,
            timeout: .zero,
            polling: polling
        )
    }

    @Test
    func nothingIsTriedWhenTheKeyboardIsNotShowing() {
        let keyboard = Keyboard(dismissedBy: nil)
        keyboard.isShowing = false

        #Testing::expect(failure(keyboard, attempts: [keyboard.attempt("key")]) == nil)
        #Testing::expect(keyboard.tried.isEmpty)
    }

    @Test
    func stopsAtTheFirstWayThatWorks() {
        let keyboard = Keyboard(dismissedBy: "done")

        let failure = failure(keyboard, attempts: [
            keyboard.attempt("key"), keyboard.attempt("done"), keyboard.attempt("drag"),
        ])

        #Testing::expect(failure == nil)
        #Testing::expect(keyboard.tried == ["key", "done"])
    }

    @Test
    func skipsWaysTheAppDoesNotOffer() {
        let keyboard = Keyboard(dismissedBy: "drag")

        let failure = failure(keyboard, attempts: [
            keyboard.attempt("key", isAvailable: false), keyboard.attempt("drag"),
        ])

        #Testing::expect(failure == nil)
        #Testing::expect(keyboard.tried == ["drag"])
    }

    @Test
    func failsWhenNoWayWorks() throws {
        let keyboard = Keyboard(dismissedBy: nil)

        let failure = try #Testing::require(
            failure(keyboard, attempts: [keyboard.attempt("key"), keyboard.attempt("drag")])
        )

        #Testing::expect(failure.hasPrefix("Could not dismiss the keyboard"))
        #Testing::expect(keyboard.tried == ["key", "drag"])
    }
}
