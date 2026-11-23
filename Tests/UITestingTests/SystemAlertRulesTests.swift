import Testing

@testable import UITesting

@Suite
struct SystemAlertRulesTests {
    private let microphone = "kTCCServiceMicrophone-alert"
    private let camera = "kTCCServiceCamera-alert"

    /// The buttons of a permission alert that says which allows and which refuses.
    private func buttons(for service: String) -> [SystemAlertButtonInfo] {
        [
            SystemAlertButtonInfo(label: "Don’t Allow", identifier: "\(service)-deny-button"),
            SystemAlertButtonInfo(label: "Allow", identifier: "\(service)-allow-button")
        ]
    }

    /// The buttons of the alert for location, which have no identifiers.
    private let locationButtons = [
        SystemAlertButtonInfo(label: "Allow Once"),
        SystemAlertButtonInfo(label: "Allow While Using App"),
        SystemAlertButtonInfo(label: "Don’t Allow")
    ]

    private func position(_ rules: [SystemAlertRule], inAlert identifier: String) -> Int? {
        let service = String(identifier.dropLast("-alert".count))
        return SystemAlertRules(rules: rules).positionOfButton(
            inAlertWithIdentifier: identifier,
            buttons: buttons(for: service),
            marked: true
        )
    }

    /// The buttons of a permission alert of a system that marks nothing, as before iOS 27.
    fileprivate static let unmarkedButtons = [
        SystemAlertButtonInfo(label: "Don’t Allow"),
        SystemAlertButtonInfo(label: "Allow")
    ]

    /// The position that rules give in the alert for location, on a system that marks its alerts.
    private func locationPosition(_ rules: SystemAlertRules) -> Int? {
        rules.positionOfButton(inAlertWithIdentifier: "", buttons: locationButtons, marked: true)
    }

    @Test
    func unmarkedAlertIsAnsweredByItsPositions() {
        let allow = SystemAlertRules(rules: [SystemAlertRule(answer: .allow)])
        let deny = SystemAlertRules(rules: [SystemAlertRule(answer: .deny)])

        #Testing::expect(allow.unmarkedPosition == 1)
        #Testing::expect(deny.unmarkedPosition == 0)
    }

    @Test
    func ruleForAServiceAnswersEveryAlertOfASystemThatMarksNothing() {
        let rules = SystemAlertRules(rules: [SystemAlertRule(answer: .deny, services: ["kTCCServiceCamera"])])

        #Testing::expect(rules.unmarkedPosition == 0)
        // Where alerts are marked, an alert without an identifier is not the camera's.
        let marked = rules.positionOfButton(inAlertWithIdentifier: "", buttons: Self.unmarkedButtons, marked: true)
        #Testing::expect(marked == nil)
    }

    @Test
    func ruleWithoutServicesAnswersEveryAlertThatHasItsButton() {
        let rules = [SystemAlertRule(answer: .allow)]

        #Testing::expect(position(rules, inAlert: microphone) == 1)
        #Testing::expect(position(rules, inAlert: camera) == 1)
    }

    @Test
    func ruleWithServicesAnswersOnlyTheirAlerts() {
        let rules = [SystemAlertRule(answer: .deny, services: ["kTCCServiceMicrophone"])]

        #Testing::expect(position(rules, inAlert: microphone) == 0)
        #Testing::expect(position(rules, inAlert: camera) == nil)
    }

    @Test
    func serviceHasToMatchTheWholeName() {
        let rules = [SystemAlertRule(answer: .allow, services: ["kTCCServicePhotos"])]

        #Testing::expect(position(rules, inAlert: "kTCCServicePhotos-staged-alert") == 1)
        #Testing::expect(position(rules, inAlert: "kTCCServicePhotosAdd-alert") == nil)
    }

    @Test
    func laterRuleOverridesAnEarlierOne() {
        let rules = [
            SystemAlertRule(answer: .allow),
            SystemAlertRule(answer: .deny, services: ["kTCCServiceMicrophone"])
        ]

        #Testing::expect(position(rules, inAlert: microphone) == 0)
        #Testing::expect(position(rules, inAlert: camera) == 1)
    }

    @Test
    func laterRuleForEveryAlertOverridesAnEarlierNamedOne() {
        let rules = [
            SystemAlertRule(answer: .deny, services: ["kTCCServiceMicrophone"]),
            SystemAlertRule(answer: .allow)
        ]

        #Testing::expect(position(rules, inAlert: microphone) == 1)
    }

    @Test
    func alertThatDoesNotSayWhichButtonAllowsIsNotAnswered() {
        let rules = SystemAlertRules(rules: [SystemAlertRule(answer: .allow)])

        #Testing::expect(locationPosition(rules) == nil)
    }

    @Test
    func ruleForALabelAnswersAnAlertWithThatButton() {
        let rules = SystemAlertRules(rules: [SystemAlertRule(answer: .button("Allow While Using App"))])

        #Testing::expect(locationPosition(rules) == 1)
    }

    @Test
    func ruleForALabelLeavesOtherAlertsToEarlierRules() {
        let rules = SystemAlertRules(rules: [
            SystemAlertRule(answer: .deny),
            SystemAlertRule(answer: .button("Allow While Using App"))
        ])

        #Testing::expect(locationPosition(rules) == 1)
        #Testing::expect(position(rules.rules, inAlert: microphone) == 0)
    }

    @Test
    func traitsGiveTheRulesInOrder() {
        let rules = UITestRunner.systemAlertRules(from: [
            .systemAlerts(.allow),
            .launchArgument("--flag"),
            .systemAlerts(.deny, for: .microphone, .camera)
        ])

        #Testing::expect(
            rules
                == SystemAlertRules(rules: [
                    SystemAlertRule(answer: .allow),
                    SystemAlertRule(answer: .deny, services: ["kTCCServiceMicrophone", "kTCCServiceCamera"])
                ])
        )
    }

    @Test
    func traitForAResourceWhoseAlertHasNoNameIsForEveryAlert() {
        let rules = UITestRunner.systemAlertRules(from: [
            .systemAlerts(.button("OK"), for: .calendar),
            .systemAlerts(.allow, for: .camera, .calendar)
        ])

        #Testing::expect(
            rules
                == SystemAlertRules(rules: [
                    SystemAlertRule(answer: .button("OK")),
                    SystemAlertRule(answer: .allow)
                ])
        )
    }

    @Test
    func traitsThatSayNothingAboutAlertsGiveNoRules() {
        #Testing::expect(UITestRunner.systemAlertRules(from: [.launchArgument("--flag")]) == nil)
        #Testing::expect(UITestRunner.systemAlertRules(from: []) == nil)
    }

    @Test
    func waitRunsTheStepBetweenEvaluationsOnlyAfterAFalseOne() {
        var evaluations = 0
        var steps = 0
        let polling = ExpectationPolling(
            sleep: { _ in },
            betweenEvaluations: { steps += 1 }
        )

        let outcome = polling.wait(timeout: .seconds(10)) {
            evaluations += 1
            return evaluations == 3
        }

        #Testing::expect(outcome == .met)
        #Testing::expect(steps == 2)
    }
}

extension SystemAlertRules {
    /// The position these rules give in a permission alert of a system that marks nothing.
    fileprivate var unmarkedPosition: Int? {
        positionOfButton(inAlertWithIdentifier: "", buttons: SystemAlertRulesTests.unmarkedButtons, marked: false)
    }
}
