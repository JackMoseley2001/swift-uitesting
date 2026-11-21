import Foundation
import Testing

@testable import UITesting

@Suite
struct ControlStateTests {
    @Test
    func switchIsOnWhenItsValueIsOne() {
        #Testing::expect(ControlState.isOn(value: "1"))
        #Testing::expect(ControlState.isOn(value: 1))
        #Testing::expect(!ControlState.isOn(value: "0"))
        #Testing::expect(!ControlState.isOn(value: nil))
        #Testing::expect(!ControlState.isOn(value: ""))
    }

    @Test
    func sliderPositionIsItsPercentage() {
        #Testing::expect(ControlState.sliderPosition(value: "50%") == 0.5)
        #Testing::expect(ControlState.sliderPosition(value: "0%") == 0)
        #Testing::expect(ControlState.sliderPosition(value: "100 %") == 1)
        #Testing::expect(ControlState.sliderPosition(value: nil) == nil)
        #Testing::expect(ControlState.sliderPosition(value: "half") == nil)
    }

    @Test
    func stepperValueIsTheSameTextForAStringAndANumber() {
        #Testing::expect(ControlState.stepperValue(value: "3") == "3")
        #Testing::expect(ControlState.stepperValue(value: 3) == "3")
        #Testing::expect(ControlState.stepperValue(value: NSNumber(value: 3)) == "3")
    }

    @Test
    func stepperThatReportsNothingHasNoValue() {
        #Testing::expect(ControlState.stepperValue(value: nil) == nil)
        #Testing::expect(ControlState.stepperValue(value: "") == nil)
    }

    @Test
    func stepTakesEachStepWhenTheValueChanges() {
        var value = 2

        let stuckAt = ControlState.step(
            times: 3,
            value: { "\(value)" },
            tap: { value += 1 },
            waitForChange: { "\(value)" != $0 }
        )

        #Testing::expect(stuckAt == nil)
        #Testing::expect(value == 5)
    }

    @Test
    func stepStopsWhenTheValueStaysTheSame() {
        var value = 4
        var taps = 0

        let stuckAt = ControlState.step(
            times: 3,
            value: { "\(value)" },
            tap: {
                taps += 1
                value = min(value + 1, 5)
            },
            waitForChange: { "\(value)" != $0 }
        )

        #Testing::expect(stuckAt == "5")
        #Testing::expect(taps == 2)
    }

    @Test
    func stepThatChangesNothingIsAllowedWhenChangeIsNotRequired() {
        var value = 4
        var taps = 0

        let stuckAt = ControlState.step(
            times: 3,
            requiringChange: false,
            value: { "\(value)" },
            tap: {
                taps += 1
                value = min(value + 1, 5)
            },
            waitForChange: { _ in
                Issue.record("The value was waited for")
                return false
            }
        )

        #Testing::expect(stuckAt == nil)
        #Testing::expect(taps == 3)
        #Testing::expect(value == 5)
    }

    @Test
    func stepIsTakenOnTrustWhenTheStepperReportsNoValue() {
        var taps = 0

        let stuckAt = ControlState.step(times: 2, value: { "" }, tap: { taps += 1 }, waitForChange: { _ in false })

        #Testing::expect(stuckAt == nil)
        #Testing::expect(taps == 2)
    }

    @Test
    func stepOfNoTimesDoesNothing() {
        var taps = 0

        for times in [0, -1] {
            let stuckAt = ControlState.step(
                times: times,
                value: { "1" },
                tap: { taps += 1 },
                waitForChange: { _ in true }
            )
            #Testing::expect(stuckAt == nil)
        }

        #Testing::expect(taps == 0)
    }

    @Test
    func changeDoesNothingWhenAlreadyDone() {
        var attempts = 0

        let changed = ControlState.change(isDone: { true }, attempts: [{ attempts += 1 }], wait: { false })

        #Testing::expect(changed)
        #Testing::expect(attempts == 0)
    }

    @Test
    func changeStopsAtTheFirstAttemptThatWorks() {
        var state = false
        var attempts: [String] = []

        let changed = ControlState.change(
            isDone: { state },
            attempts: [
                { attempts.append("centre") },
                {
                    attempts.append("switch")
                    state = true
                },
                { attempts.append("never") },
            ],
            wait: { state }
        )

        #Testing::expect(changed)
        #Testing::expect(attempts == ["centre", "switch"])
    }

    @Test
    func changeFailsWhenNoAttemptWorks() {
        #Testing::expect(!ControlState.change(isDone: { false }, attempts: [{}, {}], wait: { false }))
    }

    /// A slider whose thumb lands a little past where it is dragged to.
    private final class Slider {
        var position: Double? = 0.5
        var drags = 0
        var nudges = 0
        var overshoot: Double
        var canBeDragged = true

        init(overshoot: Double = 0) {
            self.overshoot = overshoot
        }

        func adjust(to target: Double, tolerance: Double = 0.02) -> Double?? {
            ControlState.adjustSlider(
                to: target,
                tolerance: tolerance,
                position: { self.position },
                drag: { from, to in
                    self.drags += 1
                    guard self.canBeDragged, let position = self.position else { return }
                    self.position = min(max(position + (to - from) + self.overshoot, 0), 1)
                    self.overshoot /= 4
                },
                nudge: { target in
                    self.nudges += 1
                    self.position = target
                }
            )
        }
    }

    @Test
    func sliderAlreadyThereIsNotMoved() {
        let slider = Slider()

        #Testing::expect(slider.adjust(to: 0.51) == nil)
        #Testing::expect(slider.drags == 0)
    }

    @Test
    func sliderThatLandsWhereDraggedMovesOnce() {
        let slider = Slider()

        #Testing::expect(slider.adjust(to: 0.8) == nil)
        #Testing::expect(slider.drags == 1)
    }

    @Test
    func sliderThatOvershootsIsDraggedAgain() throws {
        let slider = Slider(overshoot: 0.06)

        #Testing::expect(slider.adjust(to: 0.8) == nil)
        #Testing::expect(slider.drags == 2)
        #Testing::expect(abs(try #Testing::require(slider.position) - 0.8) <= 0.02)
    }

    @Test
    func sliderWhoseThumbIsMissedIsNudged() {
        let slider = Slider()
        slider.canBeDragged = false

        #Testing::expect(slider.adjust(to: 0.8) == nil)
        #Testing::expect(slider.nudges == 1)
    }

    @Test
    func sliderThatNeverSettlesReportsWhereItEnded() {
        var position = 0.5

        let failure = ControlState.adjustSlider(
            to: 0.8,
            tolerance: 0.02,
            position: { position },
            drag: { _, _ in position = position == 0.7 ? 0.9 : 0.7 },
            nudge: { _ in }
        )

        #Testing::expect(failure == .some(0.7))
    }

    @Test
    func sliderWithoutAPositionFails() {
        let failure = ControlState.adjustSlider(
            to: 0.5, tolerance: 0.02, position: { nil }, drag: { _, _ in }, nudge: { _ in }
        )

        #Testing::expect(failure == .some(nil))
    }
}
