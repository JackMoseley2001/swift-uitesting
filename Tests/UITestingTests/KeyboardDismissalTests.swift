import Testing

@testable import UITesting

@Suite
struct KeyboardDismissalTests {
    private let polling = ExpectationPolling(interval: .seconds(1), now: { ContinuousClock.now }, sleep: { _ in })

    private func failure(isShowing: @escaping () -> Bool, dismiss: @escaping () -> Void) -> String? {
        KeyboardDismissal.failure(isShowing: isShowing, dismiss: dismiss, timeout: .zero, polling: polling)
    }

    @Test
    func nothingIsDoneWhenTheKeyboardIsNotShowing() {
        var gestures = 0

        #Testing::expect(failure(isShowing: { false }, dismiss: { gestures += 1 }) == nil)
        #Testing::expect(gestures == 0)
    }

    @Test
    func passesWhenTheGestureDismissesTheKeyboard() {
        var isShowing = true
        var gestures = 0

        let failure = failure(isShowing: { isShowing }, dismiss: {
            gestures += 1
            isShowing = false
        })

        #Testing::expect(failure == nil)
        #Testing::expect(gestures == 1)
    }

    @Test
    func failsWhenTheKeyboardStays() throws {
        let failure = try #Testing::require(failure(isShowing: { true }, dismiss: {}))

        #Testing::expect(failure.hasPrefix("Could not dismiss the keyboard: it was still showing"))
    }
}
