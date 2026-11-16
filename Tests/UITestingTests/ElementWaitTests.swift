import Testing

@testable import UITesting

@Suite
struct ElementWaitTests {
    /// Polling that never sleeps, with a clock that moves on one second at each check of the time.
    private func polling() -> ExpectationPolling {
        let clock = TestClock()
        return ExpectationPolling(interval: .seconds(1), now: { clock.advance() }, sleep: { _ in })
    }

    private func failure(
        intent: String = "tap",
        requirement: ElementRequirement,
        exists: @escaping () -> Bool,
        isEnabled: @escaping () -> Bool = { true },
        otherType: String? = nil
    ) -> String? {
        ElementWait.failure(
            intent: intent,
            identifier: "LoginID.signInButton",
            kind: "button",
            requirement: requirement,
            timeout: .seconds(5),
            polling: polling(),
            probe: ElementProbe(
                exists: exists,
                isEnabled: isEnabled,
                typeOfElementWithSameIdentifier: { otherType }
            )
        )
    }

    @Test
    func elementThatIsReadyPasses() {
        #Testing::expect(failure(requirement: .enabled, exists: { true }) == nil)
        #Testing::expect(failure(requirement: .exists, exists: { true }) == nil)
        #Testing::expect(failure(requirement: .absent, exists: { false }) == nil)
    }

    @Test
    func elementThatAppearsWhileWaitingPasses() {
        var checks = 0

        let failure = failure(requirement: .exists, exists: {
            checks += 1
            return checks >= 3
        })

        #Testing::expect(failure == nil)
        #Testing::expect(checks == 3)
    }

    @Test
    func elementThatBecomesEnabledWhileWaitingPasses() {
        var checks = 0

        let failure = failure(requirement: .enabled, exists: { true }, isEnabled: {
            checks += 1
            return checks >= 2
        })

        #Testing::expect(failure == nil)
    }

    @Test
    func enabledIsNotReadWhileTheElementIsMissing() {
        var enabledReads = 0

        _ = failure(requirement: .enabled, exists: { false }, isEnabled: {
            enabledReads += 1
            return true
        })

        #Testing::expect(enabledReads == 0)
    }

    @Test
    func missingElementSaysNothingAppeared() {
        #Testing::expect(
            failure(requirement: .enabled, exists: { false })
                == "Could not tap LoginID.signInButton: no button with this identifier appeared within 5 seconds"
        )
    }

    @Test
    func disabledElementSaysItStayedDisabled() {
        #Testing::expect(
            failure(requirement: .enabled, exists: { true }, isEnabled: { false })
                == "Could not tap LoginID.signInButton: the button was still disabled after 5 seconds"
        )
    }

    @Test
    func elementOfAnotherKindIsPointedOut() {
        #Testing::expect(
            failure(requirement: .exists, exists: { false }, otherType: "staticText") == """
                Could not tap LoginID.signInButton: no button with this identifier appeared within 5 seconds
                An element of type staticText has this identifier. Is the identifier declared as the wrong kind?
                """
        )
    }

    @Test
    func elementThatStaysSaysItWasStillThere() {
        #Testing::expect(
            failure(intent: "see the end of", requirement: .absent, exists: { true })
                == "Could not see the end of LoginID.signInButton: the button was still there after 5 seconds"
        )
    }

    @Test
    func actionTimeoutIsFiveSecondsWithoutATrait() {
        #Testing::expect(ActionTimeout.timeout(from: []) == .seconds(5))
        #Testing::expect(ActionTimeout.timeout(from: [.launchArgument("--flag")]) == .seconds(5))
        #Testing::expect(ActionTimeout.current == .seconds(5))
    }

    @Test
    func lastActionTimeoutTraitWins() {
        let traits: [any UITestTrait] = [
            .actionTimeout(.seconds(2)), .launchArgument("--flag"), .actionTimeout(.seconds(20)),
        ]

        #Testing::expect(ActionTimeout.timeout(from: traits) == .seconds(20))
    }
}

private final class TestClock {
    private var instant = ContinuousClock.now

    func advance() -> ContinuousClock.Instant {
        defer { instant += .seconds(1) }
        return instant
    }
}
